import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/settings.dart';
import 'calls.dart';
import 'user_stream.dart';

/// Calls on Firestore.
///
/// - calls/{id}: studentId, names and pictures, gender, status, the teacher
///   being rung (teacherId), teachers already tried, and the WebRTC offer and
///   answer; direction "toStudent" when a teacher rang the student. Only its
///   student and (once rung) its teacher can read it.
/// - calls/{id}/ice/{id}: network routes from each side.
/// - presence/{uid}.busy: a teacher in a call isn't rung by anyone else.
/// - beats/{uid}.at: an available teacher's "still here", every minute.
mixin FirestoreCalls implements CallApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  String? get _me => auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _calls => db.collection('calls');

  /// Marks a call a teacher made to a student.
  static const _toStudent = 'toStudent';

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
      fromTeacher: c['direction'] == _toStudent,
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
    final listed = [
      for (final d in s.docs)
        if (d.data()['busy'] != true && d.id != _me && !exclude.contains(d.id) && isListed(d.data())) d,
    ];
    // Only teachers whose phone said "still here" lately are rung.
    final beats = <String, Object?>{};
    for (var i = 0; i < listed.length; i += 30) {
      final ids = [for (final d in listed.skip(i).take(30)) d.id];
      final b = await db.collection('beats').where(FieldPath.documentId, whereIn: ids).get();
      for (final d in b.docs) {
        beats[d.id] = d.data()['at'];
      }
    }
    final free = [
      for (final d in listed)
        if (isBeatFresh(beats[d.id])) Candidate(d.id, lessonsToday: lessonsToday(d.data())),
    ]..shuffle(Random());
    return free;
  }

  /// Today's lesson count from a presence document (0 if it was written on
  /// another day).
  static int lessonsToday(Map<String, dynamic> d) {
    final day = DateTime.now().toIso8601String().substring(0, 10);
    return d['lessonsDay'] == day ? ((d['lessonsToday'] as num?)?.toInt() ?? 0) : 0;
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
    if (status == CallStatus.active) 'acceptedAt': FieldValue.serverTimestamp(),
    if (status == CallStatus.ended || status == CallStatus.cancelled || status == CallStatus.unmatched)
      'endedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> acceptCall(String callId, {required String name, String? avatar}) async {
    final me = _me;
    final ref = _calls.doc(callId);
    // Only while it still rings for this teacher: the student may have
    // given up, or moved on to someone else, a moment ago.
    await db.runTransaction((tx) async {
      final d = await tx.get(ref);
      final c = d.data();
      if (c == null || c['status'] != CallStatus.ringing.name || c['teacherId'] != me) throw const CallGone();
      tx.update(ref, {
        'status': CallStatus.active.name,
        'teacherName': name,
        'teacherAvatar': avatar,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<CallStatus> unring(String callId, String teacherId) async {
    final ref = _calls.doc(callId);
    return db.runTransaction((tx) async {
      final d = await tx.get(ref);
      final c = d.data();
      final status = CallStatus.values.where((s) => s.name == c?['status']).firstOrNull ?? CallStatus.ended;
      if (c == null || c['teacherId'] != teacherId) return status;
      if (status != CallStatus.ringing && status != CallStatus.declined) return status;
      tx.update(ref, {'status': CallStatus.searching.name});
      return CallStatus.searching;
    });
  }

  @override
  Future<void> clearRoutes(String callId) async {
    final me = _me;
    if (me == null) return;
    final ref = _calls.doc(callId);
    // Each phone removes its own routes (that's all the rules allow), and
    // the connection details once the call is over.
    final mine = await ref.collection('ice').where('senderId', isEqualTo: me).get();
    final batch = db.batch();
    for (final d in mine.docs) {
      batch.delete(d.reference);
    }
    batch.update(ref, {'offer': FieldValue.delete(), 'answer': FieldValue.delete()});
    await batch.commit();
  }

  @override
  Stream<CallInfo?> watchCall(String callId) => _calls.doc(callId).snapshots().map((d) => d.exists ? _info(d) : null);

  @override
  Stream<List<CallInfo>> incomingCalls() => perUser(
    auth,
    (uid) => _calls
        .where('teacherId', isEqualTo: uid)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .snapshots()
        .map((s) => [for (final d in s.docs) _info(d)]),
    const <CallInfo>[],
  );

  @override
  Future<String> callStudent({
    required String studentId,
    required String studentName,
    String? studentAvatar,
    required String name,
    String? avatar,
    required Gender gender,
  }) async {
    final ref = _calls.doc();
    await ref.set({
      'studentId': studentId,
      'studentName': studentName,
      'studentAvatar': studentAvatar,
      'teacherId': _me,
      'teacherName': name,
      'teacherAvatar': avatar,
      'gender': gender.name,
      'status': CallStatus.ringing.name,
      'direction': _toStudent,
      'tried': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Stream<List<CallInfo>> callsFromTeachers() => perUser(
    auth,
    (uid) => _calls
        .where('studentId', isEqualTo: uid)
        .where('direction', isEqualTo: _toStudent)
        .where('status', isEqualTo: CallStatus.ringing.name)
        .snapshots()
        .map((s) => [for (final d in s.docs) _info(d)]),
    const <CallInfo>[],
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
  Future<void> presenceHeartbeat({bool list = false}) async {
    final me = _me;
    if (me == null) return;
    // Kept apart from presence/{uid}, which every student of that gender
    // watches: a beat there would be a read for each of them every minute.
    await db.collection('beats').doc(me).set({'at': FieldValue.serverTimestamp()});
    if (list) await db.collection('presence').doc(me).update({'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> setLessonsToday(int count) async {
    final me = _me;
    if (me == null) return;
    await db.collection('presence').doc(me).update({
      'lessonsToday': count.clamp(0, 200),
      'lessonsDay': DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  /// Whether a presence entry was refreshed recently enough to be listed
  /// (a write still on its way counts as now).
  static bool isListed(Map<String, dynamic> p) {
    final at = p['updatedAt'];
    if (at is! Timestamp) return at == null;
    return DateTime.now().difference(at.toDate()) < listFresh;
  }

  /// Whether a teacher's last "still here" beat is recent enough to ring them.
  static bool isBeatFresh(Object? at) => at is Timestamp && DateTime.now().difference(at.toDate()) < presenceFresh;

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
