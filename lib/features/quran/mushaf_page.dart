import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'quran_data.dart';

/// Called when an ayah is long-pressed, with where the finger is.
typedef AyahPressed = void Function(Ayah ayah, Offset globalPosition);

TextStyle quranStyle(double size, Color color) =>
    TextStyle(fontFamily: SanadiFonts.quran, letterSpacing: 0, fontSize: size, color: color, height: 1.0);

/// Usual gap between words, as a share of the font size (as printed).
const _gap = 0.22;

/// Tightest gap allowed before a long line is narrowed instead.
const _minGap = 0.08;

/// Each line's width at the reference size (with ordinary spaces) and how
/// many of its gaps stretch: precomputed, or measured here if missing (tests
/// only).
(List<double>, List<int>) _lineMetrics(QuranData q, int page) {
  final pre = q.lineWidths;
  final gaps = q.lineGaps;
  if (pre != null && gaps != null) return (pre[page - 1], gaps[page - 1]);
  return _measured.putIfAbsent(page, () {
    final style = quranStyle(q.widthRefSize, Colors.black);
    double w(String text, [double wordSpacing = 0]) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(wordSpacing: wordSpacing),
        ),
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
      )..layout();
      final x = tp.width;
      tp.dispose();
      return x;
    }

    // Alef never joins the next letter, so this is exactly one space.
    if (q.spaceWidth == 0) q.spaceWidth = w('\u0627 \u0627') - w('\u0627\u0627');
    final lines = q.lines(page);
    final widths = [for (final l in lines) l is TextLine ? w(l.text) : 0.0];
    return (
      widths,
      [
        for (var i = 0; i < lines.length; i++)
          if (lines[i] case final TextLine l) ((w(l.text, 10) - widths[i]) / 10).round() else 0,
      ],
    );
  });
}

