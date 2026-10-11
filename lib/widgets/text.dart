import 'package:flutter/material.dart';

import '../core/theme.dart';

// Text that never breaks a word across lines, and names that fit.

/// Surah names carry harakat; Noto Naskh stacks them cleanly where the UI
/// font would let them collide with the letters. Applies in Arabic, or
/// always when [arabic] is true.
TextStyle nameFont(BuildContext context, TextStyle style, {bool arabic = false}) {
  if (!arabic && !context.isAr) return style;
  return style.copyWith(
    fontFamily: SanadiFonts.naskh,
    letterSpacing: 0,
    fontFamilyFallback: const ['Tajawal'],
    height: (style.height ?? 1.3) + 0.3,
  );
}

/// Width of the widest single word in [text], as it would be drawn.
double longestWordWidth(BuildContext context, String text, TextStyle style) {
  final scaler = MediaQuery.textScalerOf(context);
  final dir = Directionality.of(context);
  final base = DefaultTextStyle.of(context).style.merge(style);
  var max = 0.0;
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final tp = TextPainter(
      text: TextSpan(text: word, style: base),
      textDirection: dir,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    if (tp.width > max) max = tp.width;
    tp.dispose();
  }
  return max;
}

/// Text that wraps only between words. If a single word is wider than the
/// space, the text is drawn slightly smaller so the word stays whole.
class WordSafeText extends StatelessWidget {
  const WordSafeText(this.text, {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final scaler = MediaQuery.textScalerOf(context);
        TextScaler? fitted;
        if (c.hasBoundedWidth && c.maxWidth > 0) {
          final longest = longestWordWidth(context, text, style ?? const TextStyle());
          if (longest > c.maxWidth) {
            final size = (DefaultTextStyle.of(context).style.merge(style)).fontSize ?? 14;
            final current = scaler.scale(size) / size;
            fitted = TextScaler.linear(current * c.maxWidth / longest * 0.98);
          }
        }
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          textScaler: fitted,
        );
      },
    );
  }
}

/// Shows a name in full. If it doesn't fit on one line it scrolls gently
/// sideways (marquee); with "remove animations" on, it wraps instead.
class FullName extends StatelessWidget {
  const FullName(this.text, {super.key, required this.style, this.textAlign = TextAlign.start});

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final scaler = MediaQuery.textScalerOf(context);
        final dir = Directionality.of(context);
        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: dir,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final w = tp.width;
        final h = tp.height;
        tp.dispose();
        if (w <= c.maxWidth || MediaQuery.disableAnimationsOf(context)) {
          return WordSafeText(text, style: style, textAlign: textAlign);
        }
        return Semantics(
          label: text,
          excludeSemantics: true,
          child: SizedBox(
            height: h,
            child: _Marquee(text: text, style: style, textWidth: w),
          ),
        );
      },
    );
  }
}

class _Marquee extends StatefulWidget {
  const _Marquee({required this.text, required this.style, required this.textWidth});

  final String text;
  final TextStyle style;
  final double textWidth;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    // Wait, scroll to the end, wait, slide back; repeat.
    final scrollMs = (widget.textWidth * 25).round().clamp(1500, 8000);
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + scrollMs + 2000 + 600),
    )..repeat();
    _t = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 2000),
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: scrollMs.toDouble()),
      TweenSequenceItem(tween: ConstantTween(1), weight: 2000),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeOut)), weight: 600),
    ]).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final overflow = (widget.textWidth - c.maxWidth).clamp(0.0, double.infinity);
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return ClipRect(
          child: OverflowBox(
            alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
            maxWidth: double.infinity,
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, child) =>
                  Transform.translate(offset: Offset((rtl ? 1 : -1) * overflow * _t.value, 0), child: child),
              child: Text(widget.text, style: widget.style, maxLines: 1, softWrap: false),
            ),
          ),
        );
      },
    );
  }
}
