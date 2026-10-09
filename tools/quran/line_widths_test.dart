// Measures every mushaf line once with the bundled KFGQPC font and writes
// assets/quran/line_widths.json, so the app never measures text at runtime.
// Run after changing the font or layout:
//   flutter test tools/quran/line_widths_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/theme.dart';
import 'package:sanadi/features/quran/quran_data.dart';

const ref = 20.0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('measure mushaf lines', () async {
    final loader = FontLoader(SanadiFonts.quran)..addFont(rootBundle.load('assets/fonts/quran/UthmanicHafs1Ver18.ttf'));
    await loader.load();
    final q = QuranData.parse((
      File('assets/quran/hafs.json').readAsStringSync(),
      File('assets/quran/layout.json').readAsStringSync(),
    ));
    final style = TextStyle(fontFamily: SanadiFonts.quran, fontSize: ref, height: 1.0);
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

    // Alef never joins the letter after it, so this is exactly one space.
    final space = w('ا ا') - w('اا');
    final pages = <List<double>>[];
    // How many gaps on each line take word spacing. Not every space does
    // (e.g. the one beside an ayah number or hizb mark), so it is measured.
    final gaps = <List<int>>[];
    for (var p = 1; p <= QuranData.pageCount; p++) {
      final widths = <double>[];
      final counts = <int>[];
      for (final line in q.lines(p)) {
        if (line is TextLine) {
          final base = w(line.text);
          widths.add(double.parse(base.toStringAsFixed(2)));
          counts.add(((w(line.text, 10) - base) / 10).round());
        } else {
          widths.add(0);
          counts.add(0);
        }
      }
      pages.add(widths);
      gaps.add(counts);
    }
    File('assets/quran/line_widths.json').writeAsStringSync(
      jsonEncode({'refSize': ref, 'space': double.parse(space.toStringAsFixed(3)), 'pages': pages, 'gaps': gaps}),
    );
  });
}
