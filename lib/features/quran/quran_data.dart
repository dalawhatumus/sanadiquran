import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Ayah {
  Ayah(this.sura, this.ayah, this.page, this.juz, this.text);

  final int sura;
  final int ayah;

  /// The page the ayah starts on (KFGQPC data).
  final int page;
  final int juz;

  /// KFGQPC text, ending with the ayah number (drawn as an ayah marker by
  /// the KFGQPC font).
  final String text;

  /// The ayah number in Arabic-Indic digits, as written in the text.
  String get number => text.substring(text.lastIndexOf(' ') + 1);

  /// The text without its trailing ayah number, for copying and sharing.
  String get plain => text.substring(0, text.lastIndexOf(' '));

  /// The words of the ayah, without the number. A stand-alone hizb mark
  /// (۞) is kept with the word after it.
  late final List<String> words = _splitWords();

  List<String> _splitWords() {
    final out = <String>[];
    for (final w in plain.split(' ')) {
      if (out.isNotEmpty && !_hasLetter(out.last)) {
        out[out.length - 1] = '${out.last} $w';
      } else {
        out.add(w);
      }
    }
    return out;
  }

  static final _letter = RegExp('[ء-يٱ]');
  static bool _hasLetter(String s) => _letter.hasMatch(s);

  late final String key = '$sura:$ayah';
}

@immutable
class Sura {
  const Sura(this.number, this.ar, this.en, this.count, this.page, this.juz);

  final int number;
  final String ar;
  final String en;
  final int count;
  final int page;
  final int juz;

  /// Revealed in Madinah (Tanzil metadata); the rest are Makki.
  bool get madani => _madani.contains(number);

  static const _madani = {
    2,
    3,
    4,
    5,
    8,
    9,
    13,
    22,
    24,
    33,
    47,
    48,
    49,
    55,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    76,
    98,
    99,
    110,
  };

  String name(bool arabic) => arabic ? 'سورة $ar' : en;
}

/// One line of a 15-line mushaf page.
sealed class PageLine {
  const PageLine();
}

class HeaderLine extends PageLine {
  const HeaderLine(this.sura);
  final int sura;
}

class BasmalaLine extends PageLine {
  const BasmalaLine();
}

/// Part of an ayah on a line: words [from, to] (1-based). [endsAyah] means
/// the ayah's number marker closes this segment.
@immutable
class Segment {
  const Segment(this.ayah, this.from, this.to, this.endsAyah);
  final Ayah ayah;
  final int from;
  final int to;
  final bool endsAyah;
}

class TextLine extends PageLine {
  TextLine(this.segments);
  final List<Segment> segments;

  /// The line as one string: words and ayah numbers, single spaces between.
  late final String text = [
    for (final s in segments) ...[...s.ayah.words.sublist(s.from - 1, s.to), if (s.endsAyah) s.ayah.number],
  ].join(' ');

  /// Number of spaces in [text] (the gaps that justify the line).
  late final int spaces = ' '.allMatches(text).length;
}

@immutable
class JuzStart {
  const JuzStart(this.juz, this.sura, this.ayah, this.page);
  final int juz;
  final int sura;
  final int ayah;
  final int page;
}

/// The whole Quran (KFGQPC Hafs v18) with the Madani 15-line page layout,
/// loaded once from assets and kept in memory.
class QuranData {
  QuranData(this.suras, this.ayahs, List<List<PageLine>> layout) : _layout = layout {
    for (var i = 0; i < ayahs.length; i++) {
      _index[ayahs[i].key] = i;
    }
    for (var p = 0; p < layout.length; p++) {
      for (final line in layout[p]) {
        if (line is TextLine) {
          for (final s in line.segments) {
            _pageOf.putIfAbsent(s.ayah.key, () => p + 1);
          }
        }
      }
    }
    var juz = 0;
    for (final a in ayahs) {
      if (a.juz != juz) {
        juz = a.juz;
        juzStarts.add(JuzStart(juz, a.sura, a.ayah, pageOf(a)));
      }
    }
  }

  final List<Sura> suras;
  final List<Ayah> ayahs;
  final List<List<PageLine>> _layout;
  final _index = <String, int>{};
  final _pageOf = <String, int>{};
  final juzStarts = <JuzStart>[];

