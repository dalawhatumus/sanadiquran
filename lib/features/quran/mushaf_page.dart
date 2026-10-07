import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import 'quran_data.dart';

/// Called when an ayah is long-pressed, with where the finger is.
typedef AyahPressed = void Function(Ayah ayah, Offset globalPosition);

/// Natural widths of each line at [_refSize], per page. Measuring once per
/// page keeps page turns smooth.
final _widthCache = <int, List<double>>{};
const _refSize = 20.0;

TextStyle quranStyle(double size, Color color) =>
    TextStyle(fontFamily: SanadiFonts.quran, fontSize: size, color: color, height: 1.0);

/// Gap between words, as a share of the font size.
const _gap = 0.22;

List<double> _lineWidths(QuranData q, int page) => _widthCache.putIfAbsent(page, () {
  final style = quranStyle(_refSize, Colors.black);
  return [
    for (final line in q.lines(page))
      if (line is TextLine) _lineWidth(line, style) else 0,
  ];
});

/// Width of a line's words at [_refSize] with the minimum gap between them.
double _lineWidth(TextLine line, TextStyle style) {
  var w = 0.0;
  var n = 0;
  for (final s in line.segments) {
    for (var i = s.from; i <= s.to; i++) {
      w += _wordWidth(s.ayah.words[i - 1], style);
      n++;
    }
    if (s.endsAyah) {
      w += _wordWidth(s.ayah.number, style);
      n++;
    }
  }
  return w + (n - 1) * _gap * _refSize;
}

final _wordCache = <String, double>{};

double _wordWidth(String word, TextStyle style) => _wordCache.putIfAbsent(word, () {
  final tp = TextPainter(
    text: TextSpan(text: word, style: style),
    textDirection: TextDirection.rtl,
    textScaler: TextScaler.noScaling,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w;
});

/// One page of the Madani mushaf: the exact 15 lines, justified, with the
/// surah frame, basmala, page header and page number.
class MushafPage extends StatelessWidget {
  const MushafPage({
    super.key,
    required this.q,
    required this.page,
    required this.selected,
    required this.onAyah,
    required this.onTap,
    this.scrollable = false,
  });

  final QuranData q;
  final int page;
  final ValueNotifier<String?> selected;
  final AyahPressed onAyah;
  final VoidCallback onTap;

  /// Landscape on a phone: lines keep a readable size and the page scrolls.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = S.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final paper = dark ? t.bg : const Color(0xFFFFFCF2);
    final ink = dark ? t.text : const Color(0xFF111111);
    final first = q.firstOn(page);
    final sura = q.sura(first.sura);
    final meta = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.muted);
    // Right-hand (odd) pages have the spine on the left, like a printed mushaf.
    final spineLeft = page.isOdd;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: paper,
            gradient: dark
                ? null
                : LinearGradient(
                    begin: spineLeft ? Alignment.centerLeft : Alignment.centerRight,
                    end: spineLeft ? Alignment.centerRight : Alignment.centerLeft,
                    colors: [const Color(0xFFEDE6D3), paper, paper],
                    stops: const [0, 0.06, 1],
                  ),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              const hPad = 14.0;
              final width = c.maxWidth - hPad * 2;
              final lines = q.lines(page);
              final widths = _lineWidths(q, page);
              // One size per page, set so a typical full line fills the
              // width; the few longer lines are squeezed slightly to fit.
              final full = [
                for (final w in widths)
                  if (w > 0) w,
              ]..sort();
              final typical = full.isEmpty ? width : full[(full.length * 0.5).floor().clamp(0, full.length - 1)];
              var size = _refSize * width / typical;
              const header = 30.0, footer = 28.0;
              final lineH = scrollable ? size * 2.05 : (c.maxHeight - header - footer) / 15;
              if (!scrollable) size = math.min(size, lineH / 1.72);

              final body = Column(
                mainAxisAlignment: lines.length < 15 ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  for (var i = 0; i < lines.length; i++)
                    SizedBox(height: lineH, child: _line(lines[i], widths[i], size, width, ink, t)),
                ],
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  children: [
                    SizedBox(
                      height: header,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(sura.name(s.ar), style: meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Text(s.juz(first.juz), style: meta),
                        ],
                      ),
                    ),
                    Expanded(child: scrollable ? SingleChildScrollView(child: body) : body),
                    SizedBox(
                      height: footer,
                      child: Center(child: Text(s.n(page), style: meta)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _line(PageLine line, double natural, double size, double width, Color ink, SanadiTokens t) {
    switch (line) {
      case HeaderLine(:final sura):
        return _SurahFrame(name: q.sura(sura).ar, size: size, color: t.primary, ink: ink);
      case BasmalaLine():
        return Center(
          child: Text(q.basmala, textDirection: TextDirection.rtl, style: quranStyle(size, ink)),
        );
      case TextLine(:final segments):
        final words = <Widget>[];
        for (final seg in segments) {
          for (var w = seg.from; w <= seg.to; w++) {
            words.add(
              _Word(
                text: seg.ayah.words[w - 1],
                ayah: seg.ayah,
                style: quranStyle(size, ink),
                selected: selected,
                onAyah: onAyah,
                onTap: onTap,
              ),
            );
          }
          if (seg.endsAyah) {
            words.add(
              _Word(
                text: seg.ayah.number,
                ayah: seg.ayah,
                style: quranStyle(size, t.primary),
                selected: selected,
                onAyah: onAyah,
                onTap: onTap,
              ),
            );
          }
        }
        // Short lines (the first pages, or a surah's last line) are centred.
        // Full lines fill the width exactly: like kashida in the printed
        // mushaf, the line is stretched or squeezed slightly sideways.
        final scaled = natural * size / _refSize;
        final centre = page <= 2 || scaled < width * 0.75;
        final row = Row(mainAxisSize: MainAxisSize.min, spacing: size * _gap, children: words);
        if (centre) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: row),
            ),
          );
        }
        final stretch = (width / scaled).clamp(0.8, 1.3);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: OverflowBox(
            maxWidth: double.infinity,
            child: Transform.scale(scaleX: stretch, scaleY: 1, child: row),
          ),
        );
    }
  }
}

class _Word extends StatelessWidget {
  const _Word({
    required this.text,
    required this.ayah,
    required this.style,
    required this.selected,
    required this.onAyah,
    required this.onTap,
  });

  final String text;
  final Ayah ayah;
  final TextStyle style;
  final ValueNotifier<String?> selected;
  final AyahPressed onAyah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = context.t.tint;
    return GestureDetector(
      onLongPressStart: (d) => onAyah(ayah, d.globalPosition),
      onTap: onTap,
      child: ValueListenableBuilder<String?>(
        valueListenable: selected,
        builder: (_, sel, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: sel == ayah.key ? tint : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        ),
        child: Text(text, style: style, textDirection: TextDirection.rtl, maxLines: 1, softWrap: false),
      ),
    );
  }
}

class _SurahFrame extends StatelessWidget {
  const _SurahFrame({required this.name, required this.size, required this.color, required this.ink});

  final String name;
  final double size;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox.expand(),
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/icons/surah_frame.svg',
              fit: BoxFit.fill,
              theme: SvgTheme(currentColor: color),
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          Text('سُورَةُ $name', textDirection: TextDirection.rtl, style: quranStyle(size * 0.92, ink)),
        ],
      ),
    );
  }
}
