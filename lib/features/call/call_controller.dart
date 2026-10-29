import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../backend/backend.dart';
import '../../backend/calls.dart';
import '../../backend/sessions.dart';
import '../../backend/teachers.dart';
import '../../core/log.dart';
import '../../core/settings.dart';
import 'audio_link.dart';
import 'call_state.dart';

export 'call_state.dart';

/// Makes the audio link: real WebRTC when connected to the server, a
/// silent stand-in in demo mode (and tests).
final audioLinkFactoryProvider = Provider<AudioLink Function()>((ref) {
  final b = ref.watch(backendProvider);
  return b.live ? () => WebRtcAudioLink(b) : FakeAudioLink.new;
});

/// Asks for the microphone. Overridden in tests.
final micPermissionProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => (await Permission.microphone.request()).isGranted,
);

/// How long each teacher's phone rings, and how long to look overall.
const ringFor = Duration(seconds: 30);
const searchFor = Duration(minutes: 2);

/// One call at a time: finding a teacher (student), answering (teacher),
/// the live audio, and the end.
class CallController extends Notifier<CallState> {
  StreamSubscription<CallInfo?>? _watch;
  AudioLink? _link;
  Completer<CallStatus>? _waiting;
  bool _cancelled = false;

  /// A teacher's call to a student stops ringing after [ringFor].
  Timer? _ringTimeout;

  Backend get _b => ref.read(backendProvider);

  @override
  CallState build() {
    ref.onDispose(_cleanUp);
    return const CallState();
  }

  /// "Recite now" (or "Call" on a teacher card, with [preferredTeacher]).
  Future<void> startAsStudent({String? preferredTeacher}) async {
    if (state.phase != CallPhase.idle) return;
    _cancelled = false;
    state = const CallState(phase: CallPhase.finding);
    if (!await ref.read(micPermissionProvider)()) {
      state = const CallState(phase: CallPhase.noMic);
      return;
    }
    final me = ref.read(settingsProvider);
    // Teachers are matched strictly by gender: without one, no call.
    final gender = me.gender;
    if (gender == null) {
      state = const CallState(phase: CallPhase.failed);
      return;
    }
    final String id;
    try {
      id = await _b.createCall(name: me.name.trim(), avatar: me.avatar, gender: gender);
    } catch (e) {
      logIssue('Call not created: $e');
      state = const CallState(phase: CallPhase.failed);
      return;
    }
    if (_cancelled) return _b.setCallStatus(id, CallStatus.cancelled).catchError((_) {});
    state = state.copyWith(callId: id);
    _watch = _b.watchCall(id).listen((c) => _onCall(c, asStudent: true));

    final tried = <String>{};
    var timedOut = false;
    final deadline = Timer(searchFor, () => timedOut = true);
    try {
      await _search(id, gender, tried, () => timedOut, preferredTeacher);
    } finally {
      deadline.cancel();
    }
  }

  Future<void> _search(
    String id,
    Gender gender,
    Set<String> tried,
    bool Function() timedOut,
    String? preferredTeacher,
  ) async {
    while (!_cancelled && state.searching) {
      if (timedOut()) {
        await _b.setCallStatus(id, CallStatus.unmatched).catchError((_) {});
        await _stopWatching();
        state = const CallState(phase: CallPhase.unmatched);
        return;
      }
      List<Candidate> free;
      try {
        free = await _b.freeTeachers(gender, exclude: tried);
      } catch (_) {
        free = const [];
      }
      if (_cancelled || !state.searching) return;
      if (free.isEmpty) {
        // Someone may switch on "available" soon; look again shortly.
        await Future<void>.delayed(const Duration(seconds: 5));
        continue;
      }
      final pick = rankCandidates(
        free,
        preferred: preferredTeacher,
        favourites: ref.read(favoriteTeachersProvider),
        previous: _previousTeachers(),
      ).first;
      tried.add(pick.uid);
      final waiter = _waiting = Completer<CallStatus>();
      try {
        await _b.ring(id, pick.uid);
      } catch (e) {
        logIssue('Ring failed: $e');
        continue;
      }
      if (_cancelled) return;
      state = state.copyWith(phase: CallPhase.ringing);
      final answer = await waiter.future.timeout(ringFor, onTimeout: () => CallStatus.declined);
      if (_cancelled || answer == CallStatus.active || state.inCall) return;
      // Not answered: on to the next teacher.
      await _b.setCallStatus(id, CallStatus.searching).catchError((_) {});
      state = state.copyWith(phase: CallPhase.finding);
    }
  }

  /// Teachers this student had lessons with, most recent first.
  List<String> _previousTeachers() {
    final me = _b.myUid;
    final seen = <String>[];
    for (final l in ref.read(lessonsProvider).value ?? const <Lesson>[]) {
      if (l.studentId == me && !seen.contains(l.teacherId)) seen.add(l.teacherId);
    }
    return seen;
  }

