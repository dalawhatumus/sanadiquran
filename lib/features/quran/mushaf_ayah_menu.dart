part of 'mushaf_screen.dart';

// An ayah's actions after a long-press.

/// 40 · Floating actions above the long-pressed ayah.
class _AyahToolbar extends ConsumerWidget {
  const _AyahToolbar({
    required this.ayah,
    required this.at,
    required this.q,
    required this.onClose,
    required this.onPlay,
  });

  final Ayah ayah;
  final ValueChanged<Ayah> onPlay;
  final Offset at;
  final QuranData q;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final size = MediaQuery.sizeOf(context);
    final marked = ref.watch(settingsProvider.select((x) => x.bookmarks.contains(ayah.key)));
    final student = ref.watch(settingsProvider.select((x) => x.role == UserRole.student));
    final barW = (size.width - 16).clamp(0.0, 360.0);
    const barH = 120.0;
    final left = (at.dx - barW / 2).clamp(8.0, size.width - barW - 8);
    var top = at.dy - barH - 28;
    if (top < MediaQuery.paddingOf(context).top + 8) top = at.dy + 36;

    Widget item(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      width: barW,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Material(
          color: SanadiTokens.light.primary,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.ayahTitle(q.sura(ayah.sura).name(s.ar), ayah.ayah),
                  style: nameFont(
                    context,
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFDDE8E1)),
                  ),
                ),
                Row(
                  children: [
                    item(marked ? Icons.bookmark_rounded : Icons.bookmark_add_rounded, s.bookmark, () {
                      ref.read(settingsProvider.notifier).toggleBookmark(ayah.sura, ayah.ayah);
                      if (!marked) toast(context, s.bookmarked);
                      onClose();
                    }),
                    item(Icons.content_copy_rounded, s.copy, () {
                      Clipboard.setData(
                        ClipboardData(
                          text: '${ayah.plain}\n[${q.sura(ayah.sura).name(s.ar)} ${ayah.sura}:${ayah.ayah}]',
                        ),
                      );
                      toast(context, s.copied);
                      onClose();
                    }),
                    item(Icons.play_arrow_rounded, s.play, () {
                      onPlay(ayah);
                      onClose();
                    }),
                    if (student)
                      item(Icons.flag_rounded, s.setNextShort, () {
                        final count = q.sura(ayah.sura).count;
                        final to = ayah.ayah + 9 > count ? count : ayah.ayah + 9;
                        ref.read(ownNextPortionProvider.notifier).set(Portion(ayah.sura, ayah.ayah, to));
                        toast(context, s.nextPortionSet);
                        onClose();
                      }),
                    item(Icons.close_rounded, s.close, onClose),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