  static const pageCount = 604;

  Ayah? ayah(int sura, int ayah) {
    final i = _index['$sura:$ayah'];
    return i == null ? null : ayahs[i];
  }

  /// The ayah after [a] in the mushaf, or null after the last.
  Ayah? after(Ayah a) {
    final i = _index[a.key];
    return i == null || i + 1 >= ayahs.length ? null : ayahs[i + 1];
  }

  List<Ayah> range(int sura, int from, int to) => [for (var a = from; a <= to; a++) ?ayah(sura, a)];

  Sura sura(int n) => suras[n - 1];

  /// The 15 (or fewer) lines of page [p].
  List<PageLine> lines(int p) => _layout[(p - 1).clamp(0, pageCount - 1)];

  /// The page an ayah starts on in the mushaf layout.
  int pageOf(Ayah a) => _pageOf[a.key] ?? a.page;

  /// Ayahs that start or continue on page [p], in order.
  List<Ayah> page(int p) {
    final seen = <String>{};
    return [
      for (final line in lines(p))
        if (line is TextLine)
          for (final s in line.segments)
            if (seen.add(s.ayah.key)) s.ayah,
    ];
  }

  /// First ayah on page [p] (for the page header).
  Ayah firstOn(int p) => page(p).first;

  int juzOfPage(int p) => firstOn(p).juz;

  /// Width of every mushaf line in the KFGQPC font at [widthRefSize], with
  /// ordinary spaces (0 for frames and basmalas). Measured ahead of time by
  /// tools/quran/line_widths_test.dart so pages never measure text.
  List<List<double>>? lineWidths;
  double widthRefSize = 20;

  /// Width of one space at [widthRefSize].
  double spaceWidth = 0;

  /// How many gaps on each line stretch with word spacing.
  List<List<int>>? lineGaps;

  void attachWidths(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    widthRefSize = (j['refSize'] as num).toDouble();
    spaceWidth = (j['space'] as num).toDouble();
    lineWidths = [
      for (final p in (j['pages'] as List).cast<List>()) [for (final w in p.cast<num>()) w.toDouble()],
    ];
    lineGaps = [for (final p in (j['gaps'] as List).cast<List>()) p.cast<int>()];
  }

  /// Basmala text, taken from al-Fatihah 1 (without its number).
  String get basmala => ayahs.first.plain;

  static QuranData parse((String, String) raw) {
    final j = jsonDecode(raw.$1) as Map<String, dynamic>;
    final suras = <Sura>[];
    final sl = j['suras'] as List;
    for (var i = 0; i < sl.length; i++) {
      final s = sl[i] as List;
      suras.add(Sura(i + 1, s[0] as String, s[1] as String, s[2] as int, s[3] as int, s[4] as int));
    }
    final ayahs = [
      for (final a in (j['ayahs'] as List).cast<List>())
        Ayah(a[0] as int, a[1] as int, a[2] as int, a[3] as int, a[6] as String),
    ];
    final byKey = {for (final a in ayahs) a.key: a};
    final pages = (jsonDecode(raw.$2) as Map<String, dynamic>)['pages'] as List;
    final layout = [
      for (final page in pages.cast<List>())
        [
          for (final l in page.cast<List>())
            switch (l[0]) {
              'h' => HeaderLine(l[1] as int),
              'b' => const BasmalaLine(),
              _ => TextLine([
                for (final s in (l[1] as List).cast<List>())
                  () {
                    final a = byKey['${s[0]}:${s[1]}']!;
                    final n = a.words.length;
                    final to = s[3] as int;
                    return Segment(a, s[2] as int, to > n ? n : to, to > n);
                  }(),
              ]),
            },
        ],
    ];
    return QuranData(suras, ayahs, layout);
  }
}

final quranProvider = FutureProvider<QuranData>((ref) async {
  final hafs = await rootBundle.loadString('assets/quran/hafs.json');
  final layout = await rootBundle.loadString('assets/quran/layout.json');
  final widths = await rootBundle.loadString('assets/quran/line_widths.json');
  return (await compute(QuranData.parse, (hafs, layout)))..attachWidths(widths);
});