  /// Teacher: rings one of their students (from the student's page or the
  /// chat). The student's phone rings while Sanadi is open on it.
  Future<void> startAsTeacher({required String studentId, required String studentName, String? studentAvatar}) async {
    if (state.phase != CallPhase.idle) return;
    _cancelled = false;
    state = CallState(
      phase: CallPhase.ringing,
      asTeacher: true,
      otherName: studentName,
      otherAvatar: studentAvatar,
      otherUid: studentId,
    );
    if (!await ref.read(micPermissionProvider)()) {
      state = const CallState(phase: CallPhase.noMic, asTeacher: true);
      return;
    }
    final me = ref.read(settingsProvider);
    final gender = me.gender;
    if (gender == null) {
      state = const CallState(phase: CallPhase.failed, asTeacher: true);
      return;
    }
    final String id;
    try {
      id = await _b.callStudent(
        studentId: studentId,
        studentName: studentName,
        studentAvatar: studentAvatar,
        name: me.name.trim(),
        avatar: me.avatar,
        gender: gender,
      );
    } catch (e) {
      logIssue('Call not made: $e');
      state = const CallState(phase: CallPhase.failed, asTeacher: true);
      return;
    }
    if (_cancelled) return _b.setCallStatus(id, CallStatus.cancelled).catchError((_) {});
    state = state.copyWith(callId: id);
    _lastCall = CallInfo(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentAvatar: studentAvatar,
      teacherId: _b.myUid ?? 'demo-teacher',
      teacherName: me.name.trim(),
      teacherAvatar: me.avatar,
      status: CallStatus.ringing,
      fromTeacher: true,
    );
    _watch = _b.watchCall(id).listen(_onTeacherCall);
    _ringTimeout = Timer(ringFor, () async {
      if (state.phase != CallPhase.ringing || state.callId != id) return;
      await _stopWatching();
      await _b.setCallStatus(id, CallStatus.unmatched).catchError((_) {});
      state = state.copyWith(phase: CallPhase.unmatched);
    });
  }

  /// The student answered (or said no to) the teacher's call.
  void _onTeacherCall(CallInfo? c) {
    if (c == null) return;
    if (state.phase == CallPhase.ringing && c.status == CallStatus.active) {
      _ringTimeout?.cancel();
      state = state.copyWith(phase: CallPhase.connecting);
      _b.setBusy(true).catchError((_) {});
      _connect(c.id, asStudent: false);
    } else if (state.phase == CallPhase.ringing && c.status == CallStatus.declined) {
      _ringTimeout?.cancel();
      _stopWatching();
      state = state.copyWith(phase: CallPhase.unmatched);
    } else if (c.status == CallStatus.ended && state.inCall) {
      _finish();
    }
  }

  /// Student: answers a call from their teacher.
  Future<void> acceptFromTeacher(CallInfo call) async {
    if (state.phase != CallPhase.idle) return;
    state = CallState(
      phase: CallPhase.connecting,
      callId: call.id,
      otherName: call.teacherName,
      otherAvatar: call.teacherAvatar,
      otherUid: call.teacherId,
    );
    if (!await ref.read(micPermissionProvider)()) {
      await declineFromTeacher(call);
      state = const CallState(phase: CallPhase.noMic);
      return;
    }
    _lastCall = call;
    try {
      await _b.setCallStatus(call.id, CallStatus.active);
    } catch (e) {
      logIssue('Answer failed: $e');
      state = const CallState(phase: CallPhase.failed);
      return;
    }
    _watch = _b.watchCall(call.id).listen((c) => _onCall(c, asStudent: true));
    await _connect(call.id, asStudent: true);
  }

  /// Student: says no to (or misses) a call from their teacher.
  Future<void> declineFromTeacher(CallInfo call) => _b.setCallStatus(call.id, CallStatus.declined).catchError((_) {});

  /// Stops looking (student) or ringing (teacher), before anyone answers.
  Future<void> cancel() async {
    _cancelled = true;
    _ringTimeout?.cancel();
    final id = state.callId;
    _resolve(CallStatus.cancelled);
    await _stopWatching();
    if (id != null) await _b.setCallStatus(id, CallStatus.cancelled).catchError((_) {});
    state = const CallState();
  }

  /// Teacher: answers a ringing call.
  Future<void> accept(CallInfo call) async {
    if (state.phase != CallPhase.idle) return;
    state = CallState(
      phase: CallPhase.connecting,
      callId: call.id,
      asTeacher: true,
      otherName: call.studentName,
      otherAvatar: call.studentAvatar,
      otherUid: call.studentId,
    );
    if (!await ref.read(micPermissionProvider)()) {
      await decline(call);
      state = const CallState(phase: CallPhase.noMic, asTeacher: true);
      return;
    }
    final me = ref.read(settingsProvider);
    _lastCall = CallInfo(
      id: call.id,
      studentId: call.studentId,
      studentName: call.studentName,
      studentAvatar: call.studentAvatar,
      teacherId: call.teacherId ?? _b.myUid ?? 'demo-teacher',
      teacherName: me.name.trim(),
      teacherAvatar: me.avatar,
      status: CallStatus.active,
    );
    try {
      await _b.setBusy(true);
      await _b.acceptCall(call.id, name: me.name.trim(), avatar: me.avatar);
    } catch (e) {
      logIssue('Accept failed: $e');
      await _b.setBusy(false).catchError((_) {});
      state = const CallState(phase: CallPhase.failed, asTeacher: true);
      return;
    }
    _watch = _b.watchCall(call.id).listen((c) => _onCall(c, asStudent: false));
    await _connect(call.id, asStudent: false);
  }

