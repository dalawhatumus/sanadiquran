import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/features/quran/mushaf_page.dart';
import 'package:sanadi/features/quran/quran_data.dart';

/// Guards the accuracy of the mushaf: the page layout must place every word
/// of the KFGQPC text exactly once, in order, and nothing else.
void main() {
  final q = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ));

  test('114 surahs, 6236 ayahs, 604 pages, 30 juz', () {
    expect(q.suras.length, 114);
    expect(q.ayahs.length, 6236);
    expect(q.juzStarts.length, 30);
    expect(q.suras.where((s) => s.madani).length, 28);
    for (var p = 1; p <= QuranData.pageCount; p++) {
      expect(q.lines(p), isNotEmpty, reason: 'page $p');
    }
  });

  test('every word of every ayah appears exactly once, in reading order', () {
    final next = <String, int>{}; // ayah -> next expected word
    final ended = <String>{};
    Ayah? last;
    for (var p = 1; p <= QuranData.pageCount; p++) {
      for (final line in q.lines(p)) {
        if (line is! TextLine) continue;
        for (final seg in line.segments) {
          final a = seg.ayah;
          final expected = next[a.key] ?? 1;
          expect(seg.from, expected, reason: '${a.key} on page $p');
          expect(seg.to, greaterThanOrEqualTo(seg.from));
          next[a.key] = seg.to + 1;
          if (seg.endsAyah) {
            expect(seg.to, a.words.length, reason: '${a.key} ends early');
            ended.add(a.key);
          }
          // Ayahs come in Quran order.
          if (last != null && last.key != a.key) {
            expect(q.ayahs.indexOf(a), q.ayahs.indexOf(last) + 1, reason: 'order at ${a.key}');
          }
          last = a;
        }
      }
    }
    expect(ended.length, 6236);
    for (final a in q.ayahs) {
      expect(next[a.key], a.words.length + 1, reason: a.key);
    }
  });

  test('surah headers sit where surahs begin', () {
    for (var p = 1; p <= QuranData.pageCount; p++) {
      final lines = q.lines(p);
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (l is! HeaderLine) continue;
        // The next text line starts with ayah 1 of that surah.
        final text = lines.skip(i + 1).whereType<TextLine>().first;
        expect(text.segments.first.ayah.sura, l.sura, reason: 'page $p');
        expect(text.segments.first.ayah.ayah, 1, reason: 'page $p');
      }
    }
  });

  test('well-known pages', () {
    expect(q.pageOf(q.ayah(1, 1)!), 1);
    expect(q.pageOf(q.ayah(2, 1)!), 2);
    expect(q.pageOf(q.ayah(38, 1)!), 453); // Sad
    expect(q.pageOf(q.ayah(67, 1)!), 562); // Al-Mulk
    expect(q.pageOf(q.ayah(114, 6)!), 604);
  });

  test('only the lines printed short are centred; every other line is justified edge to edge', () {
    final qw = QuranData.parse((
      File('assets/quran/hafs.json').readAsStringSync(),
      File('assets/quran/layout.json').readAsStringSync(),
    ))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());
    final centred = <String>[
      for (var p = 3; p <= QuranData.pageCount; p++)
        for (final i in centredLines(qw, p)) '$p:${i + 1}',
    ];
    // A surah's short last line before the next surah, and the short lines
    // of the last pages, as in the printed Madani mushaf (page:line).
    expect(centred, [
      '528:9', '534:6', '545:6', '593:2', '594:5', '600:10', '602:5', '602:15', //
      '603:10', '603:15', '604:4', '604:9', '604:14', '604:15',
    ]);
    // The first two pages are centred throughout, as printed.
    for (final p in [1, 2]) {
      final text = [
        for (var i = 0; i < qw.lines(p).length; i++)
          if (qw.lines(p)[i] is TextLine) i,
      ];
      expect(centredLines(qw, p), text.toSet(), reason: 'page $p');
    }
  });
}
