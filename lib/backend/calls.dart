import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings.dart';
import 'backend.dart';

/// Where a call stands, as stored on the server.
enum CallStatus {
  /// The student is waiting while the app looks for a teacher.
  searching,

  /// A teacher's phone is ringing.
  ringing,

  /// The teacher said no (or didn't answer); the app tries the next one.
  declined,

  /// Accepted: the two phones connect.
  active,
  ended,

  /// The student cancelled before anyone answered.
  cancelled,

  /// No teacher was free.
  unmatched,
}

/// A call between a student and a teacher.
class CallInfo {
  const CallInfo({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentAvatar,
    this.teacherId,
    this.teacherName = '',
    this.teacherAvatar,
    required this.status,
    this.offer,
    this.answer,
    this.fromTeacher = false,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String? studentAvatar;
  final String? teacherId;
  final String teacherName;
  final String? teacherAvatar;
  final CallStatus status;

  /// The teacher rang the student (rather than the student looking for a
  /// teacher).
  final bool fromTeacher;

  /// WebRTC session descriptions ({type, sdp}).
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
}

/// A teacher counts as reachable this long after their last heartbeat.
const presenceFresh = Duration(seconds: 150);

/// A teacher who could take a call now.
class Candidate {
  const Candidate(this.uid, {this.lessonsToday = 0});
  final String uid;

  /// Lessons this teacher has given today (to share calls out fairly).
  final int lessonsToday;
}

/// The order a student's call tries free teachers: the one they chose,
/// then their own teachers (favourites, then those they had lessons with,
/// most recent first), then the teachers who have taught least today. Ties
/// keep the order given (shuffled by the server query), so calls are
/// shared out.
///
/// Every candidate is already the student's gender: the server only lists
/// (and its rules only let a call ring) teachers of the same gender.
List<Candidate> rankCandidates(
  List<Candidate> free, {
  String? preferred,
  Set<String> favourites = const {},
  List<String> previous = const [],
}) {
  int rank(Candidate c) {
    if (c.uid == preferred) return 0;
    if (favourites.contains(c.uid)) return 1;
    final i = previous.indexOf(c.uid);
    if (i >= 0) return 2 + i;
    return 1 << 20;
  }

  final order = {for (var i = 0; i < free.length; i++) free[i].uid: i};
  return [...free]..sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final l = a.lessonsToday.compareTo(b.lessonsToday);
    if (l != 0) return l;
    return order[a.uid]!.compareTo(order[b.uid]!);
  });
}

/// Calls without a server of our own: the student's app finds a free
/// teacher of the same gender and rings them by writing to the call;
/// the teacher's app (while open) sees it ring. A teacher can also ring one
/// of their own students. Either way the two phones then exchange WebRTC
/// connection details through the call document (the student always sends
/// the offer, the teacher the answer).
abstract interface class CallApi {
  /// Creates a call for this student; returns its id.
  Future<String> createCall({required String name, String? avatar, required Gender gender});

  /// Teachers of [gender] who are available and not in a call, excluding
  /// [exclude] (already tried) and this user.
  Future<List<Candidate>> freeTeachers(Gender gender, {Set<String> exclude = const {}});

  /// Rings [teacherId] for this call.
  Future<void> ring(String callId, String teacherId);

  /// Updates the call's status (and when it ended).
  Future<void> setCallStatus(String callId, CallStatus status);

  /// The teacher accepts, adding their name and picture.
  Future<void> acceptCall(String callId, {required String name, String? avatar});

  Stream<CallInfo?> watchCall(String callId);

  /// Calls ringing for this teacher now.
  Stream<List<CallInfo>> incomingCalls();

  /// A teacher rings one of their students (someone they share a chat
  /// with); returns the call's id.
  Future<String> callStudent({
    required String studentId,
    required String studentName,
    String? studentAvatar,
    required String name,
    String? avatar,
    required Gender gender,
  });

  /// Calls from teachers ringing for this student now.
  Stream<List<CallInfo>> callsFromTeachers();

  Future<void> setOffer(String callId, Map<String, dynamic> description);
  Future<void> setAnswer(String callId, Map<String, dynamic> description);

  /// Network routes found by one side, for the other ([fromStudent] says
  /// whose they are).
  Future<void> addIceCandidate(String callId, {required bool fromStudent, required Map<String, dynamic> candidate});
  Stream<List<Map<String, dynamic>>> iceCandidates(String callId, {required bool fromStudent});

  /// Marks this teacher as in a call, so no one else rings them.
  Future<void> setBusy(bool busy);

  /// "Still here": sent every minute while an available teacher has the app
  /// open. Teachers who stop sending it aren't rung (or counted).
  Future<void> presenceHeartbeat();

  /// How many lessons this teacher has given today, so students' calls go
  /// first to teachers who have taught least.
  Future<void> setLessonsToday(int count);

