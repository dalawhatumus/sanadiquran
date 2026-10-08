import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
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

/// Measures a page's lines ahead of time (call for the pages next to the
/// one on screen, so turning to them is instant).
void warmMushafPage(QuranData q, int page) {
  if (page >= 1 && page <= QuranData.pageCount) _lineWidths(q, page);
}

/// Width of the font's space at [_refSize]; lines are drawn as one text run
/// with word spacing adjusted so each gap is exactly [_gap] em.
double? _spaceRef;
double _spaceWidth(TextStyle style) => _spaceRef ??= () {
  final tp = TextPainter(
    text: TextSpan(text: '\u0628 \u0628', style: style),
    textDirection: TextDirection.rtl,
    textScaler: TextScaler.noScaling,
  )..layout();
  final both = tp.width;
  tp.text = TextSpan(text: '\u0628\u0628', style: style);
  tp.layout();
  final w = both - tp.width;
  tp.dispose();
  return w;
}();

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
/// surah frame, basmala, page header and page number. Each line is drawn as
/// a single text run, which keeps page turns smooth.
class MushafPage extends StatefulWidget {
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

  /// Called with where the page was tapped (global position).
  final ValueChanged<Offset> onTap;

  /// Landscape on a phone: lines keep a readable size and the page scrolls.
  final bool scrollable;

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  /// One long-press recogniser per ayah on the page, made once.
  late final Map<String, LongPressGestureRecognizer> _press = {
    for (final a in widget.q.page(widget.page))
      a.key: LongPressGestureRecognizer()..onLongPressStart = (d) => widget.onAyah(a, d.globalPosition),
  };

  @override
  void dispose() {
    for (final r in _press.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final page = widget.page;
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
        onTapUp: (d) => widget.onTap(d.globalPosition),
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
              final lineH = widget.scrollable ? size * 2.05 : (c.maxHeight - header - footer) / 15;
              if (!widget.scrollable) size = math.min(size, lineH / 1.72);

              final body = ValueListenableBuilder<String?>(
                valueListenable: widget.selected,
                builder: (context, sel, _) => Column(
                  mainAxisAlignment: lines.length < 15 ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      SizedBox(height: lineH, child: _line(lines[i], widths[i], size, width, ink, t, sel)),
                  ],
                ),
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
                            child: Text(
                              sura.name(s.ar),
                              style: nameFont(context, meta),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(s.juz(first.juz), style: meta),
                        ],
                      ),
                    ),
                    Expanded(child: widget.scrollable ? SingleChildScrollView(child: body) : body),
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

  Widget _line(PageLine line, double natural, double size, double width, Color ink, SanadiTokens t, String? sel) {
    switch (line) {
      case HeaderLine(:final sura):
        return _SurahFrame(name: widget.q.sura(sura).ar, size: size, color: t.primary, ink: ink);
      case BasmalaLine():
        return Basmala(color: ink, text: widget.q.basmala);
      case TextLine(:final segments):
        // The whole line is one text run; gaps between words are set to
        // exactly [_gap] em through word spacing.
        final style = quranStyle(size, ink);
        final wordSpacing = size * _gap - _spaceWidth(quranStyle(_refSize, ink)) * size / _refSize;
        final spans = <InlineSpan>[];
        for (var i = 0; i < segments.length; i++) {
          final seg = segments[i];
          final a = seg.ayah;
          final hl = sel == a.key ? TextStyle(backgroundColor: t.tint) : null;
          if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
          spans.add(
            TextSpan(text: a.words.sublist(seg.from - 1, seg.to).join(' '), style: hl, recognizer: _press[a.key]),
          );
          if (seg.endsAyah) {
            spans.add(TextSpan(text: ' ', style: hl));
            spans.add(
              TextSpan(
                text: a.number,
                style: TextStyle(color: t.primary, backgroundColor: hl?.backgroundColor),
                recognizer: _press[a.key],
              ),
            );
          }
        }
        final text = Text.rich(
          TextSpan(
            style: style.copyWith(wordSpacing: wordSpacing),
            children: spans,
          ),
          textDirection: TextDirection.rtl,
          maxLines: 1,
          softWrap: false,
        );
        // Short lines (the first pages, or a surah's last line) are centred.
        // Full lines fill the width exactly: like kashida in the printed
        // mushaf, the line is stretched or squeezed slightly sideways.
        final scaled = natural * size / _refSize;
        final centre = widget.page <= 2 || scaled < width * 0.75;
        if (centre) {
          return Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: text),
          );
        }
        final stretch = (width / scaled).clamp(0.8, 1.3);
        return OverflowBox(
          maxWidth: double.infinity,
          child: Transform.scale(scaleX: stretch, scaleY: 1, child: text),
        );
    }
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
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox.expand(),
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/icons/surah_frame.svg',
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            // The name sits inside the middle cartouche with a clear margin,
            // shrinking if needed so it never touches the frame's lines.
            SizedBox(
              width: c.maxWidth * 0.34,
              height: c.maxHeight * 0.5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('سُورَةُ $name', textDirection: TextDirection.rtl, style: quranStyle(size * 0.85, ink)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The basmala in calligraphy (Noto Naskh's ﷽ glyph), set apart from the
/// ayah text. Screen readers hear the full words.
class Basmala extends StatelessWidget {
  const Basmala({super.key, required this.color, required this.text, this.height});

  final Color color;
  final String text;

  /// Fixed height; by default it fills the space it is given.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FractionallySizedBox(
          // Centred and narrower than a line, like the printed basmala.
          widthFactor: 0.75,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              '\uFDFD',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: SanadiFonts.naskh, fontSize: 100, height: 1.15, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
