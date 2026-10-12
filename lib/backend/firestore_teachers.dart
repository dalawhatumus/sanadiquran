import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/settings.dart';
import 'firestore_calls.dart';
import 'teachers.dart';
import 'user_stream.dart';

/// The teacher list and "waiting" students, on Firestore.
///
/// - presence/{teacherUid}: available, busy, gender, name, avatar,
///   updatedAt (heartbeat). Students read only teachers of their own gender.
/// - waiting/{studentUid}: gender, until. Teachers of that gender read them.
mixin FirestoreTeachers implements TeacherDirectoryApi {
  FirebaseFirestore get db;
  FirebaseAuth get auth;

  /// Re-reads [query] on every change and every [every], since heartbeats
  /// and "until" times age without the documents changing.
  Stream<T> _recounted<T>(
    Query<Map<String, dynamic>> query,
    T Function(QuerySnapshot<Map<String, dynamic>> s) read, {
    Duration every = const Duration(seconds: 30),
  }) {
    late final StreamController<T> out;
    QuerySnapshot<Map<String, dynamic>>? last;
    StreamSubscription<Object?>? sub;
    Timer? tick;
    void emit() {
      final s = last;
      if (s != null) out.add(read(s));
    }

    out = StreamController<T>(
      onListen: () {
        sub = query.snapshots().listen((s) {
          last = s;
          emit();
        }, onError: out.addError);
        tick = Timer.periodic(every, (_) => emit());
      },
      onCancel: () {
        tick?.cancel();
        sub?.cancel();
      },
    );
    return out.stream;
  }

  static TeacherState _state(Map<String, dynamic> p) {
    if (p['available'] != true || !FirestoreCalls.isFresh(p)) return TeacherState.away;
    return p['busy'] == true ? TeacherState.busy : TeacherState.available;
  }

  @override
  Stream<List<TeacherEntry>> teachers(Gender gender) => perUser(
    auth,
    (me) => _recounted(
      db.collection('presence').where('gender', isEqualTo: gender.name),
      (s) => sortTeachers([
        for (final d in s.docs)
          if (d.id != me)
            TeacherEntry(
              uid: d.id,
              name: (d.data()['name'] as String?) ?? '',
              avatar: d.data()['avatar'] as String?,
              state: _state(d.data()),
            ),
      ]),
    ),
    const <TeacherEntry>[],
  );

  @override
  Future<void> setWaiting({required Gender gender, DateTime? until}) async {
    final me = auth.currentUser?.uid;
    if (me == null) return;
    final doc = db.collection('waiting').doc(me);
    if (until == null) return doc.delete();
    await doc.set({'gender': gender.name, 'until': Timestamp.fromDate(until)});
  }

  @override
  Stream<int> waitingStudents(Gender gender) => perUser(
    auth,
    (_) => _recounted(db.collection('waiting').where('gender', isEqualTo: gender.name), (s) {
      final now = DateTime.now();
      return s.docs.where((d) => ((d.data()['until'] as Timestamp?)?.toDate() ?? now).isAfter(now)).length;
    }, every: const Duration(seconds: 60)),
    0,
  );
}
