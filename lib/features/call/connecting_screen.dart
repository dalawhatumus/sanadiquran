part of 'call_screens.dart';

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
