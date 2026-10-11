part of 'mushaf_screen.dart';

// The bars over the mushaf: page title and actions at the top, the recitation player at the bottom, and its settings.

/// Dark translucent bar over the top of the page, like a reading app.
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.visible,
    required this.q,
    required this.page,
    required this.mode,
    required this.onMode,
    required this.onGoTo,
  });

  final bool visible;
  final QuranData q;
  final ValueNotifier<int> page;
  final MushafMode mode;
  final VoidCallback onMode;
  final VoidCallback onGoTo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    const fg = Colors.white;
    final marks = ref.watch(settingsProvider.select((x) => x.pageBookmarks));
    Widget action(IconData icon, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 68,
          height: kMinTap + 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg, size: 26),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xFF101C19),
            child: SafeArea(
              bottom: false,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                  child: ValueListenableBuilder<int>(
                    valueListenable: page,
                    builder: (context, p, _) {
                      final first = q.firstOn(p);
                      final marked = marks.contains(p);
                      return Row(
                        children: [
                          IconButton(
                            tooltip: s.back,
                            onPressed: () => context.pop(),
                            icon: const Icon(Arrows.back, color: fg, size: 28),
                            style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  q.sura(first.sura).name(s.ar),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: nameFont(
                                    context,
                                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg),
                                  ),
                                ),
                                Text(
                                  '${s.page(p)} · ${s.juz(first.juz)}',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFDDE8E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          action(marked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, s.bookmark, () {
                            ref.read(settingsProvider.notifier).togglePageBookmark(p);
                            if (!marked) toast(context, s.bookmarked);
                          }),
                          action(
                            mode == MushafMode.page ? Icons.format_size_rounded : Icons.menu_book_rounded,
                            mode == MushafMode.page ? s.segLarge : s.segPage,
                            onMode,
                          ),
                          action(Icons.list_alt_rounded, s.goTo, onGoTo),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Listening bar: play from this page (or the chosen ayah), pause, stop,
/// and the recitation settings. Shown and hidden with the other bars (a tap
/// on the page), so it never covers the ayahs being read.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.visible, required this.onPlay});

  final bool visible;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    const fg = Colors.white;
    const sub = Color(0xFFDDE8E1);
    final r = ref.watch(recitationProvider);
    final c = ref.read(recitationProvider.notifier);
    final q = ref.watch(quranProvider).value;
    final show = visible;
    Widget iconBtn(IconData icon, String tip, VoidCallback onTap) => IconButton(
      tooltip: tip,
      onPressed: onTap,
      icon: Icon(icon, color: fg, size: 32),
      style: IconButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
    );
    final a = r.ayah;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !show,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xFF101C19),
            child: SafeArea(
              top: false,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: SizedBox(
                  height: 64,
                  child: a == null
                      ? InkWell(
                          onTap: onPlay,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              const Icon(Icons.play_arrow_rounded, color: fg, size: 34),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${s.play} · ${r.reciter.name(s.ar)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg),
                                ),
                              ),
                              iconBtn(Icons.tune_rounded, s.recitationSettings, () => _showSettings(context)),
                              const SizedBox(width: 4),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            const SizedBox(width: 4),
                            r.loading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(strokeWidth: 3, color: fg),
                                    ),
                                  )
                                : iconBtn(
                                    r.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    r.playing ? s.pause : s.play,
                                    c.toggle,
                                  ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q == null ? '' : s.ayahTitle(q.sura(a.sura).name(s.ar), a.ayah),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: nameFont(
                                      context,
                                      const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: fg),
                                    ),
                                  ),
                                  Text(
                                    r.failed
                                        ? s.recitationFailed
                                        : '${r.reciter.name(s.ar)} · ${s.repeatTimes(r.repeat)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sub),
                                  ),
                                ],
                              ),
                            ),
                            iconBtn(Icons.tune_rounded, s.recitationSettings, () => _showSettings(context)),
                            iconBtn(Icons.stop_rounded, s.stop, c.stop),
                            const SizedBox(width: 4),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reciter, repeat and speed.
void _showSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final s = S.of(ctx);
        final tt = Theme.of(ctx).textTheme;
        final r = ref.watch(recitationProvider);
        final c = ref.read(recitationProvider.notifier);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WordSafeText(s.recitationSettings, style: tt.headlineSmall),
                const SizedBox(height: 14),
                WordSafeText(s.repeatL, style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final n in repeatChoices)
                      PickChip(label: s.repeatTimes(n), selected: r.repeat == n, onTap: () => c.setRepeat(n)),
                  ],
                ),
                const SizedBox(height: 16),
                WordSafeText(s.speedL, style: tt.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final v in speedChoices)
                      PickChip(label: s.n('×$v'), selected: r.speed == v, onTap: () => c.setSpeed(v)),
                  ],
                ),
                const SizedBox(height: 16),
                WordSafeText(s.reciterL, style: tt.titleMedium),
                const SizedBox(height: 8),
                for (final rc in reciters) ...[
                  ChoiceCard(title: rc.name(s.ar), selected: r.reciterId == rc.id, onTap: () => c.setReciter(rc.id)),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
