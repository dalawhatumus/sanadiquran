import 'package:flutter/foundation.dart';

enum CallPhase {
  idle,

  /// Student: looking for a free teacher.
  finding,

  /// Student: a teacher's phone is ringing (or, for a teacher calling a
  /// student, the student's).
  ringing,

  /// Accepted; the phones are connecting.
  connecting,
  active,
  reconnecting,
  ended,

  /// Student: no teacher was free. Teacher: the student didn't answer.
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
    this.otherUid,
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

  /// The other person (the student, for a teacher; the teacher, for a
  /// student), once known.
  final String? otherUid;

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
    String? otherUid,
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
    otherUid: otherUid ?? this.otherUid,
    connectedAt: connectedAt ?? this.connectedAt,
    muted: muted ?? this.muted,
    speaker: speaker ?? this.speaker,
    seconds: seconds ?? this.seconds,
    dropped: dropped ?? this.dropped,
  );
}
