import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../backend/backend.dart';
import '../../backend/calls.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';
import '../quran/quran_data.dart';
import 'call_controller.dart';

String _clock(S s, int secs) =>
    s.n('${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}');

/// The other person's name and picture during a call (sample ones in demo
/// mode, where the call has no real person).
(String, String, String?) _other(S s, CallState st) {
  final teacher = st.asTeacher;
  if (st.otherName.isEmpty) {
    return teacher
        ? (s.studentName, s.studentInitial, sampleStudentAvatar(s.female))
        : (s.teacherName, s.teacherInitials, sampleTeacherAvatar(s.female));
  }
  final n = st.otherName.trim();
  return (n, n.isEmpty ? '?' : n.characters.first.toUpperCase(), st.otherAvatar);
}

/// 19 · Connecting: finding a free teacher of the same gender, then ringing
/// them; or "No teacher is free right now".
class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key, this.teacherId});

  /// A particular teacher to try first ("Call" on My teacher).
  final String? teacherId;

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  CallController get _c => ref.read(callControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    _c.reset();
    _c.startAsStudent(preferredTeacher: widget.teacherId);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final st = ref.read(callControllerProvider);
    if (st.searching) {
      await _c.cancel();
    } else {
      _c.reset();
    }
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final st = ref.watch(callControllerProvider);
    ref.listen(callControllerProvider, (prev, next) {
      if (next.inCall && !(prev?.inCall ?? false)) context.pushReplacement(Routes.inCall);
    });

    if (st.phase == CallPhase.unmatched || st.phase == CallPhase.failed || st.phase == CallPhase.noMic) {
      final (icon, title, body) = switch (st.phase) {
        CallPhase.unmatched => (Icons.hourglass_empty_rounded, s.noTeacherTitle, s.noTeacherBody),
        CallPhase.noMic => (Icons.mic_off_rounded, s.callFailedTitle, s.micNeededCall),
        _ => (Icons.wifi_off_rounded, s.callFailedTitle, s.callFailedBody),
      };
      return StepScaffold(
        center: true,
        content: [
          Center(child: Illustration(size: 112, child: Icon(icon))),
          const SizedBox(height: 18),
          WordSafeText(title, style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: tt.bodyLarge, textAlign: TextAlign.center),
        ],
        bottom: [
          if (st.phase == CallPhase.noMic)
            BigButton(label: s.openSettings, icon: Icons.settings_rounded, onPressed: openAppSettings)
          else
            BigButton(label: s.tryAgain, icon: Icons.refresh_rounded, onPressed: _start),
          BigButton(label: s.back, icon: Arrows.back, kind: ButtonKind.outline, onPressed: _cancel),
        ],
      );
    }

    final ringing = st.phase == CallPhase.ringing;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: StepScaffold(
        center: true,
        content: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
              child: Text(
                s.sessionType,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.tint.withValues(alpha: 1 - _pulse.value * 0.7),
                ),
                child: child,
              ),
              child: Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.primary,
                  border: Border.all(color: t.sage, width: 4),
                ),
                child: Icon(ringing ? Icons.call_rounded : Icons.mic_rounded, size: 60, color: t.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Semantics(
            liveRegion: true,
            child: WordSafeText(
              ringing ? s.callingAny : s.finding,
              style: tt.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(ringing ? s.callingSub : s.findingSub, style: tt.bodyLarge, textAlign: TextAlign.center),
        ],
        bottom: [BigButton(label: s.cancel, icon: Icons.close_rounded, kind: ButtonKind.outline, onPressed: _cancel)],
      ),
    );
  }
}

/// 21 · In call (student) and 32 · In call (teacher).
class InCallScreen extends ConsumerStatefulWidget {
  const InCallScreen({super.key, this.asTeacher = false});

  final bool asTeacher;

