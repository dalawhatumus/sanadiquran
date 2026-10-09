import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/settings.dart';
import 'chat.dart';

/// Chat on Firestore.
///
/// - conversations/{studentUid_teacherUid}: members, names, avatars, roles,
///   the last message preview, unread counts per member, blockedBy.
///   Only admins create them (later: the first lesson).
/// - conversations/{id}/messages/{id}: senderId, type, text or durationSec,
///   sentAt.
/// - conversations/{id}/audio/{messageId}: the voice note itself (AAC bytes),
///   kept apart so opening a chat doesn't download every recording.
/// - reports/{id}: written by users, read by admins.
mixin FirestoreChat implements ChatApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  @override
  String? get myUid => auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _convs => db.collection('conversations');

  Stream<T> _signedIn<T>(Stream<T> Function(String uid) build, T signedOut) =>
      auth.authStateChanges().asyncExpand((u) => u == null ? Stream.value(signedOut) : build(u.uid));

  static DateTime? _time(Object? v) => v is Timestamp ? v.toDate() : null;

  static String _str(Map<dynamic, dynamic>? m, String key) => (m?[key] as String?) ?? '';

  @override
  Stream<List<Conversation>> conversations() => _signedIn(
    (me) => _convs.where('members', arrayContains: me).snapshots().map((s) {
      final list = [
        for (final d in s.docs)
          () {
            final c = d.data();
            final members = ((c['members'] as List?) ?? const []).cast<String>();
            final other = members.firstWhere((m) => m != me, orElse: () => '');
            final blockedBy = ((c['blockedBy'] as List?) ?? const []).cast<String>();
            return Conversation(
              id: d.id,
              otherUid: other,
              otherName: _str(c['names'] as Map?, other),
              otherAvatar: (c['avatars'] as Map?)?[other] as String?,
              otherRole: UserRole.values.where((r) => r.name == (c['roles'] as Map?)?[other]).firstOrNull,
              lastText: (c['lastText'] as String?) ?? '',
              lastVoiceSec: (c['lastVoiceSec'] as num?)?.toInt(),
              lastAt: _time(c['lastAt']) ?? _time(c['createdAt']),
              unread: (((c['unread'] as Map?)?[me]) as num?)?.toInt() ?? 0,
              blockedByMe: blockedBy.contains(me),
              blockedByOther: blockedBy.any((b) => b != me),
            );
          }(),
      ];
      list.sort((a, b) => (b.lastAt ?? DateTime(2000)).compareTo(a.lastAt ?? DateTime(2000)));
      return list;
    }),
    const <Conversation>[],
  );

  @override
  Stream<List<ChatMessage>> messages(String conversationId) => _convs
      .doc(conversationId)
      .collection('messages')
      .orderBy('sentAt')
      .limitToLast(300)
      .snapshots(includeMetadataChanges: true)
      .map(
        (s) => [
          for (final d in s.docs)
            ChatMessage(
              id: d.id,
              senderId: _str(d.data(), 'senderId'),
              type: d.data()['type'] == 'voice' ? MessageType.voice : MessageType.text,
              text: _str(d.data(), 'text'),
              durationSec: (d.data()['durationSec'] as num?)?.toInt() ?? 0,
              // A message still on its way has no server time yet.
              sentAt: _time(d.data()['sentAt']) ?? DateTime.now(),
              pending: d.metadata.hasPendingWrites,
            ),
        ],
      );

  /// The conversation's other member (conversation ids are both uids).
  String _other(String conversationId) =>
      conversationId.split('_').firstWhere((u) => u != myUid, orElse: () => conversationId);

  Map<String, Object?> _preview(String conversationId, {String text = '', int? voiceSec}) => {
    'lastText': text.length > 120 ? '${text.substring(0, 120)}…' : text,
    'lastVoiceSec': voiceSec,
    'lastSender': myUid,
    'lastAt': FieldValue.serverTimestamp(),
    'unread.${_other(conversationId)}': FieldValue.increment(1),
  };

  @override
  Future<void> sendText(String conversationId, String text) {
    final c = _convs.doc(conversationId);
    final msg = c.collection('messages').doc();
    final batch = db.batch()
      ..set(msg, {'senderId': myUid, 'type': 'text', 'text': text, 'sentAt': FieldValue.serverTimestamp()})
      ..update(c, _preview(conversationId, text: text));
    return batch.commit();
  }

  @override
  Future<void> sendVoice(String conversationId, Uint8List audio, int durationSec) {
    final c = _convs.doc(conversationId);
    final msg = c.collection('messages').doc();
    final batch = db.batch()
      ..set(c.collection('audio').doc(msg.id), {
        'senderId': myUid,
        'data': Blob(audio),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(msg, {
        'senderId': myUid,
        'type': 'voice',
        'durationSec': durationSec,
        'sentAt': FieldValue.serverTimestamp(),
      })
      ..update(c, _preview(conversationId, voiceSec: durationSec));
    return batch.commit();
  }

  @override
  Future<Uint8List> voiceAudio(String conversationId, String messageId) async {
    final d = await _convs.doc(conversationId).collection('audio').doc(messageId).get();
    final blob = d.data()?['data'];
    if (blob is! Blob) throw StateError('Voice note not found');
    return blob.bytes;
  }

  @override
  Future<void> deleteMessage(String conversationId, ChatMessage message) {
    final c = _convs.doc(conversationId);
    final batch = db.batch()..delete(c.collection('messages').doc(message.id));
    if (message.type == MessageType.voice) batch.delete(c.collection('audio').doc(message.id));
    return batch.commit();
  }

  @override
  Future<void> markRead(String conversationId) async {
    final me = myUid;
    if (me == null) return;
    await _convs.doc(conversationId).update({'unread.$me': 0});
  }

  @override
  Future<void> setBlocked(String conversationId, {required bool blocked}) => _convs.doc(conversationId).update({
    'blockedBy': blocked ? FieldValue.arrayUnion([myUid]) : FieldValue.arrayRemove([myUid]),
  });

  @override
  Future<void> report({
    required String conversationId,
    required String reportedUid,
    required ReportReason reason,
    String details = '',
  }) async {
    final c = await _convs.doc(conversationId).get();
    final names = (c.data()?['names'] as Map?) ?? const {};
    await db.collection('reports').add({
      'reporterId': myUid,
      'reporterName': names[myUid] ?? '',
      'reportedId': reportedUid,
      'reportedName': names[reportedUid] ?? '',
      'conversationId': conversationId,
      'reason': reason.name,
      'details': details.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<bool> teacherAvailable(String uid) => _signedIn(
    (_) => db.collection('presence').doc(uid).snapshots().map((d) => d.data()?['available'] == true),
    false,
  ).handleError((_) {});

  // ---- Admins ----

  @override
  Future<List<PersonSummary>> students() async {
    final s = await db.collection('users').where('role', isEqualTo: UserRole.student.name).get();
    return [
      for (final d in s.docs)
        PersonSummary(
          uid: d.id,
          name: _str(d.data(), 'name'),
          gender: Gender.values.where((g) => g.name == d.data()['gender']).firstOrNull,
          role: UserRole.student,
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<List<PersonSummary>> approvedTeachers() async {
    final s = await db.collection('teacherApplications').where('status', isEqualTo: TeacherStatus.approved.name).get();
    return [
      for (final d in s.docs)
        PersonSummary(
          uid: d.id,
          name: _str(d.data(), 'name'),
          gender: Gender.values.where((g) => g.name == d.data()['gender']).firstOrNull,
          role: UserRole.teacher,
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<void> connect(PersonSummary student, PersonSummary teacher) async {
    if (student.gender == null || student.gender != teacher.gender) {
      throw StateError('A student and teacher must be of the same gender.');
    }
    final users = db.collection('users');
    final s = (await users.doc(student.uid).get()).data() ?? const {};
    final t = (await users.doc(teacher.uid).get()).data() ?? const {};
    final ref = _convs.doc('${student.uid}_${teacher.uid}');
    if ((await ref.get()).exists) return;
    await ref.set({
      'members': [student.uid, teacher.uid],
      'names': {student.uid: s['name'] ?? student.name, teacher.uid: t['name'] ?? teacher.name},
      'avatars': {student.uid: s['avatar'], teacher.uid: t['avatar']},
      'roles': {student.uid: UserRole.student.name, teacher.uid: UserRole.teacher.name},
      'gender': student.gender!.name,
      'unread': {student.uid: 0, teacher.uid: 0},
      'blockedBy': <String>[],
      'lastText': '',
      'createdBy': myUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<UserReport>> reports() => _signedIn(
    (_) => db
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              UserReport(
                id: d.id,
                reporterName: _str(d.data(), 'reporterName'),
                reportedName: _str(d.data(), 'reportedName'),
                reason: _str(d.data(), 'reason'),
                details: _str(d.data(), 'details'),
                at: _time(d.data()['createdAt']),
              ),
          ]..sort((a, b) => (b.at ?? DateTime(2100)).compareTo(a.at ?? DateTime(2100))),
        ),
    const <UserReport>[],
  );
}
