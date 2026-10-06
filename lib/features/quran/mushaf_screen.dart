import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'quran_data.dart';
import 'surah_index_screen.dart';

/// 39 · Mushaf with two modes: Large text (default, reflowing, with page
/// dividers) and Mushaf page (one page at a time, swipe right-to-left).
/// 40 · Long-press an ayah for the ayah menu.
class MushafScreen extends ConsumerStatefulWidget {
  const MushafScreen({super.key, this.sura, this.ayah, this.page});

  final int? sura;
  final int? ayah;
  final int? page;

  @override
  ConsumerState<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends ConsumerState<MushafScreen> {
  int? _page;
  int _jump = 0;
  String? _selected;
  PageController? _pc;

  @override
  void dispose() {
    _pc?.dispose();
    super.dispose();
  }

  int _startPage(QuranData q) {
    if (widget.sura != null) return q.ayah(widget.sura!, widget.ayah ?? 1)?.page ?? 1;
    return widget.page ?? ref.read(settingsProvider).lastPage;
  }

  void _setPage(int p) {
    if (p == _page) return;
    setState(() => _page = p);
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(lastPage: p));
  }

  void _goTo(int p) {
    setState(() {
      _page = p;
      _jump++;
    });
    _pc?.jumpToPage(p - 1);
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(lastPage: p));
  }

  void _onAyah(Ayah a) async {
    setState(() => _selected = '${a.sura}:${a.ayah}');
    await showAyahMenu(context, ref, a);
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final quran = ref.watch(quranProvider);
    return Scaffold(
      body: SafeArea(
        child: quran.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (q) {
            _page ??= _startPage(q);
            return _body(context, q);
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, QuranData q) {
    final s = S.of(context);
    final t = context.t;
    final mode = ref.watch(settingsProvider.select((x) => x.mushafMode));
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final page = _page!;
    final first = q.page(page).first;
    final sura = q.sura(first.sura);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sura.name(s.ar),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.heading),
        ),
        Text(
          s.juzPage(first.juz, page),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
        ),
      ],
    );
    final toggle = _ModeSwitch(
      mode: mode,
      onChanged: (m) {
        ref.read(settingsProvider.notifier).update((x) => x.copyWith(mushafMode: m));
        _pc?.dispose();
        _pc = null;
        setState(() => _jump++);
      },
    );
    final bar = _BottomBar(
      onPlay: () => showSoon(context),
      bookmarked: ref.watch(settingsProvider).bookmarks.contains('${first.sura}:${first.ayah}'),
      onBookmark: () {
        ref.read(settingsProvider.notifier).toggleBookmark(first.sura, first.ayah);
        toast(context, s.bookmarked);
      },
      onGoTo: () => _showGoTo(context, q),
      inline: landscape,
    );

    final content = mode == MushafMode.large ? _largeText(q, page) : _pages(q, page, landscape);

    if (landscape) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                const BackPill(),
                const SizedBox(width: 10),
                Expanded(child: toggle),
                const SizedBox(width: 10),
                title,
                const SizedBox(width: 6),
                bar,
              ],
            ),
          ),
          Divider(height: 1, color: t.line),
          Expanded(child: content),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const BackPill(),
              const SizedBox(width: 12),
              Expanded(
                child: Align(alignment: AlignmentDirectional.centerEnd, child: title),
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: toggle),
        Divider(height: 1, color: t.line),
        Expanded(child: content),
        Divider(height: 1, color: t.line),
        bar,
      ],
    );
  }

  Widget _largeText(QuranData q, int page) {
    final centerKey = ValueKey('center-$page-$_jump');
    return _PageTracker(
      key: ValueKey('tracker-$_jump'),
      onPage: _setPage,
      child: CustomScrollView(
        center: centerKey,
        slivers: [
          SliverList.builder(
            itemCount: page - 1,
            itemBuilder: (_, i) => _LargePage(q: q, page: page - 1 - i, selected: _selected, onAyah: _onAyah),
          ),
          SliverList.builder(
            key: centerKey,
            itemCount: QuranData.pageCount - page + 1,
            itemBuilder: (_, i) => _LargePage(q: q, page: page + i, selected: _selected, onAyah: _onAyah),
          ),
        ],
      ),
    );
  }

  Widget _pages(QuranData q, int page, bool landscape) {
    _pc ??= PageController(initialPage: page - 1);
    return Directionality(
      // Mushaf pages always turn right-to-left.
      textDirection: TextDirection.rtl,
      child: PageView.builder(
        controller: _pc,
        itemCount: QuranData.pageCount,
        onPageChanged: (i) => _setPage(i + 1),
        itemBuilder: (_, i) => _MushafPage(q: q, page: i + 1, selected: _selected, onAyah: _onAyah, scroll: landscape),
      ),
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
                      if (ref.read(settingsProvider).bookmarks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: LinkButton(
                            label: s.bookmarks,
                            icon: Icons.bookmark_rounded,
                            onPressed: () {
                              Navigator.pop(ctx);
                              showBookmarks(context, ref, q, onOpen: (a) => _goTo(a.page));
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
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

/// "Large text | Mushaf page" switch; icon then label on one line.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final MushafMode mode;
  final ValueChanged<MushafMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    Widget seg(MushafMode m, IconData icon, String label) {
      final on = mode == m;
      return Expanded(
        child: Semantics(
          selected: on,
          button: true,
          child: Material(
            color: on ? t.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(m),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTap),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: on ? t.onPrimary : t.text),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: on ? t.onPrimary : t.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            seg(MushafMode.large, Icons.format_size_rounded, s.segLarge),
            seg(MushafMode.page, Icons.menu_book_rounded, s.segPage),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onPlay,
    required this.onBookmark,
    required this.onGoTo,
    required this.bookmarked,
    this.inline = false,
  });

  /// Sits in the landscape header row instead of along the bottom.
  final bool inline;

  final VoidCallback onPlay;
  final VoidCallback onBookmark;
  final VoidCallback onGoTo;
  final bool bookmarked;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    Widget item(IconData icon, String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 72, minHeight: kMinTap),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: t.heading, size: 28),
              Text(
                label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
              ),
            ],
          ),
        ),
      ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        color: t.surface,
        child: Row(
          mainAxisSize: inline ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            item(Icons.play_arrow_rounded, s.play, onPlay),
            item(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, s.bookmark, onBookmark),
            item(Icons.list_alt_rounded, s.goTo, onGoTo),
          ],
        ),
      ),
    );
  }
}

