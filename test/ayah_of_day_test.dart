import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/reminders.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/quran/ayah_of_day.dart';
import 'package:sanadi/features/quran/daily_ayahs.dart';
import 'package:sanadi/features/quran/mushaf_screen.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ayah of the day: the chosen ayahs, the home card, its page, the
/// notification's link and its setting.
void main() {
  final quran = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());

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
      expect(d.meaningEn.trim(), isNotEmpty);
      expect(d.meaningAr.trim(), isNotEmpty);
      // Arabic meanings are in Arabic, English ones in English.
      expect(RegExp('[a-zA-Z]').hasMatch(d.meaningAr), isFalse, reason: key);
      expect(RegExp('[ء-ي]').hasMatch(d.meaningEn), isFalse, reason: key);
      expect(ayahText(quran, d), isNotEmpty);
    }
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
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues({
        'settings.v2':
            '{"locale":"$locale","signedIn":true,"role":"student","gender":"female","name":"Fatima",'
            '"permissionsDone":true,"ageGroup":"25-34","nationality":"SA","phone":"+966500000001","tourDone":true,"sessions":2}',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onlineCheckProvider.overrideWithValue(() async => true),
          quranProvider.overrideWith((ref) async => quran),
        ],
      );
      addTearDown(container.dispose);
      final s = S(ar: locale == 'ar', female: true);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Navigator).first));
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
