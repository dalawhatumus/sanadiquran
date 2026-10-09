import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _letter = RegExp(r'\p{L}', unicode: true);

/// Words that a text block splits across two lines (e.g. "Mess-age").
/// Line breaks between words are fine; inside a word they are not.
List<String> brokenWords(WidgetTester tester) {
  final out = <String>[];
  void visit(RenderObject r) {
    if (r is RenderParagraph && r.softWrap && r.hasSize) {
      final text = r.text.toPlainText();
      // Lay the same text out again at the same width to read its lines.
      final tp = TextPainter(
        text: r.text,
        textDirection: r.textDirection,
        textScaler: r.textScaler,
        textAlign: r.textAlign,
        maxLines: r.maxLines,
      )..layout(maxWidth: r.size.width + 0.5);
      var pos = 0;
      while (pos < text.length) {
        final line = tp.getLineBoundary(TextPosition(offset: pos));
        final end = line.end;
        if (end <= pos) break;
        if (end < text.length && end > 0 && _letter.hasMatch(text[end - 1]) && _letter.hasMatch(text[end])) {
          final a = text.lastIndexOf(RegExp(r'\s'), end - 1) + 1;
          var b = text.indexOf(RegExp(r'\s'), end);
          if (b < 0) b = text.length;
          out.add(text.substring(a, b));
        }
        pos = end;
      }
      tp.dispose();
    }
    r.visitChildren(visit);
  }

  for (final e in find.byType(Scaffold).evaluate()) {
    final ro = e.renderObject;
    if (ro != null) visit(ro);
  }
  return out;
}

/// Pairs of visible text blocks that sit on top of each other. Only what is
/// actually painted counts: hidden tabs and routes, transparent widgets and
/// anything scrolled or clipped out of view are ignored.
List<String> overlappingText(WidgetTester tester) {
  final boxes = <(Rect, String)>[];
  void visit(RenderObject r, Rect clip) {
    if (r is RenderBox && r.hasSize && r.attached) {
      final global = MatrixUtils.transformRect(r.getTransformTo(null), Offset.zero & r.size);
      if (r is RenderViewportBase || r is RenderClipRect || r is RenderClipRRect || r is RenderClipPath) {
        clip = clip.intersect(global);
      }
      if (r is RenderParagraph) {
        final text = r.text.toPlainText().trim();
        final visible = clip.intersect(global);
        if (text.isNotEmpty && visible.width > 1 && visible.height > 1) boxes.add((visible, text));
        return;
      }
    }
    if (r is RenderOpacity && r.opacity == 0) return;
    if (r is RenderAnimatedOpacity && r.opacity.value == 0) return;
    if (clip.isEmpty) return;
    r.visitChildrenForSemantics((c) => visit(c, clip));
  }

  final root = tester.binding.renderViews.first;
  visit(root, Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio);
  final out = <String>[];
  for (var i = 0; i < boxes.length; i++) {
    for (var j = i + 1; j < boxes.length; j++) {
      final o = boxes[i].$1.intersect(boxes[j].$1);
      if (o.width > 2 && o.height > 2 && o.width * o.height > 12) {
        String short(String s) => s.substring(0, math.min(30, s.length));
        out.add('"${short(boxes[i].$2)}" and "${short(boxes[j].$2)}"');
      }
    }
  }
  return out;
}
