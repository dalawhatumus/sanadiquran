import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/log.dart';
import '../core/settings.dart';
import 'admin.dart';
import 'user_stream.dart';

/// Pausing accounts and the overview, on Firestore.
///
/// - suspensions/{uid}: reason, by (the admin), at. Written only by admins;
///   the rules check it before messages, calls and "available".
mixin FirestoreAdmin implements AdminApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  DocumentReference<Map<String, dynamic>> _suspension(String uid) => db.collection('suspensions').doc(uid);

  @override
  Stream<bool> paused() => perUser(auth, (uid) => _suspension(uid).snapshots().map((d) => d.exists), false);

  @override
  Stream<List<UserEntry>> users() => perUser(auth, (_) {
    late final StreamController<List<UserEntry>> out;
    QuerySnapshot<Map<String, dynamic>>? people;
    var pausedIds = <String>{};
    final subs = <StreamSubscription<Object?>>[];
    void emit() {
      final p = people;
      if (p == null) return;
      out.add(
        byName([
          for (final d in p.docs)
            UserEntry(
              uid: d.id,
              name: (d.data()['name'] as String?) ?? '',
              role: UserRole.values.where((r) => r.name == d.data()['role']).firstOrNull,
              gender: Gender.values.where((g) => g.name == d.data()['gender']).firstOrNull,
              paused: pausedIds.contains(d.id),
            ),
        ], (u) => u.name),
      );
    }

    out = StreamController<List<UserEntry>>(
      onListen: () {
        subs
          ..add(
            db.collection('users').snapshots().listen((s) {
              people = s;
              emit();
            }, onError: out.addError),
          )
          ..add(
            db.collection('suspensions').snapshots().listen((s) {
              pausedIds = {for (final d in s.docs) d.id};
              emit();
            }, onError: out.addError),
          );
      },
      onCancel: () {
        for (final s in subs) {
          s.cancel();
        }
      },
    );
    return out.stream;
  }, const <UserEntry>[]);

  @override
  Future<void> setPaused(String uid, {required bool paused, String reason = ''}) async {
    if (!paused) return _suspension(uid).delete();
    final batch = db.batch()
      ..set(_suspension(uid), {
        'reason': reason.trim(),
        'by': auth.currentUser?.uid,
        'at': FieldValue.serverTimestamp(),
      })
      // No more calls to a paused teacher.
      ..delete(db.collection('presence').doc(uid));
    await batch.commit();
  }

  @override
  Future<AdminStats> stats() async {
    Future<int?> countOf(Query<Map<String, dynamic>> q) async {
      try {
        return (await q.count().get()).count;
      } catch (e) {
        logIssue('Count failed: $e');
        return null;
      }
    }

    final weekAgo = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    int? lessons;
    int? minutes;
    try {
      final week = await db
          .collection('sessions')
          .where('startedAt', isGreaterThanOrEqualTo: weekAgo)
          .aggregate(count(), sum('durationSec'))
          .get();
      lessons = week.count;
      minutes = ((week.getSum('durationSec') ?? 0) / 60).round();
    } catch (e) {
      logIssue('Lesson stats failed: $e');
    }
    final apps = db.collection('teacherApplications');
    final results = await Future.wait([
      countOf(db.collection('users').where('role', isEqualTo: UserRole.student.name)),
      countOf(apps.where('status', isEqualTo: TeacherStatus.approved.name)),
      countOf(db.collection('presence').where('available', isEqualTo: true)),
      countOf(apps.where('status', isEqualTo: TeacherStatus.pending.name)),
      countOf(db.collection('reports').where('status', isEqualTo: 'open')),
    ]);
    return AdminStats(
      students: results[0],
      teachers: results[1],
      teachersOn: results[2],
      pendingApplications: results[3],
      openReports: results[4],
      lessonsWeek: lessons,
      minutesWeek: minutes,
    );
  }
}