  @override
  ConsumerState<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends ConsumerState<InCallScreen> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _end() async {
    final s = S.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.endTitle),
        content: Text(widget.asTeacher ? s.endBodyTeacher : s.endBody),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 10,
        actions: [
          SizedBox(
            width: double.infinity,
            child: BigButton(
              label: s.endYes,
              icon: Icons.call_end_rounded,
              kind: ButtonKind.warn,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: BigButton(
              label: widget.asTeacher ? s.endNoTeacher : s.endNo,
              kind: ButtonKind.outline,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ),
        ],
      ),
    );
    if (yes == true) await ref.read(callControllerProvider.notifier).hangUp();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final st = ref.watch(callControllerProvider);
    final c = ref.read(callControllerProvider.notifier);
    final live = ref.watch(backendProvider).live;
    ref.listen(callControllerProvider, (prev, next) {
      if (next.phase == CallPhase.ended) {
        context.pushReplacement(
          widget.asTeacher ? '${Routes.teacherEnded}?s=${next.seconds}' : '${Routes.studentEnded}?s=${next.seconds}',
        );
      } else if (next.phase == CallPhase.failed && (prev?.inCall ?? false)) {
        toast(context, s.callFailedTitle);
        c.reset();
        context.go(widget.asTeacher ? Routes.teacherHome : Routes.studentHome);
      }
    });
    final (name, initials, avatar) = _other(s, st);
    final secs = st.connectedAt == null ? 0 : DateTime.now().difference(st.connectedAt!).inSeconds;
    final (statusIcon, statusText, statusColor) = switch (st.phase) {
      CallPhase.active => (SIcons.bars3, s.goodConn, t.primary),
      CallPhase.reconnecting => (SIcons.bars1, s.reconnecting, t.warn),
      _ => (SIcons.bars0, s.connectingCall, t.muted),
    };

