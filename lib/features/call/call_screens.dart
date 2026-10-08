import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/avatars.dart';
import '../../widgets/ui.dart';
import '../quran/quran_data.dart';

// Test build: calls are simulated. Real audio calls (WebRTC) come next.

String _clock(S s, int secs) =>
    s.n('${(secs ~/ 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}');

/// 19 · Connecting: finding a teacher, then calling them.
class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({super.key});

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  int _stage = 0;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _timers.add(Timer(const Duration(milliseconds: 2200), () => setState(() => _stage = 1)));
    _timers.add(
      Timer(const Duration(milliseconds: 4400), () {
        if (mounted) context.pushReplacement(Routes.inCall);
      }),
    );
  }

  @override
  void dispose() {
    for (final tm in _timers) {
      tm.cancel();
    }
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final ringing = _stage == 1;
    return StepScaffold(
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
              child: ringing
                  ? Text(
                      s.teacherInitials,
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: t.onPrimary, height: 1),
                    )
                  : Icon(Icons.mic_rounded, size: 60, color: t.onPrimary),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Semantics(
          liveRegion: true,
          child: WordSafeText(ringing ? s.calling : s.finding, style: tt.headlineSmall, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Text(ringing ? s.callingSub : s.findingSub, style: tt.bodyLarge, textAlign: TextAlign.center),
      ],
      bottom: [
        BigButton(label: s.cancel, icon: Icons.close_rounded, kind: ButtonKind.outline, onPressed: () => context.pop()),
      ],
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
  late final Timer _timer;
  int _secs = 0;
  bool _muted = false;
  bool _speaker = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _secs++));
  }

  @override
  void dispose() {
    _timer.cancel();
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
    if (yes != true || !mounted) return;
    ref.read(settingsProvider.notifier).update((x) => x.copyWith(sessions: x.sessions + 1));
    context.pushReplacement(widget.asTeacher ? '${Routes.teacherEnded}?s=$_secs' : '${Routes.studentEnded}?s=$_secs');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final name = widget.asTeacher ? s.studentName : s.teacherName;
    final initials = widget.asTeacher ? s.studentInitial : s.teacherInitials;

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
          if (_muted) ...[
            WarnBanner(icon: Icons.mic_off_rounded, text: widget.asTeacher ? s.mutedBannerTeacher : s.mutedBanner),
            const SizedBox(height: 20),
          ],
          Text(
            s.inSession,
            style: tt.bodyLarge!.copyWith(color: t.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Center(
            child: Avatar(
              initials,
              size: 112,
              image: widget.asTeacher ? sampleStudentAvatar(s.female) : sampleTeacherAvatar(s.female),
            ),
          ),
          const SizedBox(height: 14),
          WordSafeText(name, style: tt.headlineMedium, textAlign: TextAlign.center),
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
          const SizedBox(height: 10),
          Text(
            _clock(s, _secs),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: t.heading,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SIcon(SIcons.bars3, size: 22, color: t.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s.goodConn,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(s.testCall, style: tt.bodySmall, textAlign: TextAlign.center),
        ],
        bottom: [
          Row(
            children: [
              control(
                _muted ? Icons.mic_rounded : Icons.mic_off_rounded,
                _muted ? s.unmute : s.mute,
                _muted,
                () => setState(() => _muted = !_muted),
              ),
              const SizedBox(width: 10),
              control(Icons.volume_up_rounded, s.speaker, _speaker, () => setState(() => _speaker = !_speaker)),
              const SizedBox(width: 10),
              control(
                Icons.menu_book_rounded,
                s.openQuran,
                false,
                () => context.push(Routes.mushafAt(sura: 67, ayah: 1)),
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
class StudentCallEndedScreen extends StatefulWidget {
  const StudentCallEndedScreen({super.key, required this.seconds});

  final int seconds;

  @override
  State<StudentCallEndedScreen> createState() => _StudentCallEndedScreenState();
}

class _StudentCallEndedScreenState extends State<StudentCallEndedScreen> {
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    const faces = [Icons.sentiment_dissatisfied_rounded, Icons.sentiment_neutral_rounded, Icons.check_circle_rounded];
    final minutes = (widget.seconds / 60).ceil().clamp(1, 999);
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 112, child: Icon(Icons.check_rounded))),
        const SizedBox(height: 18),
        WordSafeText(s.sEndTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.sEndSub(minutes), style: tt.bodyLarge, textAlign: TextAlign.center),
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
        BigButton(label: s.done, icon: Icons.check_rounded, onPressed: () => context.go(Routes.studentHome)),
        LinkButton(label: s.reportProblem, onPressed: () => showSoon(context)),
      ],
    );
  }
}

/// 31 · Incoming call (teacher). Tap buttons, never swipe; auto-declines at 30s.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late final Timer _timer;
  int _left = 30;
  bool _missed = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      setState(() => _left--);
      if (_left <= 0) {
        tm.cancel();
        setState(() => _missed = true);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;

    if (_missed) {
      return StepScaffold(
        center: true,
        content: [
          const Center(child: Illustration(size: 112, child: Icon(Icons.schedule_rounded))),
          const SizedBox(height: 18),
          WordSafeText(s.missedTitle, style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(s.missedBody, style: tt.bodyLarge, textAlign: TextAlign.center),
        ],
        bottom: [BigButton(label: s.ok, onPressed: () => context.pop())],
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

    return StepScaffold(
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
        Center(child: Avatar(s.studentInitial, size: 120, image: sampleStudentAvatar(s.female))),
        const SizedBox(height: 18),
        WordSafeText(s.studentName, style: tt.headlineMedium, textAlign: TextAlign.center),
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
        const SizedBox(height: 12),
        Text(
          '${s.answerWithin} · ${s.n(_left)}',
          style: tt.bodyMedium!.copyWith(color: t.muted),
          textAlign: TextAlign.center,
        ),
      ],
      bottom: [
        Row(
          children: [
            big(s.decline, Icons.call_end_rounded, t.warn, t.onWarn, () => context.pop()),
            const SizedBox(width: 14),
            big(
              s.accept,
              Icons.call_rounded,
              t.primary,
              t.onPrimary,
              () => context.pushReplacement('${Routes.inCall}?teacher=1'),
            ),
          ],
        ),
      ],
    );
  }
}

/// 34 · Call ended (teacher): Done, with optional notes.
class TeacherCallEndedScreen extends StatelessWidget {
  const TeacherCallEndedScreen({super.key, required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final minutes = (seconds / 60).ceil().clamp(1, 999);
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 112, child: Icon(Icons.check_rounded))),
        const SizedBox(height: 18),
        WordSafeText(s.tEndTitle, style: tt.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s.tEndSub(minutes), style: tt.bodyLarge, textAlign: TextAlign.center),
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
        BigButton(label: s.done, icon: Icons.check_rounded, onPressed: () => context.go(Routes.teacherHome)),
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
