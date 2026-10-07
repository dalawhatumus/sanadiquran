import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
