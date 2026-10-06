import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Ayah {
  const Ayah(this.sura, this.ayah, this.page, this.juz, this.lineStart, this.lineEnd, this.text);

  final int sura;
  final int ayah;
  final int page;
  final int juz;
  final int lineStart;
  final int lineEnd;

  /// KFGQPC text, ending with the ayah number (drawn as an ayah marker by
  /// the KFGQPC font).
  final String text;

  /// The text without its trailing ayah number, for copying and sharing.
  String get plain => text.replaceAll(RegExp(r'[\s ][٠-٩]+$'), '');
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

  String name(bool arabic) => arabic ? 'سورة $ar' : en;
}

/// The whole Quran (KFGQPC Hafs v18), loaded once from assets.
class QuranData {
  QuranData(this.suras, this.ayahs) {
    for (var i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      _index['${a.sura}:${a.ayah}'] = i;
      (_pages[a.page - 1]).add(a);
    }
  }

  final List<Sura> suras;
  final List<Ayah> ayahs;
  final _index = <String, int>{};
  final _pages = List.generate(604, (_) => <Ayah>[]);

  static const pageCount = 604;

  Ayah? ayah(int sura, int ayah) {
    final i = _index['$sura:$ayah'];
    return i == null ? null : ayahs[i];
  }

  List<Ayah> range(int sura, int from, int to) => [for (var a = from; a <= to; a++) ?ayah(sura, a)];

  List<Ayah> page(int p) => _pages[(p - 1).clamp(0, pageCount - 1)];

  Sura sura(int n) => suras[n - 1];

  /// Basmala text, taken from al-Fatihah 1 (without its number).
  String get basmala => ayahs.first.plain;

  static QuranData parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final suras = <Sura>[];
    final sl = j['suras'] as List;
    for (var i = 0; i < sl.length; i++) {
      final s = sl[i] as List;
      suras.add(Sura(i + 1, s[0] as String, s[1] as String, s[2] as int, s[3] as int, s[4] as int));
    }
    final ayahs = [
      for (final a in (j['ayahs'] as List).cast<List>())
        Ayah(a[0] as int, a[1] as int, a[2] as int, a[3] as int, a[4] as int, a[5] as int, a[6] as String),
    ];
    return QuranData(suras, ayahs);
  }
}

final quranProvider = FutureProvider<QuranData>((ref) async {
  final raw = await rootBundle.loadString('assets/quran/hafs.json');
  return compute(QuranData.parse, raw);
});
