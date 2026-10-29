import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/quran/mushaf_screen.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:sanadi/features/quran/surah_index_screen.dart';
import 'package:sanadi/features/quran/surah_search.dart';

import 'helpers.dart';

/// The surah search finds a surah however its name is typed.
void main() {
  final q = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ));
  int? first(String query) => searchSurahs(q, query).firstOrNull?.number;

  final cases = <int, List<String>>{
    114: [
      'surah al-nas',
      'Surah Al Nas',
      'surah alnas',
      'an nas',
      'annas',
      'An-Nās',
      'naas',
      'Nas',
      'al-naas',
      'mankind',
    ],
    36: ['yaseen', 'yasin', 'ya sin', 'Ya-Seen', 'surah yasin'],
    55: ['rehman', 'ar rahman', 'al-rahman', 'arrahman', 'Rahmaan'],
    18: ['kahaf', 'kahf', 'al kahf', 'surat al-kahf', 'the cave'],
    2: ['baqara', 'al baqarah', 'bakara', 'baqarah', 'the cow'],
    1: ['fatiha', 'fatihah', 'alfatiha', 'al-faatiha', 'the opening'],
    112: ['ikhlas', 'iklas', 'ikhlaas', 'al-ikhlas'],
    67: ['mulk', 'al mulk', 'tabarak'],
    62: ['jumuah', 'jumma', 'friday'],
    3: ['imran', 'al imran', 'aal imran', 'ale imran'],
    73: ['muzammil', 'muzzamil', 'al-muzzammil'],
    74: ['mudathir', 'muddaththir'],
    99: ['zalzalah', 'zilzal'],
    78: ['naba', 'amma'],
  };
  cases.forEach((number, queries) {
    for (final query in queries) {
      test('"$query" finds surah $number', () => expect(first(query), number));
    }
  });

  test('Arabic, with or without "سورة", "ال" and vowel marks', () {
    for (final query in ['الناس', 'ناس', 'سورة الناس', 'سوره الناس', 'النّاس']) {
      expect(first(query), 114, reason: query);
    }
    for (final query in ['الفاتحه', 'فاتحة', 'الفَاتِحة']) {
      expect(first(query), 1, reason: query);
    }
    expect(first('يس'), 36);
    expect(first('تبارك'), 67);
    expect(first('البقره'), 2);
  });

  test('by number, in either kind of digits', () {
    expect(first('114'), 114);
    expect(first('١١٤'), 114);
    expect(first('2'), 2);
    expect(searchSurahs(q, '115'), isEmpty);
  });

  test('nothing for nonsense or an empty box', () {
    expect(searchSurahs(q, 'xyzq'), isEmpty);
    expect(searchSurahs(q, '   '), isEmpty);
  });

  test('every surah finds itself by its own names', () {
    for (final s in q.suras) {
      expect(first(s.en), s.number, reason: s.en);
      expect(first(s.ar), s.number, reason: s.ar);
    }
  });

  testWidgets('the Quran tab search finds a surah and opens it', (tester) async {
    await startApp(
      tester,
      prefs: {'settings.v2': userSettings(teacherStatus: null, sessions: null)},
      overrides: [quranProvider.overrideWith((ref) async => q)],
    );
    const s = S(ar: false, female: true);
    await tester.pumpAndSettle();
    final router = routerOf(tester);
    router.go(Routes.studentQuran);
    await tester.pumpAndSettle();
    final box = find.byKey(const ValueKey('surah-search'));
    Finder tiles() => find.byType(SurahTile);

    await tester.enterText(box, 'surah alnas');
    await tester.pumpAndSettle();
    expect(tester.widget<SurahTile>(tiles().first).sura.number, 114);
    expect(find.text(s.surahs), findsNothing); // the tabs give way to the results

    await tester.enterText(box, 'zzqx');
    await tester.pumpAndSettle();
    expect(find.text(s.noSurahFound), findsOneWidget);

    // A number: that surah, and that page.
    await tester.enterText(box, '50');
    await tester.pumpAndSettle();
    expect(tester.widget<SurahTile>(tiles().first).sura.number, 50);
    expect(find.text(s.page(50)), findsOneWidget);

    await tester.enterText(box, 'yaseen');
    await tester.pumpAndSettle();
    await tester.tap(tiles().first);
    await tester.pumpAndSettle();
    expect(tester.widget<MushafScreen>(find.byType(MushafScreen)).sura, 36);
    router.pop();
    await tester.pumpAndSettle();

    // Clearing brings the surah list back.
    await tester.tap(find.byTooltip(s.clear));
    await tester.pumpAndSettle();
    expect(find.text(s.surahs), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}
