import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../backend/backend.dart';
import '../../backend/calls.dart';
import '../../core/settings.dart';
import 'audio_link.dart';

enum CallPhase {
  idle,

  /// Student: looking for a free teacher.
  finding,

  /// Student: a teacher's phone is ringing.
  ringing,

  /// Accepted; the phones are connecting.
  connecting,
  active,
  reconnecting,
  ended,

  /// Student: no teacher was free.
  unmatched,

  /// The call couldn't connect, or was cut off.
  failed,

  /// The microphone permission was refused.
  noMic,
}

@immutable
class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.asTeacher = false,
    this.otherName = '',
    this.otherAvatar,
    this.connectedAt,
    this.muted = false,
    this.speaker = true,
    this.seconds = 0,
    this.dropped = false,
  });

  final CallPhase phase;
  final String? callId;
  final bool asTeacher;
  final String otherName;
  final String? otherAvatar;

  /// When the audio first connected (the session time counts from here).
  final DateTime? connectedAt;
  final bool muted;
  final bool speaker;

  /// Length of the finished call.
  final int seconds;

  /// The line broke rather than someone hanging up.
  final bool dropped;

  bool get inCall => phase == CallPhase.connecting || phase == CallPhase.active || phase == CallPhase.reconnecting;
  bool get searching => phase == CallPhase.finding || phase == CallPhase.ringing;

  CallState copyWith({
    CallPhase? phase,
    String? callId,
    String? otherName,
    String? otherAvatar,
    DateTime? connectedAt,
    bool? muted,
    bool? speaker,
    int? seconds,
    bool? dropped,
  }) => CallState(
    phase: phase ?? this.phase,
    callId: callId ?? this.callId,
    asTeacher: asTeacher,
    otherName: otherName ?? this.otherName,
    otherAvatar: otherAvatar ?? this.otherAvatar,
    connectedAt: connectedAt ?? this.connectedAt,
    muted: muted ?? this.muted,
    speaker: speaker ?? this.speaker,
    seconds: seconds ?? this.seconds,
    dropped: dropped ?? this.dropped,
  );
}

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
    final gender = me.gender ?? Gender.female;
    final String id;
    try {
      id = await _b.createCall(name: me.name.trim(), avatar: me.avatar, gender: gender);
    } catch (e) {
      debugPrint('Call not created: $e');
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
      final pick = free.where((c) => c.uid == preferredTeacher).firstOrNull ?? free.first;
      tried.add(pick.uid);
      final waiter = _waiting = Completer<CallStatus>();
      try {
        await _b.ring(id, pick.uid);
      } catch (e) {
        debugPrint('Ring failed: $e');
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

  /// Student: stops looking (before anyone answers).
  Future<void> cancel() async {
    _cancelled = true;
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
    );
    if (!await ref.read(micPermissionProvider)()) {
      await decline(call);
      state = const CallState(phase: CallPhase.noMic, asTeacher: true);
      return;
    }
    final me = ref.read(settingsProvider);
    try {
      await _b.setBusy(true);
      await _b.acceptCall(call.id, name: me.name.trim(), avatar: me.avatar);
    } catch (e) {
      debugPrint('Accept failed: $e');
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
        state = state.copyWith(phase: CallPhase.connecting, otherName: c.teacherName, otherAvatar: c.teacherAvatar);
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
      debugPrint('Audio failed: $e');
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
      // A first lesson opens the chat between them.
      if (!teacher && call != null) await _b.openChatAfterCall(call).catchError((Object e) => debugPrint('$e'));
    }
  }

  Future<void> _stopWatching() async {
    // Not awaited: this can run from inside the call's own update.
    final w = _watch;
    _watch = null;
    unawaited(w?.cancel());
  }

  Future<void> _cleanUp() async {
    await _stopWatching();
    final link = _link;
    _link = null;
    await link?.close();
  }
}

final callControllerProvider = NotifierProvider<CallController, CallState>(CallController.new);