    Widget control(IconData icon, String label, bool active, VoidCallback onTap, {Widget? iconWidget}) => Expanded(
      child: Semantics(
        button: true,
        toggled: active,
        child: Material(
          color: active ? t.tint : t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.text, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget ?? Icon(icon, size: 32, color: t.text),
                    const SizedBox(height: 6),
                    WordSafeText(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text, height: 1.15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _end();
      },
      child: StepScaffold(
        center: true,
        content: [
          if (st.muted) ...[
            WarnBanner(icon: Icons.mic_off_rounded, text: widget.asTeacher ? s.mutedBannerTeacher : s.mutedBanner),
            const SizedBox(height: 20),
          ],
          Text(
            s.inSession,
            style: tt.bodyLarge!.copyWith(color: t.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Center(child: Avatar(initials, size: 112, image: avatar)),
          const SizedBox(height: 14),
          WordSafeText(name, style: tt.headlineMedium, textAlign: TextAlign.center),
          if (!live) ...[
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_rounded, size: 20, color: t.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s.firstPortion,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: t.heading),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _clock(s, secs),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: t.heading,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SIcon(statusIcon, size: 22, color: statusColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          if (!live) ...[
            const SizedBox(height: 16),
            Text(s.testCall, style: tt.bodySmall, textAlign: TextAlign.center),
          ],
        ],
        bottom: [
          Row(
            children: [
              control(
                st.muted ? Icons.mic_rounded : Icons.mic_off_rounded,
                st.muted ? s.unmute : s.mute,
                st.muted,
                c.toggleMute,
              ),
              const SizedBox(width: 10),
              control(Icons.volume_up_rounded, s.speaker, st.speaker, c.toggleSpeaker),
              const SizedBox(width: 10),
              control(
                Icons.menu_book_rounded,
                s.openQuran,
                false,
                () => context.push(Routes.mushaf),
                iconWidget: SIcon(SIcons.rehal, size: 32, color: t.text),
              ),
            ],
          ),
          BigButton(label: s.endCall, icon: Icons.call_end_rounded, kind: ButtonKind.warn, onPressed: _end),
        ],
      ),
    );
  }
}

/// 24 · Call ended (student), with an optional rating.
class StudentCallEndedScreen extends ConsumerStatefulWidget {
  const StudentCallEndedScreen({super.key, required this.seconds});

  final int seconds;

  @override
  ConsumerState<StudentCallEndedScreen> createState() => _StudentCallEndedScreenState();
}

class _StudentCallEndedScreenState extends ConsumerState<StudentCallEndedScreen> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    const faces = [Icons.sentiment_dissatisfied_rounded, Icons.sentiment_neutral_rounded, Icons.check_circle_rounded];
    final minutes = (widget.seconds / 60).ceil().clamp(1, 999);
    final (name, _, _) = _other(s, ref.watch(callControllerProvider));
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 112, child: Icon(Icons.check_rounded))),
        const SizedBox(height: 18),
        WordSafeText(s.sEndTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.sEndSubName(minutes, name), style: tt.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 20, color: t.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.savedToProgress,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        SCard(
          child: Column(
            children: [
              Text(_rating == null ? s.rateQ : s.thanks, style: tt.titleSmall, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        selected: _rating == i,
                        button: true,
                        child: Material(
                          color: _rating == i ? t.primary : t.bg,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _rating = i),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 88),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(faces[i], size: 34, color: _rating == i ? t.onPrimary : t.primary),
                                  const SizedBox(height: 4),
                                  WordSafeText(
                                    s.faces[i],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _rating == i ? t.onPrimary : t.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
      bottom: [
        BigButton(
          label: s.done,
          icon: Icons.check_rounded,
          onPressed: () {
            ref.read(callControllerProvider.notifier).reset();
            context.go(Routes.studentHome);
          },
        ),
        LinkButton(label: s.reportProblem, onPressed: () => showSoon(context)),
      ],
    );
  }
}

/// 31 · Incoming call (teacher). Tap buttons, never swipe; auto-declines at
/// 30 seconds. With no [callId] (demo mode) it's a practice call.
class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key, this.callId});

  final String? callId;

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  late final Timer _timer;
  int _left = 30;
  bool _missed = false;
  bool _answering = false;
  CallInfo? _call;
  StreamSubscription<CallInfo?>? _sub;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    final id = widget.callId;
    if (id != null) {
      _sub = ref.read(backendProvider).watchCall(id).listen((c) {
        if (!mounted || _answering) return;
        setState(() => _call = c);
        // The student hung up, or was put through to someone else.
        if (c != null && c.status != CallStatus.ringing) _stop(missed: true);
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      setState(() => _left--);
      if (_left <= 0) {
        final c = _call;
        if (c != null) ref.read(callControllerProvider.notifier).decline(c);
        _stop(missed: true);
      }
    });
  }

  void _stop({bool missed = false}) {
    _timer.cancel();
    _sub?.cancel();
    if (mounted && missed) setState(() => _missed = true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _sub?.cancel();
    super.dispose();
  }

  CallInfo _demoCall(S s) => CallInfo(
    id: 'demo-incoming',
    studentId: 'demo-student',
    studentName: s.studentName,
    studentAvatar: sampleStudentAvatar(s.female),
    status: CallStatus.ringing,
  );

  Future<void> _accept() async {
    final s = S.of(context);
    final call = widget.callId == null ? _demoCall(s) : _call;
    if (call == null) return;
    _answering = true;
    _stop();
    final c = ref.read(callControllerProvider.notifier)..reset();
    unawaited(c.accept(call));
    if (mounted) context.pushReplacement('${Routes.inCall}?teacher=1');
  }

  Future<void> _decline() async {
    _stop();
    final c = _call;
    if (c != null) await ref.read(callControllerProvider.notifier).decline(c);
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final demo = widget.callId == null;
    final name = demo ? s.studentName : (_call?.studentName ?? '');
    final avatar = demo ? sampleStudentAvatar(s.female) : _call?.studentAvatar;
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();

    if (_missed) {
      return StepScaffold(
        center: true,
        content: [
          const Center(child: Illustration(size: 112, child: Icon(Icons.schedule_rounded))),
          const SizedBox(height: 18),
          WordSafeText(s.missedTitle, style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(demo ? s.missedBody : s.missedBodyName(name), style: tt.bodyLarge, textAlign: TextAlign.center),
        ],
        bottom: [
          BigButton(label: s.ok, onPressed: () => context.canPop() ? context.pop() : context.go(Routes.teacherHome)),
        ],
      );
    }

    Widget big(String label, IconData icon, Color bg, Color fg, VoidCallback onTap) => Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 128),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: fg),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: fg),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _decline();
      },
      child: StepScaffold(
        center: true,
        content: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.call_received_rounded, color: t.text),
              const SizedBox(width: 8),
              Flexible(child: WordSafeText(s.incoming, style: tt.titleMedium)),
            ],
          ),
          const SizedBox(height: 36),
          Center(child: Avatar(initial, size: 120, image: avatar)),
          const SizedBox(height: 18),
          WordSafeText(name, style: tt.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
              child: Text(
                s.sessionType,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
              ),
            ),
          ),
          if (demo) ...[
            const SizedBox(height: 16),
            SCard(
              child: Row(
                children: [
                  Icon(Icons.bookmark_rounded, color: t.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.lastPortionL, style: tt.bodySmall),
                        Text(s.lastPortion, style: tt.titleSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            '${s.answerWithin} · ${s.n(_left.clamp(0, 30))}',
            style: tt.bodyMedium!.copyWith(color: t.muted),
            textAlign: TextAlign.center,
          ),
        ],
        bottom: [
          Row(
            children: [
              big(s.decline, Icons.call_end_rounded, t.warn, t.onWarn, _decline),
              const SizedBox(width: 14),
              big(s.accept, Icons.call_rounded, t.primary, t.onPrimary, _accept),
            ],
          ),
        ],
      ),
    );
  }
}