final _measured = <int, (List<double>, List<int>)>{};

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
              final (widths, gaps) = _lineMetrics(q, page);
              final ref = q.widthRefSize;
              // Each line's width at the reference size with the usual gaps.
              final natural = [
                for (var i = 0; i < lines.length; i++)
                  switch (lines[i]) {
                    TextLine() => widths[i] + gaps[i] * (_gap * ref - q.spaceWidth),
                    _ => 0.0,
                  },
              ];
              // One size per page, set so a typical full line fills the
              // width. Rounded to quarter pixels, so pages share sizes and
              // the phone reuses the letters it has already drawn.
              final full = [
                for (final w in natural)
                  if (w > 0) w,
              ]..sort();
              final typical = full.isEmpty ? width : full[(full.length * 0.5).floor().clamp(0, full.length - 1)];
              var size = ref * width / typical;
              // ...but small enough that the longest line fits with the
              // tightest gaps, so no line ever has to be narrowed.
              var longest = 0.0;
              for (var i = 0; i < lines.length; i++) {
                if (lines[i] is TextLine) {
                  longest = math.max(
                    longest,
                    widths[i] + gaps[i] * ((page <= 2 ? _gap : _minGap) * ref - q.spaceWidth),
                  );
                }
              }
              if (longest > 0) size = math.min(size, ref * width / longest);
              const header = 30.0, footer = 28.0;
              final lineH = widget.scrollable ? size * 2.05 : (c.maxHeight - header - footer) / 15;
              if (!widget.scrollable) size = math.min(size, lineH / 1.72);
              size = (size * 4).floorToDouble() / 4;

              final body = ValueListenableBuilder<String?>(
                valueListenable: widget.selected,
                builder: (context, sel, _) => Column(
                  mainAxisAlignment: lines.length < 15 ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      SizedBox(
                        height: lineH,
                        child: _line(lines[i], widths[i], gaps[i], natural[i], size, width, ink, t, sel),
                      ),
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

  Widget _line(
    PageLine line,
    double measured,
    int gaps,
    double natural,
    double size,
    double width,
    Color ink,
    SanadiTokens t,
    String? sel,
  ) {
    switch (line) {
      case HeaderLine(:final sura):
        return _SurahFrame(name: widget.q.sura(sura).ar, size: size, color: t.primary, ink: ink);
      case BasmalaLine():
        return Basmala(color: ink, text: widget.q.basmala);
      case TextLine(:final segments):
        final q = widget.q;
        final k = size / q.widthRefSize;
        final space = q.spaceWidth * k;
        // Short lines (the first pages, or a surah's last line) are centred
        // with the usual gaps. Full lines are justified: the gaps between
        // words grow or shrink so the line meets both edges, as printed.
        final centre = widget.page <= 2 || gaps == 0 || natural * k < width * 0.75;
        var spacing = centre ? size * _gap - space : (width - measured * k) / gaps;
        // Never closer than [_minGap]; a line that would need it is narrowed.
        spacing = math.max(spacing, size * _minGap - space);
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
        return _FitLine(
          width: width,
          justify: !centre,
          child: Text.rich(
            TextSpan(
              style: quranStyle(size, ink).copyWith(wordSpacing: spacing),
              children: spans,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 1,
            softWrap: false,
          ),
        );
    }
  }
}

/// Lays a line out at its own width, then fits it to the page width: a
/// justified line is matched to the width exactly (any rounding is taken up
/// by an invisible horizontal scale of a percent or two); a centred line is
/// only ever narrowed, never stretched. Nothing can spill past the page.
class _FitLine extends SingleChildRenderObjectWidget {
  const _FitLine({required this.width, required this.justify, required super.child});

  final double width;
  final bool justify;

  @override
  _RenderFitLine createRenderObject(BuildContext context) => _RenderFitLine(width, justify);

  @override
  void updateRenderObject(BuildContext context, _RenderFitLine r) => r
    ..lineWidth = width
    ..justify = justify;
}

class _RenderFitLine extends RenderProxyBox {
  _RenderFitLine(this._lineWidth, this._justify);

  double _lineWidth;
  set lineWidth(double v) {
    if (v == _lineWidth) return;
    _lineWidth = v;
    markNeedsLayout();
  }

  bool _justify;
  set justify(bool v) {
    if (v == _justify) return;
    _justify = v;
    markNeedsLayout();
  }

  double _scale = 1;
  Offset _offset = Offset.zero;

  @override
  void performLayout() {
    final c = child!;
    c.layout(BoxConstraints(maxHeight: constraints.maxHeight), parentUsesSize: true);
    size = constraints.constrain(Size(constraints.maxWidth, constraints.maxHeight));
    final w = c.size.width;
    _scale = w <= 0 ? 1 : (_justify ? (_lineWidth / w).clamp(0.6, 1.04) : math.min(1.0, _lineWidth / w));
    _offset = Offset((size.width - w * _scale) / 2, (size.height - c.size.height) / 2);
  }

  Matrix4 get _transform => Matrix4.translationValues(_offset.dx, _offset.dy, 0)..scaleByDouble(_scale, 1, 1, 1);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_scale == 1) {
      context.paintChild(child!, offset + _offset);
    } else {
      context.pushTransform(needsCompositing, offset, _transform, (ctx, o) => ctx.paintChild(child!, o));
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) => transform.multiply(_transform);

  /// A press anywhere in the line's height counts as a press on the text
  /// at that point (an easy target for a long-press).
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child!;
    final inChild = Offset(
      ((position.dx - _offset.dx) / _scale).clamp(0, c.size.width),
      (position.dy - _offset.dy).clamp(0.5, c.size.height - 0.5),
    );
    return result.addWithOutOfBandPosition(
      paintTransform: _transform,
      hitTest: (r) => c.hitTest(r, position: inChild),
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
              style: TextStyle(
                fontFamily: SanadiFonts.naskh,
                letterSpacing: 0,
                fontSize: 100,
                height: 1.15,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
