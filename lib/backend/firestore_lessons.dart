import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/settings.dart';
import 'sessions.dart';

/// Lessons on Firestore: sessions/{callId}, readable by its student and
/// teacher. Either of them saves it when the call ends; only the teacher
/// writes notes, only the student rates.
mixin FirestoreLessons implements LessonApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  CollectionReference<Map<String, dynamic>> get _sessions => db.collection('sessions');

  static Lesson _lesson(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Lesson(
      id: d.id,
      studentId: (m['studentId'] as String?) ?? '',
      teacherId: (m['teacherId'] as String?) ?? '',
      studentName: (m['studentName'] as String?) ?? '',
      teacherName: (m['teacherName'] as String?) ?? '',
      studentAvatar: m['studentAvatar'] as String?,
      teacherAvatar: m['teacherAvatar'] as String?,
      at: (m['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationSec: (m['durationSec'] as num?)?.toInt() ?? 0,
      notes: LessonNotes.fromMap(m['notes']),
      rating: (m['rating'] as num?)?.toInt(),
    );
  }

  @override
  Stream<List<Lesson>> lessons() => auth.authStateChanges().asyncExpand((u) {
    if (u == null) return Stream.value(const <Lesson>[]);
    // A user is a student or a teacher; both queries are cheap, and the
    // one that doesn't apply is simply empty.
    final asStudent = _sessions.where('studentId', isEqualTo: u.uid).snapshots();
    final asTeacher = _sessions.where('teacherId', isEqualTo: u.uid).snapshots();
    var a = const <Lesson>[];
    var b = const <Lesson>[];
    List<Lesson> merged() => [...a, ...b]..sort((x, y) => y.at.compareTo(x.at));
    return Stream<List<Lesson>>.multi((out) {
      final s1 = asStudent.listen((s) {
        a = [for (final d in s.docs) _lesson(d)];
        out.add(merged());
      }, onError: (_) {});
      final s2 = asTeacher.listen((s) {
        b = [for (final d in s.docs) _lesson(d)];
        out.add(merged());
      }, onError: (_) {});
      out.onCancel = () {
        s1.cancel();
        s2.cancel();
      };
    });
  });

  @override
  Future<void> recordLesson({
    required String callId,
    required String studentId,
    required String teacherId,
    required String studentName,
    required String teacherName,
    String? studentAvatar,
    String? teacherAvatar,
    required Gender gender,
    required DateTime startedAt,
    required int durationSec,
  }) async {
    final ref = _sessions.doc(callId);
    // The other person may have saved it already.
    try {
      if ((await ref.get()).exists) return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    await ref.set({
      'studentId': studentId,
      'teacherId': teacherId,
      'studentName': studentName,
      'teacherName': teacherName,
      'studentAvatar': studentAvatar,
      'teacherAvatar': teacherAvatar,
      'gender': gender.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'durationSec': durationSec,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveNotes(String lessonId, LessonNotes notes) => _sessions.doc(lessonId).update({
    'notes': {...notes.toMap(), 'at': FieldValue.serverTimestamp()},
  });

  @override
  Future<void> rateLesson(String lessonId, int rating) => _sessions.doc(lessonId).update({'rating': rating});
}
