import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/reminders.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/quran/ayah_of_day.dart';
import 'package:sanadi/features/quran/daily_ayahs.dart';
import 'package:sanadi/features/quran/mushaf_screen.dart';
import 'package:sanadi/features/quran/quran_data.dart';

import 'helpers.dart';

/// Ayah of the day: the chosen ayahs, the home card, its page, the
/// notification's link and its setting.
void main() {
  final quran = testQuran;

  test('every daily ayah exists, with a theme and meaning in both languages', () {
    expect(dailyAyahs.length, greaterThanOrEqualTo(40));
    final seen = <String>{};
    for (final d in dailyAyahs) {
      final key = '${d.sura}:${d.from}';
      expect(seen.add(key), isTrue, reason: 'twice: $key');
      expect(d.from, lessThanOrEqualTo(d.to));
      for (var a = d.from; a <= d.to; a++) {
        expect(quran.ayah(d.sura, a), isNotNull, reason: '${d.sura}:$a');
      }
      expect(d.themeEn.trim(), isNotEmpty);
      expect(d.themeAr.trim(), isNotEmpty);
      expect(d.translationEn.trim(), isNotEmpty);
      expect(d.tafsirAr.trim(), isNotEmpty);
      // Only the tafsir itself (no surah introductions from the copy it came from).
      expect(d.tafsirAr, isNot(contains('تسمية السورة')), reason: key);
      expect(d.tafsirAr, isNot(contains('[التفسير]')), reason: key);
      // Arabic meanings are in Arabic, English ones in English.
      expect(RegExp('[a-zA-Z]').hasMatch(d.tafsirAr), isFalse, reason: key);
      expect(RegExp('[ء-ي]').hasMatch(d.translationEn), isFalse, reason: key);
      // Each ayah ends as Saheeh International prints it.
      expect(d.translationEn, matches(RegExp(r'''[.!?"')]$''')), reason: key);
      expect(ayahText(quran, d), isNotEmpty);
    }
  });

  test('the translations are the trusted ones, with their source named', () {
    final hearts = dailyAyahs.firstWhere((d) => d.sura == 13 && d.from == 28);
    expect(
      hearts.translationEn,
      'Those who have believed and whose hearts are assured by the remembrance of Allah. '
      'Unquestionably, by the remembrance of Allah hearts are assured.',
    );
    expect(hearts.tafsirAr, startsWith('ويهدي الذين تسكن قلوبهم بتوحيد الله وذكره'));
    final ease = dailyAyahs.firstWhere((d) => d.sura == 94);
    expect(
      ease.translationEn,
      'For indeed, with hardship [will be] ease. (5) Indeed, with hardship [will be] ease. (6)',
    );
    // A joint explanation of two ayahs is shown once.
    expect(ease.tafsirAr, 'فلا يَثْنِكَ أذى أعدائك عن نشر الرسالة؛ فإن مع الضيق فرجًا، إن مع الضيق فرجًا.');
    expect(const S(ar: false, female: true).ayahMeaningNote, contains('Saheeh International'));
    expect(const S(ar: true, female: true).ayahMeaningNote, contains('التفسير الميسّر'));
    expect(const S(ar: true, female: true).ayahMeaningNote, contains('مجمع الملك فهد'));
  });

  test('one ayah a day, the same all day, a different one tomorrow', () {
    final morning = dayNumber(DateTime(2026, 10, 15, 0, 5));
    expect(dayNumber(DateTime(2026, 10, 15, 23, 55)), morning);
    expect(dayNumber(DateTime(2026, 10, 16, 0, 5)), morning + 1);
    expect(ayahForDay(morning), isNot(same(ayahForDay(morning + 1))));
    expect(ayahPlainText(quran, dailyAyahs[1]), contains('﴿٥﴾'));
  });

  test('a notification may open a day\'s ayah, and nothing else there', () {
    expect(Reminders.safeRoute('/ayah?day=1018'), '/ayah?day=1018');
    expect(Reminders.safeRoute('/ayah?day=abc'), isNull);
    expect(Reminders.safeRoute('/ayah?day=1&x=2'), isNull);
    expect(Reminders.safeRoute('/ayah'), isNull);
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('the home card opens the ayah, then the mushaf ($locale)', (tester) async {
      final (container, prefs) = await startApp(
        tester,
        prefs: {'settings.v2': userSettings(locale: locale, teacherStatus: null)},
        overrides: [quranProvider.overrideWith((ref) async => quran)],
      );
      final s = S(ar: locale == 'ar', female: true);
      await tester.pumpAndSettle();
      final router = routerOf(tester);
      expect(router.state.matchedLocation, Routes.studentHome);

      final today = ayahForDay(dayNumber(DateTime.now()));
      final card = find.byKey(const ValueKey('ayah-of-day'));
      await tester.scrollUntilVisible(card, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.descendant(of: card, matching: find.text(today.theme(s.ar))), findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.byType(AyahOfDayScreen), findsOneWidget);
      expect(find.text(today.meaning(s.ar)), findsOneWidget);
      expect(find.text(s.ayahMeaningNote), findsOneWidget);
      await tester.tap(find.text(s.openInQuran));
      await tester.pumpAndSettle();
      expect(find.byType(MushafScreen), findsOneWidget);
      final mushaf = tester.widget<MushafScreen>(find.byType(MushafScreen));
      expect((mushaf.sura, mushaf.ayah), (today.sura, today.from));
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      // Tapping the notification opens that day's ayah over home.
      Reminders.instance.onOpen!(Routes.ayahOfDay(3));
      await tester.pumpAndSettle();
      expect(find.text(ayahForDay(3).meaning(s.ar)), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.studentHome);

      // The setting: off, on, and a new time.
      router.push(Routes.settings);
      await tester.pumpAndSettle();
      final row = find.text(s.ayahOfDay);
      await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      final sw = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Switch));
      expect(container.read(ayahOfDayProvider).on, isTrue);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      expect(container.read(ayahOfDayProvider).on, isFalse);
      expect(prefs.getBool('ayahOfDay.on'), isFalse);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(s.ayahTimeL)));
      await tester.pumpAndSettle();
      final ok = MaterialLocalizations.of(tester.element(sw)).okButtonLabel;
      await tester.tap(find.text(ok));
      await tester.pumpAndSettle();
      expect(prefs.getInt('ayahOfDay.time'), 9 * 60);
      expect(tester.takeException(), isNull);
    });
  }
}