/// 34 · Call ended (teacher): Done, with optional notes.
class TeacherCallEndedScreen extends ConsumerWidget {
  const TeacherCallEndedScreen({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final minutes = (seconds / 60).ceil().clamp(1, 999);
    final (name, _, _) = _other(s, ref.watch(callControllerProvider));
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 112, child: Icon(Icons.check_rounded))),
        const SizedBox(height: 18),
        WordSafeText(s.tEndTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.tEndSubName(minutes, name), style: tt.bodyLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
            child: Text(
              s.tEndSaved,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.heading),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(s.jazakTeach, style: tt.bodyMedium, textAlign: TextAlign.center),
      ],
      bottom: [
        BigButton(
          label: s.done,
          icon: Icons.check_rounded,
          onPressed: () {
            ref.read(callControllerProvider.notifier).reset();
            context.go(Routes.teacherHome);
          },
        ),
        BigButton(
          label: s.addNotes,
          icon: Icons.edit_note_rounded,
          kind: ButtonKind.outline,
          onPressed: () => context.push(Routes.notesForm),
        ),
        LinkButton(label: s.reportProblem, onPressed: () => showSoon(context)),
      ],
    );
  }
}

/// 34 · Optional notes form. Everything is optional; Save is always on.
class NotesFormScreen extends ConsumerStatefulWidget {
  const NotesFormScreen({super.key});

  @override
  ConsumerState<NotesFormScreen> createState() => _NotesFormScreenState();
}

class _NotesFormScreenState extends ConsumerState<NotesFormScreen> {
  int _from = 1;
  int _to = 10;
  int? _grade;
  final _practise = <int>{};
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final s = S.of(context);
    context.go(Routes.teacherHome);
    toast(context, s.notesSaved);
  }

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    final s = S.of(context);
    final t = context.t;
    Widget btn(IconData icon, int delta) => IconButton.filledTonal(
      onPressed: () => onChanged((value + delta).clamp(1, 30)),
      icon: Icon(icon, size: 28),
      style: IconButton.styleFrom(
        minimumSize: const Size(kMinTap, kMinTap),
        backgroundColor: t.tint,
        foregroundColor: t.primary,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            btn(Icons.remove_rounded, -1),
            Expanded(
              child: Text(
                s.n(value),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: t.heading),
              ),
            ),
            btn(Icons.add_rounded, 1),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    final from = _stepper(s.fromAyah, _from, (v) => setState(() => _from = v.clamp(1, _to)));
    final to = _stepper(s.toAyah, _to, (v) => setState(() => _to = v.clamp(_from, 30)));

    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.notesTitle, style: tt.headlineSmall),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_rounded, color: t.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(s.allOptional, style: tt.bodyMedium)),
          ],
        ),
        const SizedBox(height: 18),
        WordSafeText(s.portionL, style: tt.titleMedium),
        const SizedBox(height: 8),
        SCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.surahMulk, style: tt.titleSmall!.copyWith(color: t.heading)),
              const SizedBox(height: 10),
              from,
              const SizedBox(height: 12),
              to,
            ],
          ),
        ),
        const SizedBox(height: 18),
        WordSafeText(s.gradeL, style: tt.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < 3; i++)
              PickChip(
                label: s.grades[i],
                selected: _grade == i,
                onTap: () => setState(() => _grade = _grade == i ? null : i),
              ),
          ],
        ),
        const SizedBox(height: 18),
        WordSafeText(s.mistakesL, style: tt.titleMedium),
        const SizedBox(height: 8),
        if (q != null)
          for (var a = _from; a <= _to; a++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SCard(
                color: _practise.contains(a) ? t.tint : t.surface,
                border: _practise.contains(a) ? t.primary : null,
                onTap: () => setState(() => _practise.contains(a) ? _practise.remove(a) : _practise.add(a)),
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _practise.contains(a) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: _practise.contains(a) ? t.primary : t.muted,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        q.ayah(67, a)!.text,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: 22, color: t.text, height: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 10),
        WordSafeText(s.nextL, style: tt.titleMedium),
        const SizedBox(height: 8),
        SCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WordSafeText(s.nextPortion, style: tt.titleLarge),
              Text(s.suggested, style: tt.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 18),
        WordSafeText(s.noteTo, style: tt.titleMedium),
        const SizedBox(height: 8),
        TextField(
          minLines: 3,
          maxLines: 6,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: t.text),
          decoration: InputDecoration(hintText: s.typeNote),
        ),
      ],
      bottom: [
        BigButton(label: s.saveNotes, icon: Icons.check_rounded, busy: _saving, onPressed: _save),
        BigButton(label: s.cancel, kind: ButtonKind.outline, onPressed: () => context.pop()),
      ],
    );
  }
}