  /// Teacher: says no (or didn't answer in time).
  Future<void> decline(CallInfo call) => _b.setCallStatus(call.id, CallStatus.declined).catchError((_) {});

  /// Either side hangs up.
  Future<void> hangUp() async {
    final id = state.callId;
    if (id != null) await _b.setCallStatus(id, CallStatus.ended).catchError((_) {});
    await _finish();
  }

  Future<void> toggleMute() async {
    final m = !state.muted;
    state = state.copyWith(muted: m);
    await _link?.setMuted(m);
  }

  Future<void> toggleSpeaker() async {
    final on = !state.speaker;
    state = state.copyWith(speaker: on);
    await _link?.setSpeaker(on);
  }

  /// Back to idle once the end screens are done.
  void reset() {
    if (!state.inCall && !state.searching) state = const CallState();
  }

  void _onCall(CallInfo? c, {required bool asStudent}) {
    if (c == null) return;
    if (asStudent) {
      if (c.status == CallStatus.active && state.searching) {
        _resolve(CallStatus.active);
        state = state.copyWith(
          phase: CallPhase.connecting,
          otherName: c.teacherName,
          otherAvatar: c.teacherAvatar,
          otherUid: c.teacherId,
        );
        _lastCall = c;
        _connect(c.id, asStudent: true);
      } else if (c.status == CallStatus.declined && state.phase == CallPhase.ringing) {
        _resolve(CallStatus.declined);
      } else if (c.status == CallStatus.active) {
        _lastCall = c;
      }
    }
    if (c.status == CallStatus.ended && state.inCall) _finish();
  }

  CallInfo? _lastCall;

  void _resolve(CallStatus s) {
    final w = _waiting;
    _waiting = null;
    if (w != null && !w.isCompleted) w.complete(s);
  }

  Future<void> _connect(String id, {required bool asStudent}) async {
    final link = _link = ref.read(audioLinkFactoryProvider)();
    link.state.addListener(() {
      if (!state.inCall) return;
      switch (link.state.value) {
        case LinkState.connected:
          state = state.copyWith(phase: CallPhase.active, connectedAt: state.connectedAt ?? DateTime.now());
        case LinkState.reconnecting:
          state = state.copyWith(phase: CallPhase.reconnecting);
        case LinkState.failed:
          _b.setCallStatus(id, CallStatus.ended).catchError((_) {});
          _finish(dropped: true);
        case LinkState.connecting:
          break;
      }
    });
    try {
      await link.start(id, asStudent: asStudent);
    } catch (e) {
      logIssue('Audio failed: $e');
      await _b.setCallStatus(id, CallStatus.ended).catchError((_) {});
      await _finish(dropped: true);
    }
  }

  Future<void> _finish({bool dropped = false}) async {
    if (!state.inCall) return;
    final at = state.connectedAt;
    final secs = at == null ? 0 : DateTime.now().difference(at).inSeconds;
    final teacher = state.asTeacher;
    final call = _lastCall;
    state = state.copyWith(phase: at == null ? CallPhase.failed : CallPhase.ended, seconds: secs, dropped: dropped);
    await _cleanUp();
    if (teacher) await _b.setBusy(false).catchError((_) {});
    if (at != null) {
      ref.read(settingsProvider.notifier).update((x) => x.copyWith(sessions: x.sessions + 1));
      if (call != null && call.teacherId != null) {
        // Saved to both people's history (whoever's phone gets there first).
        await _b
            .recordLesson(
              callId: call.id,
              studentId: call.studentId,
              teacherId: call.teacherId!,
              studentName: call.studentName,
              teacherName: call.teacherName,
              studentAvatar: call.studentAvatar,
              teacherAvatar: call.teacherAvatar,
              gender: ref.read(settingsProvider).gender ?? Gender.female,
              startedAt: at,
              durationSec: secs,
            )
            .catchError((Object e) => logIssue('Lesson not saved: $e'));
      }
      // A first lesson opens the chat between them.
      if (!teacher && call != null) await _b.openChatAfterCall(call).catchError((Object e) => logIssue('$e'));
    }
  }

  Future<void> _stopWatching() async {
    // Not awaited: this can run from inside the call's own update.
    final w = _watch;
    _watch = null;
    unawaited(w?.cancel());
  }

  Future<void> _cleanUp() async {
    _ringTimeout?.cancel();
    await _stopWatching();
    final link = _link;
    _link = null;
    await link?.close();
  }
}

final callControllerProvider = NotifierProvider<CallController, CallState>(CallController.new);