  /// After a call, opens the chat between its student and teacher (if it
  /// isn't open already).
  Future<void> openChatAfterCall(CallInfo call);
}

final incomingCallsProvider = StreamProvider<List<CallInfo>>((ref) => ref.watch(backendProvider).incomingCalls());

final callsFromTeachersProvider = StreamProvider<List<CallInfo>>(
  (ref) => ref.watch(backendProvider).callsFromTeachers(),
);

/// Demo mode: a pretend teacher answers after a moment and the call has no
/// audio, so the screens can be tried without a server.
mixin DemoCalls implements CallApi {
  final _calls = <String, CallInfo>{};
  final _callChanges = StreamController<String>.broadcast();

  void _set(CallInfo c) {
    _calls[c.id] = c;
    _callChanges.add(c.id);
  }

  CallInfo _copy(CallInfo c, {CallStatus? status, String? teacherId, String? teacherName, String? teacherAvatar}) =>
      CallInfo(
        id: c.id,
        studentId: c.studentId,
        studentName: c.studentName,
        studentAvatar: c.studentAvatar,
        teacherId: teacherId ?? c.teacherId,
        teacherName: teacherName ?? c.teacherName,
        teacherAvatar: teacherAvatar ?? c.teacherAvatar,
        status: status ?? c.status,
        fromTeacher: c.fromTeacher,
      );

  @override
  Future<String> createCall({required String name, String? avatar, required Gender gender}) async {
    final id = 'demo-call-${_calls.length + 1}';
    _set(CallInfo(id: id, studentId: 'demo', studentName: name, studentAvatar: avatar, status: CallStatus.searching));
    return id;
  }

  @override
  Future<List<Candidate>> freeTeachers(Gender gender, {Set<String> exclude = const {}}) async =>
      exclude.contains('demo-teacher') ? const [] : const [Candidate('demo-teacher')];

  @override
  Future<void> ring(String callId, String teacherId) async {
    _set(_copy(_calls[callId]!, status: CallStatus.ringing, teacherId: teacherId));
    // The pretend teacher answers after a moment.
    Timer(const Duration(seconds: 2), () {
      final c = _calls[callId];
      if (c != null && c.status == CallStatus.ringing) {
        _set(_copy(c, status: CallStatus.active, teacherName: 'Aisha Rahman', teacherAvatar: 'ft2'));
      }
    });
  }

  @override
  Future<void> setCallStatus(String callId, CallStatus status) async {
    final c = _calls[callId];
    if (c != null) _set(_copy(c, status: status));
  }

  @override
  Future<void> acceptCall(String callId, {required String name, String? avatar}) async {
    final c = _calls[callId];
    if (c != null) _set(_copy(c, status: CallStatus.active, teacherName: name, teacherAvatar: avatar));
  }

  @override
  Stream<CallInfo?> watchCall(String callId) async* {
    yield _calls[callId];
    await for (final id in _callChanges.stream) {
      if (id == callId) yield _calls[callId];
    }
  }

  @override
  Stream<List<CallInfo>> incomingCalls() => Stream.value(const []);

  @override
  Future<String> callStudent({
    required String studentId,
    required String studentName,
    String? studentAvatar,
    required String name,
    String? avatar,
    required Gender gender,
  }) async {
    final id = 'demo-call-${_calls.length + 1}';
    _set(
      CallInfo(
        id: id,
        studentId: studentId,
        studentName: studentName,
        studentAvatar: studentAvatar,
        teacherId: 'demo-teacher',
        teacherName: name,
        teacherAvatar: avatar,
        status: CallStatus.ringing,
        fromTeacher: true,
      ),
    );
    // The pretend student answers after a moment.
    Timer(const Duration(seconds: 2), () {
      final c = _calls[id];
      if (c != null && c.status == CallStatus.ringing) _set(_copy(c, status: CallStatus.active));
    });
    return id;
  }

  @override
  Stream<List<CallInfo>> callsFromTeachers() => Stream.value(const []);

  @override
  Future<void> setOffer(String callId, Map<String, dynamic> description) async {}

  @override
  Future<void> setAnswer(String callId, Map<String, dynamic> description) async {}

  @override
  Future<void> addIceCandidate(
    String callId, {
    required bool fromStudent,
    required Map<String, dynamic> candidate,
  }) async {}

  @override
  Stream<List<Map<String, dynamic>>> iceCandidates(String callId, {required bool fromStudent}) =>
      Stream.value(const []);

  @override
  Future<void> setBusy(bool busy) async {}

  @override
  Future<void> presenceHeartbeat() async {}

  @override
  Future<void> setLessonsToday(int count) async {}

  @override
  Future<void> openChatAfterCall(CallInfo call) async {}
}
