import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'mushaf_page.dart';
import 'quran_data.dart';

/// Large text mode: the Quran reflowed in big type, page after page, with
/// "Page N" dividers. Only the pages on screen are built.
class LargeTextView extends StatefulWidget {
  const LargeTextView({
    super.key,
    required this.q,
    required this.startPage,
    required this.selected,
    required this.onAyah,
    required this.onPage,
    required this.onTap,
  });

  final QuranData q;
  final int startPage;
  final ValueNotifier<String?> selected;
  final AyahPressed onAyah;
  final ValueChanged<int> onPage;
  final VoidCallback onTap;

  @override
  State<LargeTextView> createState() => _LargeTextViewState();
}

class _LargeTextViewState extends State<LargeTextView> {
  final _pages = <int, BuildContext>{};
  late final _centerKey = ValueKey('center-${widget.startPage}');

  void _check() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy + 60;
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

  Widget _page(int p) => _LargePage(
    key: ValueKey(p),
    q: widget.q,
    page: p,
    selected: widget.selected,
    onAyah: widget.onAyah,
    register: (c) => _pages[p] = c,
    unregister: () => _pages.remove(p),
  );

  @override
  Widget build(BuildContext context) {
    final start = widget.startPage;
    return GestureDetector(
      onTap: widget.onTap,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (_) {
          _check();
          return false;
        },
        child: CustomScrollView(
          center: _centerKey,
          slivers: [
            SliverList.builder(itemCount: start - 1, itemBuilder: (_, i) => _page(start - 1 - i)),
            SliverList.builder(
              key: _centerKey,
              itemCount: QuranData.pageCount - start + 1,
              itemBuilder: (_, i) => _page(start + i),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargePage extends StatefulWidget {
  const _LargePage({
    super.key,
    required this.q,
    required this.page,
    required this.selected,
    required this.onAyah,
    required this.register,
    required this.unregister,
  });

  final QuranData q;
  final int page;
  final ValueNotifier<String?> selected;
  final AyahPressed onAyah;
  final void Function(BuildContext) register;
  final VoidCallback unregister;

  @override
  State<_LargePage> createState() => _LargePageState();
}

class _LargePageState extends State<_LargePage> {
  /// Ayahs that start on this page (an ayah running over from the previous
  /// page is shown there, not twice).
  late final List<Ayah> _ayahs = [
    for (final a in widget.q.page(widget.page))
      if (widget.q.pageOf(a) == widget.page) a,
  ];

  /// One long-press recogniser per ayah, made once for the page.
  late final Map<String, LongPressGestureRecognizer> _recognizers = {
    for (final a in _ayahs)
      a.key: LongPressGestureRecognizer()..onLongPressStart = (d) => widget.onAyah(a, d.globalPosition),
  };

  @override
  void initState() {
    super.initState();
    widget.register(context);
  }

  @override
  void dispose() {
    widget.unregister();
    for (final r in _recognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final q = widget.q;
    const size = 27.0;
    final style = TextStyle(fontFamily: SanadiFonts.quran, fontSize: size, color: t.text, height: 2.1);

    // Group the page into surah starts and runs of ayahs.
    final blocks = <Object>[];
    var run = <Ayah>[];
    for (final a in _ayahs) {
      if (a.ayah == 1) {
        if (run.isNotEmpty) blocks.add(run);
        run = [];
        blocks.add(a.sura);
      }
      run.add(a);
    }
    if (run.isNotEmpty) blocks.add(run);

    return RepaintBoundary(
      child: Padding(
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
            for (final b in blocks)
              if (b is int) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: t.sage, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'سُورَةُ ${q.sura(b).ar}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: SanadiFonts.quran,
                      fontSize: size * 0.95,
                      color: t.heading,
                      height: 1.6,
                    ),
                  ),
                ),
                if (b != 1 && b != 9) Basmala(color: t.text, text: q.basmala, height: size * 2.2),
              ] else
                ValueListenableBuilder<String?>(
                  valueListenable: widget.selected,
                  builder: (context, sel, _) => SizedBox(
                    width: double.infinity,
                    child: Text.rich(
                      TextSpan(
                        style: style,
                        children: [
                          for (final a in b as List<Ayah>) ...[
                            TextSpan(
                              text: a.plain,
                              recognizer: _recognizers[a.key],
                              style: sel == a.key ? TextStyle(backgroundColor: t.tint) : null,
                            ),
                            TextSpan(
                              text: ' ${a.number} ',
                              style: TextStyle(color: t.primary),
                            ),
                          ],
                        ],
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
