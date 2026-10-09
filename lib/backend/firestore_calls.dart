import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/settings.dart';
import 'calls.dart';

/// Calls on Firestore.
///
/// - calls/{id}: studentId, names and pictures, gender, status, the teacher
///   being rung (teacherId), teachers already tried, and the WebRTC offer and
///   answer. Only its student and (once rung) its teacher can read it.
/// - calls/{id}/ice/{id}: network routes from each side.
/// - presence/{uid}.busy: a teacher in a call isn't rung by anyone else.
mixin FirestoreCalls implements CallApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  String? get _me => auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _calls => db.collection('calls');

  static CallInfo _info(DocumentSnapshot<Map<String, dynamic>> d) {
    final c = d.data() ?? const {};
    return CallInfo(
      id: d.id,
      studentId: (c['studentId'] as String?) ?? '',
      studentName: (c['studentName'] as String?) ?? '',
      studentAvatar: c['studentAvatar'] as String?,
      teacherId: c['teacherId'] as String?,
      teacherName: (c['teacherName'] as String?) ?? '',
      teacherAvatar: c['teacherAvatar'] as String?,
      status: CallStatus.values.where((s) => s.name == c['status']).firstOrNull ?? CallStatus.ended,
      offer: (c['offer'] as Map?)?.cast<String, dynamic>(),
      answer: (c['answer'] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  Future<String> createCall({required String name, String? avatar, required Gender gender}) async {
    final ref = _calls.doc();
    await ref.set({
      'studentId': _me,
      'studentName': name,
      'studentAvatar': avatar,
      'gender': gender.name,
      'status': CallStatus.searching.name,
      'teacherId': null,
      'tried': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<List<Candidate>> freeTeachers(Gender gender, {Set<String> exclude = const {}}) async {
    final s = await db
        .collection('presence')
        .where('available', isEqualTo: true)
        .where('gender', isEqualTo: gender.name)
        .get();
    final free = [
      for (final d in s.docs)
        if (d.data()['busy'] != true && d.id != _me && !exclude.contains(d.id) && isFresh(d.data())) Candidate(d.id),
    ]..shuffle(Random());
    return free;
  }

  @override
  Future<void> ring(String callId, String teacherId) => _calls.doc(callId).update({
    'teacherId': teacherId,
    'status': CallStatus.ringing.name,
    'tried': FieldValue.arrayUnion([teacherId]),
    'ringAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> setCallStatus(String callId, CallStatus status) => _calls.doc(callId).update({
    'status': status.name,
    if (status == CallStatus.ended || status == CallStatus.cancelled || status == CallStatus.unmatched)
      'endedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> acceptCall(String callId, {required String name, String? avatar}) => _calls.doc(callId).update({
    'status': CallStatus.active.name,
    'teacherName': name,
    'teacherAvatar': avatar,
    'acceptedAt': FieldValue.serverTimestamp(),
  });

  @override
  Stream<CallInfo?> watchCall(String callId) => _calls.doc(callId).snapshots().map((d) => d.exists ? _info(d) : null);

  @override
  Stream<List<CallInfo>> incomingCalls() => auth.authStateChanges().asyncExpand(
    (u) => u == null
        ? Stream.value(const <CallInfo>[])
        : _calls
              .where('teacherId', isEqualTo: u.uid)
              .where('status', isEqualTo: CallStatus.ringing.name)
              .snapshots()
              .map((s) => [for (final d in s.docs) _info(d)])
              .handleError((_) {}),
  );

  @override
  Future<void> setOffer(String callId, Map<String, dynamic> description) =>
      _calls.doc(callId).update({'offer': description});

  @override
  Future<void> setAnswer(String callId, Map<String, dynamic> description) =>
      _calls.doc(callId).update({'answer': description});

  @override
  Future<void> addIceCandidate(String callId, {required bool fromStudent, required Map<String, dynamic> candidate}) =>
      _calls.doc(callId).collection('ice').add({
        'from': fromStudent ? 'student' : 'teacher',
        'senderId': _me,
        'c': candidate,
      });

  @override
  Stream<List<Map<String, dynamic>>> iceCandidates(String callId, {required bool fromStudent}) => _calls
      .doc(callId)
      .collection('ice')
      .where('from', isEqualTo: fromStudent ? 'student' : 'teacher')
      .snapshots()
      .map((s) => [for (final d in s.docs) ((d.data()['c'] as Map?) ?? const {}).cast<String, dynamic>()]);

  @override
  Future<void> setBusy(bool busy) async {
    final me = _me;
    if (me == null) return;
    await db.collection('presence').doc(me).update({'busy': busy, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> presenceHeartbeat() async {
    final me = _me;
    if (me == null) return;
    await db.collection('presence').doc(me).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  /// Whether a presence entry has had a heartbeat recently (a write still on
  /// its way counts as now).
  static bool isFresh(Map<String, dynamic> p) {
    final at = p['updatedAt'];
    if (at is! Timestamp) return at == null;
    return DateTime.now().difference(at.toDate()) < presenceFresh;
  }

  @override
  Future<void> openChatAfterCall(CallInfo call) async {
    final teacher = call.teacherId;
    if (teacher == null || _me != call.studentId) return;
    final ref = db.collection('conversations').doc('${call.studentId}_$teacher');
    // A student can't read a chat that doesn't exist yet, so "already open"
    // shows up as a refused read.
    try {
      if ((await ref.get()).exists) return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    final callDoc = (await _calls.doc(call.id).get()).data() ?? const {};
    await ref.set({
      'members': [call.studentId, teacher],
      'names': {call.studentId: call.studentName, teacher: call.teacherName},
      'avatars': {call.studentId: call.studentAvatar, teacher: call.teacherAvatar},
      'roles': {call.studentId: UserRole.student.name, teacher: UserRole.teacher.name},
      'gender': callDoc['gender'],
      'unread': {call.studentId: 0, teacher: 0},
      'blockedBy': <String>[],
      'lastText': '',
      'fromCall': call.id,
      'createdBy': _me,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
