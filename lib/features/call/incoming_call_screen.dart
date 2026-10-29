part of 'call_screens.dart';

/// 31 · Incoming call: a student calling a teacher, or a teacher calling
/// their student. Tap buttons, never swipe; auto-declines at 30 seconds.
/// With no [callId] (demo mode) it's a practice call from a student.
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
        if (c != null) {
          final calls = ref.read(callControllerProvider.notifier);
          c.fromTeacher ? calls.declineFromTeacher(c) : calls.decline(c);
        }
        _stop(missed: true);
      }
    });
  }

  /// A teacher calling this student (rather than a student calling).
  bool get _fromTeacher => _call?.fromTeacher ?? false;

  void _stop({bool missed = false}) {
    _timer.cancel();
    _sub?.cancel();
    unawaited(Reminders.instance.cancelIncomingCall());
    if (missed && !_missed && widget.callId != null) {
      // Only teachers go "away" after missing calls.
      if (!_fromTeacher) ref.read(autoAwayProvider.notifier).missed();
      // Not looking at the phone: leave a "missed call" notification.
      if (mounted && WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        final s = S.of(context);
        unawaited(
          _fromTeacher
              ? Reminders.instance.missedTeacherCall(s: s, teacherName: _call?.teacherName ?? '')
              : Reminders.instance.missedCall(s: s, studentName: _call?.studentName ?? ''),
        );
      }
    }
    if (mounted && missed) setState(() => _missed = true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _sub?.cancel();
    unawaited(Reminders.instance.cancelIncomingCall());
    // Answered: the call screen keeps it over the lock screen instead.
    if (!_answering) Background.overLockScreen(false);
    super.dispose();
  }

  CallInfo _demoCall(S s) => CallInfo(
    id: 'demo-incoming',
    studentId: 'demo',
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
    if (call.fromTeacher) {
      unawaited(c.acceptFromTeacher(call));
      if (mounted) context.pushReplacement(Routes.inCall);
      return;
    }
    ref.read(autoAwayProvider.notifier).responded();
    unawaited(c.accept(call));
    if (mounted) context.pushReplacement('${Routes.inCall}?teacher=1');
  }

  Future<void> _decline() async {
    _stop();
    final c = _call;
    final calls = ref.read(callControllerProvider.notifier);
    if (c != null && c.fromTeacher) {
      await calls.declineFromTeacher(c);
    } else {
      ref.read(autoAwayProvider.notifier).responded();
      if (c != null) await calls.decline(c);
    }
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final demo = widget.callId == null;
    final fromTeacher = _fromTeacher;
    final name = demo ? s.studentName : ((fromTeacher ? _call?.teacherName : _call?.studentName) ?? '');
    final avatar = demo ? sampleStudentAvatar(s.female) : (fromTeacher ? _call?.teacherAvatar : _call?.studentAvatar);
    final initial = name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
    // What this student recited with this teacher last time (if anything).
    final studentId = fromTeacher ? null : _call?.studentId;
    final notes = studentId == null ? null : ref.watch(lastNotesForStudentProvider(studentId))?.notes;
    final recited = notes?.recited ?? notes?.next;
    final String? lastPortion = demo
        ? s.lastPortion
        : recited == null
        ? null
        : [
            portionText(s, ref.watch(quranProvider).value, recited),
            if (notes?.grade != null) s.grades[notes!.grade!.clamp(0, 2)],
          ].join(' · ');

    if (_missed) {
      return StepScaffold(
        center: true,
        content: [
          const Center(child: Illustration(size: 112, child: Icon(Icons.schedule_rounded))),
          const SizedBox(height: 18),
          WordSafeText(s.missedTitle, style: tt.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            demo
                ? s.missedBody
                : fromTeacher
                ? s.missedFromName(name)
                : s.missedBodyName(name),
            style: tt.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
        bottom: [
          BigButton(
            label: s.ok,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(fromTeacher ? Routes.studentHome : Routes.teacherHome),
          ),
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
          // A sample lesson type (demo only; real calls have no type).
          if (demo) const SizedBox(height: 10),
          if (demo)
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
          if (lastPortion != null) ...[
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
                        Text(lastPortion, style: nameFont(context, tt.titleSmall!)),
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
