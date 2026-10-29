part of 'call_screens.dart';

/// 21 · In call (student) and 32 · In call (teacher).
class InCallScreen extends ConsumerStatefulWidget {
  const InCallScreen({super.key, this.asTeacher = false});

  final bool asTeacher;

  @override
  ConsumerState<InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends ConsumerState<InCallScreen> {
  late final Timer _tick;
  Portion? _portion;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    // No dimming or locking while the student recites; and if the call was
    // answered from the lock screen, it stays visible there until it ends.
    Screen.keepOn(true);
    Background.overLockScreen(true);
  }

  @override
  void dispose() {
    _tick.cancel();
    Screen.keepOn(false);
    Background.overLockScreen(false);
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
    // "Open Quran" goes to the student's portion: their own next portion,
    // or (for the teacher) the one from their last lesson together.
    final notes = st.otherUid == null || !widget.asTeacher
        ? null
        : ref.watch(lastNotesForStudentProvider(st.otherUid!))?.notes;
    _portion = widget.asTeacher ? (notes?.next ?? notes?.recited) : ref.watch(nextPortionProvider);
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
                () => context.push(
                  _portion == null ? Routes.mushaf : Routes.mushafAt(sura: _portion!.sura, ayah: _portion!.from),
                ),
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
