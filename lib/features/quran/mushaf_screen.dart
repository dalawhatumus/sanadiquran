import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'large_text_view.dart';
import 'mushaf_page.dart';
import 'quran_data.dart';
import 'surah_index_screen.dart';

/// 39 · The mushaf. Mushaf page mode shows the exact Madani 15-line pages
/// (two side by side on wide landscape screens); Large text mode reflows the
/// text in big type. Tap the page to show or hide the bars; long-press an
/// ayah for its actions (40).
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({super.key, this.sura, this.ayah, this.page});

  final int? sura;
  final int? ayah;
  final int? page;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  final _page = ValueNotifier<int>(1);
  final _selected = ValueNotifier<String?>(null);
  Ayah? _selAyah;
  Offset _selAt = Offset.zero;
  bool _chrome = true;
  bool _started = false;
  int _jump = 0;
  PageController? _pc;
  bool? _spreadMode;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    // Bars show on opening, then step aside so the whole page is visible.
    // A tap on the page brings them back.
    _hide = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_chrome) return;
      setState(() => _chrome = false);
      final prefs = ref.read(sharedPreferencesProvider);
      if (prefs.getBool('mushafHint') != true) {
        prefs.setBool('mushafHint', true);
        toast(context, S.of(context).tapToShowBars);
      }
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _pc?.dispose();
    _page.dispose();
    _selected.dispose();
    super.dispose();
  }

  void _start(QuranData q) {
    if (_started) return;
    _started = true;
    final a = widget.sura == null ? null : q.ayah(widget.sura!, widget.ayah ?? 1);
    _page.value = a != null ? q.pageOf(a) : (widget.page ?? ref.read(lastPageProvider));
    if (a != null && widget.ayah != null && widget.ayah! > 1) _selected.value = a.key;
  }

  void _onPage(int p) {
    if (p == _page.value) return;
    _page.value = p;
    ref.read(lastPageProvider.notifier).set(p);
    if (_selAyah != null) _clearSelection();
  }

  void _goTo(int p) {
    _clearSelection();
    _page.value = p;
    ref.read(lastPageProvider.notifier).set(p);
    final spread = _spreadMode ?? false;
    if (_pc != null && _pc!.hasClients) {
      _pc!.jumpToPage(spread ? (p - 1) ~/ 2 : p - 1);
    }
    setState(() => _jump++);
  }

  void _onAyah(Ayah a, Offset at) {
    HapticFeedback.selectionClick();
    _selected.value = a.key;
    setState(() {
      _selAyah = a;
      _selAt = at;
    });
  }

  void _clearSelection() {
    _selected.value = null;
    if (_selAyah != null) setState(() => _selAyah = null);
  }

  void _onTapPage() {
    if (_selAyah != null) {
      _clearSelection();
    } else {
      _hide?.cancel();
      setState(() => _chrome = !_chrome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quran = ref.watch(quranProvider);
    final t = context.t;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? t.bg : const Color(0xFFFFFCF2),
      body: quran.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (q) {
          _start(q);
          return _body(context, q);
        },
      ),
    );
  }

  Widget _body(BuildContext context, QuranData q) {
    final mode = ref.watch(settingsProvider.select((x) => x.mushafMode));
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final spread = mode == MushafMode.page && landscape && size.width >= 840;
    if (_spreadMode != spread) {
      _pc?.dispose();
      _pc = null;
      _spreadMode = spread;
    }

    final Widget content;
    if (mode == MushafMode.large) {
      content = LargeTextView(
        key: ValueKey('large-$_jump'),
        q: q,
        startPage: _page.value,
        selected: _selected,
        onAyah: _onAyah,
        onPage: _onPage,
        onTap: _onTapPage,
      );
    } else {
      _pc ??= PageController(initialPage: spread ? (_page.value - 1) ~/ 2 : _page.value - 1);
      content = Directionality(
        // Mushaf pages always turn right-to-left.
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          controller: _pc,
          itemCount: spread ? QuranData.pageCount ~/ 2 : QuranData.pageCount,
          onPageChanged: (i) => _onPage(spread ? i * 2 + 1 : i + 1),
          itemBuilder: (_, i) {
            Widget page(int p) => MushafPage(
              q: q,
              page: p,
              selected: _selected,
              onAyah: _onAyah,
              onTap: _onTapPage,
              scrollable: landscape && !spread,
            );
            if (!spread) return RepaintBoundary(child: page(i + 1));
            // Right-to-left row: the odd page sits on the right.
            return RepaintBoundary(
              child: Row(
                children: [
                  Expanded(child: page(i * 2 + 1)),
                  Container(width: 1, color: const Color(0x22000000)),
                  Expanded(child: page(i * 2 + 2)),
                ],
              ),
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: SafeArea(bottom: false, child: content)),
        _TopBar(
          visible: _chrome,
          q: q,
          page: _page,
          mode: mode,
          onMode: () {
            ref
                .read(settingsProvider.notifier)
                .update((x) => x.copyWith(mushafMode: mode == MushafMode.page ? MushafMode.large : MushafMode.page));
            _clearSelection();
            setState(() => _jump++);
          },
          onGoTo: () => _showGoTo(context, q),
        ),
        _BottomBar(visible: _chrome && _selAyah == null),
        if (_selAyah != null) _AyahToolbar(ayah: _selAyah!, at: _selAt, q: q, onClose: _clearSelection),
      ],
    );
  }

  void _showGoTo(BuildContext context, QuranData q) {
    final s = S.of(context);
    final c = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        void submit() {
          final p = int.tryParse(c.text.trim());
          if (p != null && p >= 1 && p <= QuranData.pageCount) {
            Navigator.pop(ctx);
            _goTo(p);
          }
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.goToPage, style: Theme.of(ctx).textTheme.headlineSmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: c,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onSubmitted: (_) => submit(),
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ctx.t.text),
                              decoration: InputDecoration(hintText: s.pageNumberHint),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 110,
                            child: BigButton(label: s.go, onPressed: submit),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(s.surahs, style: Theme.of(ctx).textTheme.titleLarge),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: q.suras.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => SurahTile(
                      sura: q.suras[i],
                      onTap: () {
                        Navigator.pop(ctx);
                        _goTo(q.suras[i].page);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(c.dispose);
  }
}

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
            color: const Color(0xD9101C19),
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
                            icon: const Icon(Icons.arrow_back_rounded, color: fg, size: 28),
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
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: fg),
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

/// Listening bar (recitation audio comes with the next update).
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const fg = Colors.white;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: const Color(0xD9101C19),
            child: SafeArea(
              top: false,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: InkWell(
                  onTap: () => showSoon(context),
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.play_arrow_rounded, color: fg, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${s.play} · ${s.reciterName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            s.comingSoonShort,
                            style: const TextStyle(fontSize: 14, color: Color(0xFFDDE8E1)),
                          ),
                        ),
                      ],
                    ),
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

/// 40 · Floating actions above the long-pressed ayah.
class _AyahToolbar extends ConsumerWidget {
  const _AyahToolbar({required this.ayah, required this.at, required this.q, required this.onClose});

  final Ayah ayah;
  final Offset at;
  final QuranData q;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final size = MediaQuery.sizeOf(context);
    final marked = ref.watch(settingsProvider.select((x) => x.bookmarks.contains(ayah.key)));
    const barW = 340.0, barH = 120.0;
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
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFDDE8E1)),
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
                      showSoon(context);
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
