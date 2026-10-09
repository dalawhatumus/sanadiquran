import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/core/theme.dart';
import 'package:sanadi/features/quran/large_text_view.dart';
import 'package:sanadi/features/quran/mushaf_page.dart';
import 'package:sanadi/features/quran/quran_data.dart';

/// Opens every one of the 604 mushaf pages, and every page in Large text,
/// with the real fonts on common phone sizes, and checks that:
/// - no line spills past the page edges or overlaps another line,
/// - every full line is justified edge to edge, and no line is squeezed
///   so much that it looks distorted,
/// - nothing overflows (any overflow fails the test).
Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

void main() {
  final q = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());

  setUpAll(() async {
    await _loadFont('Tajawal', ['assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf']);
    await _loadFont('NotoNaskhArabic', ['assets/fonts/NotoNaskhArabic-Medium.ttf']);
    await _loadFont(SanadiFonts.quran, ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
  });

  Widget host(Widget child, {double textScale = 1}) => MaterialApp(
    theme: buildTheme(const Locale('ar'), Brightness.light),
    home: StringsScope(
      s: const S(ar: true, female: true),
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );

  test('precomputed line widths cover every page and line', () {
    expect(q.lineWidths!.length, QuranData.pageCount);
    for (var p = 1; p <= QuranData.pageCount; p++) {
      final lines = q.lines(p);
      expect(q.lineWidths![p - 1].length, lines.length, reason: 'page $p');
      for (var i = 0; i < lines.length; i++) {
        expect(q.lineWidths![p - 1][i] > 0, lines[i] is TextLine, reason: 'page $p line $i');
      }
    }
  });

  for (final (size, scrollable) in const [
    (Size(360, 740), false),
    (Size(412, 860), false),
    (Size(320, 600), false),
    // Landscape phone: the page scrolls; and half of a tablet spread.
    (Size(780, 360), true),
    (Size(560, 760), false),
  ]) {
    testWidgets(
      'all 604 mushaf pages lay out cleanly at ${size.width.toInt()}x${size.height.toInt()}${scrollable ? ' (scrolling)' : ''}',
      (tester) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final selected = ValueNotifier<String?>(null);
        var minScale = 9.0, maxScale = 0.0;
        var minScalePage = 0;
        for (var p = 1; p <= QuranData.pageCount; p++) {
          await tester.pumpWidget(
            host(
              MushafPage(
                key: ValueKey(p),
                q: q,
                page: p,
                selected: selected,
                onAyah: (_, _) {},
                onTap: (_) {},
                scrollable: scrollable,
              ),
            ),
          );
          final page = tester.renderObject<RenderBox>(find.byType(MushafPage));
          final pageRect = page.localToGlobal(Offset.zero) & page.size;
          const hPad = 14.0;
          final texts = {
            for (final l in q.lines(p))
              if (l is TextLine) l.text,
          };
          final lines = <Rect>[];
          void visit(RenderObject r) {
            if (r is RenderParagraph && texts.contains(r.text.toPlainText())) {
              // Corners after the line's fit-to-width transform.
              final a = r.localToGlobal(Offset.zero);
              final b = r.localToGlobal(Offset(r.size.width, r.size.height));
              final rect = Rect.fromPoints(a, b);
              lines.add(rect);
              final scale = rect.width / r.size.width;
              if (scale < minScale) {
                minScale = scale;
                minScalePage = p;
              }
              if (scale > maxScale) maxScale = scale;
            }
            r.visitChildren(visit);
          }

          visit(page);
          expect(lines, isNotEmpty, reason: 'page $p has no text');
          final inner = Rect.fromLTRB(
            pageRect.left + hPad - 1,
            pageRect.top,
            pageRect.right - hPad + 1,
            pageRect.bottom,
          );
          final textLines = [
            for (final l in q.lines(p))
              if (l is TextLine) l,
          ];
          expect(lines.length, textLines.length, reason: 'page $p line count');
          for (var i = 0; i < lines.length; i++) {
            final r = lines[i];
            expect(
              r.left >= inner.left &&
                  r.right <= inner.right &&
                  r.top >= inner.top &&
                  (scrollable || r.bottom <= inner.bottom),
              isTrue,
              reason: 'page $p line ${i + 1} spills outside the page: $r vs $inner',
            );
            if (i > 0) {
              expect(r.top >= lines[i - 1].bottom, isTrue, reason: 'page $p line ${i + 1} overlaps the line above');
            }
            // Full lines (all but centred short ones) reach both edges.
            final full = r.width > inner.width * 0.8;
            if (full && p > 2) {
              expect(r.width, greaterThan(inner.width - 4), reason: 'page $p line ${i + 1} is not justified');
            }
          }
        }
        // ignore: avoid_print
        print('${size.width}x${size.height}: line scale $minScale (page $minScalePage) … $maxScale');
        expect(minScale, greaterThan(0.97), reason: 'a line on page $minScalePage is squeezed too much');
        expect(maxScale, lessThan(1.05));
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );
  }

  for (final scale in const [1.0, 2.0]) {
    testWidgets('every page in Large text lays out cleanly at ${(scale * 100).toInt()}% text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final selected = ValueNotifier<String?>(null);
      for (var p = 1; p <= QuranData.pageCount; p += 1) {
        await tester.pumpWidget(
          host(
            LargeTextView(
              key: ValueKey(p),
              q: q,
              startPage: p,
              selected: selected,
              onAyah: (_, _) {},
              onPage: (_) {},
              onTap: () {},
            ),
            textScale: scale,
          ),
        );
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