/// Reports which large-text page is at the top of the screen.
class _PageTracker extends StatefulWidget {
  const _PageTracker({super.key, required this.child, required this.onPage});

  final Widget child;
  final ValueChanged<int> onPage;

  static _PageTrackerState? of(BuildContext context) => context.findAncestorStateOfType<_PageTrackerState>();

  @override
  State<_PageTracker> createState() => _PageTrackerState();
}

class _PageTrackerState extends State<_PageTracker> {
  final _pages = <int, BuildContext>{};

  void register(int page, BuildContext c) => _pages[page] = c;
  void unregister(int page) => _pages.remove(page);

  void _check() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final top = box.localToGlobal(Offset.zero).dy + 40;
    for (final e in _pages.entries) {
      final r = e.value.findRenderObject() as RenderBox?;
      if (r == null || !r.attached) continue;
      final y = r.localToGlobal(Offset.zero).dy;
      if (y <= top && y + r.size.height > top) {
        widget.onPage(e.key);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _check();
        return false;
      },
      child: widget.child,
    );
  }
}

TextSpan _ayahSpans(
  List<Ayah> ayahs,
  TextStyle style, {
  required String? selected,
  required Color highlight,
  required List<GestureRecognizer> recognizers,
  required void Function(Ayah) onAyah,
}) {
  GestureRecognizer rec(Ayah a) {
    final r = LongPressGestureRecognizer()..onLongPress = () => onAyah(a);
    recognizers.add(r);
    return r;
  }

  return TextSpan(
    style: style,
    children: [
      for (final a in ayahs) ...[
        TextSpan(
          text: a.text,
          style: selected == '${a.sura}:${a.ayah}' ? TextStyle(backgroundColor: highlight) : null,
          recognizer: rec(a),
        ),
        const TextSpan(text: ' '),
      ],
    ],
  );
}

/// Splits a page into blocks: surah headers and runs of ayahs.
List<Object> _blocks(List<Ayah> ayahs) {
  final out = <Object>[];
  var run = <Ayah>[];
  for (final a in ayahs) {
    if (a.ayah == 1) {
      if (run.isNotEmpty) out.add(run);
      run = [];
      out.add(a.sura);
    }
    run.add(a);
  }
  if (run.isNotEmpty) out.add(run);
  return out;
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.sura, required this.q, required this.fontSize});

  final int sura;
  final QuranData q;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: t.sage, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'سُورَةُ ${q.sura(sura).ar}',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: fontSize * 0.95, color: t.heading, height: 1.6),
          ),
        ),
        if (sura != 1 && sura != 9)
          Text(
            q.basmala,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: fontSize * 0.9, color: t.text, height: 1.9),
          ),
      ],
    );
  }
}

class _LargePage extends StatefulWidget {
  const _LargePage({required this.q, required this.page, required this.selected, required this.onAyah});

  final QuranData q;
  final int page;
  final String? selected;
  final void Function(Ayah) onAyah;

  @override
  State<_LargePage> createState() => _LargePageState();
}

class _LargePageState extends State<_LargePage> {
  final _recognizers = <GestureRecognizer>[];
  _PageTrackerState? _tracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tracker = _PageTracker.of(context)?..register(widget.page, context);
  }

  @override
  void dispose() {
    _tracker?.unregister(widget.page);
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    const size = 26.0;
    final style = TextStyle(fontFamily: SanadiFonts.quran, fontSize: size, color: t.text, height: 2.1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: t.sage, thickness: 1.5)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.sage, width: 1.5),
                ),
                child: Text(
                  s.page(widget.page),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
                ),
              ),
              Expanded(child: Divider(color: t.sage, thickness: 1.5)),
            ],
          ),
          for (final b in _blocks(widget.q.page(widget.page)))
            if (b is int)
              _SurahHeader(sura: b, q: widget.q, fontSize: size)
            else
              SizedBox(
                width: double.infinity,
                child: Text.rich(
                  _ayahSpans(
                    b as List<Ayah>,
                    style,
                    selected: widget.selected,
                    highlight: t.tint,
                    recognizers: _recognizers,
                    onAyah: widget.onAyah,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                ),
              ),
        ],
      ),
    );
  }
}

/// One mushaf page, scaled to fill the screen in portrait.
class _MushafPage extends StatefulWidget {
  const _MushafPage({
    required this.q,
    required this.page,
    required this.selected,
    required this.onAyah,
    required this.scroll,
  });

  final QuranData q;
  final int page;
  final String? selected;
  final void Function(Ayah) onAyah;
  final bool scroll;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final _recognizers = <GestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  double _fit(List<Object> blocks, double width, double height) {
    var lo = 12.0, hi = 34.0;
    for (var k = 0; k < 12; k++) {
      final mid = (lo + hi) / 2;
      if (_measure(blocks, width, mid) <= height) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  double _measure(List<Object> blocks, double width, double size) {
    var h = 0.0;
    for (final b in blocks) {
      if (b is int) {
        h += size * 0.95 * 1.6 + 12 + 6 + 4;
        if (b != 1 && b != 9) h += size * 0.9 * 1.9;
      } else {
        final tp = TextPainter(
          text: TextSpan(
            text: (b as List<Ayah>).map((a) => a.text).join(' '),
            style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: size, height: 1.95),
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
        )..layout(maxWidth: width);
        h += tp.height;
        tp.dispose();
      }
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final ayahs = widget.q.page(widget.page);
    final blocks = _blocks(ayahs);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark ? t.bg : const Color(0xFFFBF8F1),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.q.sura(ayahs.first.sura).name(true),
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w700, color: t.muted),
                ),
                const Spacer(),
                Text(
                  S(ar: true, female: s.female).juz(ayahs.first.juz),
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.w700, color: t.muted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: t.sage, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = widget.scroll ? 30.0 : _fit(blocks, c.maxWidth, c.maxHeight - 4);
                    final style = TextStyle(fontFamily: SanadiFonts.quran, fontSize: size, color: t.text, height: 1.95);
                    final column = Column(
                      mainAxisAlignment: widget.scroll ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
                      children: [
                        for (final b in blocks)
                          if (b is int)
                            _SurahHeader(sura: b, q: widget.q, fontSize: size)
                          else
                            SizedBox(
                              width: double.infinity,
                              child: Text.rich(
                                _ayahSpans(
                                  b as List<Ayah>,
                                  style,
                                  selected: widget.selected,
                                  highlight: t.tint,
                                  recognizers: _recognizers,
                                  onAyah: widget.onAyah,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                      ],
                    );
                    return widget.scroll ? SingleChildScrollView(child: column) : column;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.n(widget.page),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 40 · Ayah menu. The ayah stays highlighted behind the sheet.
Future<void> showAyahMenu(BuildContext context, WidgetRef ref, Ayah a) {
  final s = S.of(context);
  final q = ref.read(quranProvider).value!;
  final suraName = q.sura(a.sura).name(s.ar);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final t = ctx.t;
      final tt = Theme.of(ctx).textTheme;
      final marked = ref.read(settingsProvider).bookmarks.contains('${a.sura}:${a.ayah}');
      Widget action(IconData icon, String label, VoidCallback onTap) => ListTile(
        minTileHeight: kMinTap + 4,
        leading: Icon(icon, color: t.primary, size: 28),
        title: Text(label, style: tt.titleMedium),
        onTap: onTap,
      );
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.ayahTitle(suraName, a.ayah), style: tt.headlineSmall),
                        Text(s.juzPage(a.juz, a.page), style: tt.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(s.close, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(kMinTap, kMinTap),
                      foregroundColor: t.text,
                      side: BorderSide(color: t.text, width: 2),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  a.text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: 24, color: t.text, height: 2),
                ),
              ),
              const SizedBox(height: 8),
              action(Icons.play_arrow_rounded, s.playFrom, () {
                Navigator.pop(ctx);
                showSoon(context);
              }),
              action(Icons.repeat_rounded, s.repeatAyah, () {
                Navigator.pop(ctx);
                showSoon(context);
              }),
              action(
                marked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded,
                marked ? s.removeBookmark : s.bookmarkAyah,
                () {
                  ref.read(settingsProvider.notifier).toggleBookmark(a.sura, a.ayah);
                  Navigator.pop(ctx);
                  if (!marked) toast(context, s.bookmarked);
                },
              ),
              action(Icons.content_copy_rounded, s.copyAyah, () {
                Clipboard.setData(
                  ClipboardData(text: '${a.plain}\n[${q.sura(a.sura).name(s.ar)} ${a.sura}:${a.ayah}]'),
                );
                Navigator.pop(ctx);
                toast(context, s.copied);
              }),
            ],
          ),
        ),
      );
    },
  );
}
