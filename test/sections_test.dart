import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/features/athkar/athkar_data.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:sanadi/widgets/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/layout_checks.dart';

/// Goes through the whole Quran section (every surah and juz' in the lists,
/// bookmarks) and every dhikr of every athkar set, in English and Arabic at
/// 100% and 200% text, checking that nothing overflows, no word is split
/// across lines and no text sits on top of other text.
Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

void main() {
  final quran = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());

  setUpAll(() async {
    await _loadFont('Tajawal', ['assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf']);
    await _loadFont('Montserrat', ['assets/fonts/Montserrat-Medium.ttf', 'assets/fonts/Montserrat-Bold.ttf']);
    await _loadFont('NotoNaskhArabic', [
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
      'assets/fonts/NotoNaskhArabic-Medium.ttf',
      'assets/fonts/NotoNaskhArabic-Bold.ttf',
    ]);
    await _loadFont('KFGQPC', ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
  });

  Future<GoRouter> open(WidgetTester tester, String locale, double scale) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"$locale","signedIn":true,"role":"student","gender":"female","name":"Fatima Ahmed",'
          '"permissionsDone":true,"tourDone":true,"sessions":2,'
          '"bookmarks":["2:255","18:10","36:1","67:1","112:1"],"pageBookmarks":[1,50,293,604]}',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onlineCheckProvider.overrideWithValue(() async => true),
          quranProvider.overrideWith((ref) async => quran),
        ],
        child: const SanadiApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(const Duration(milliseconds: 500));
    return GoRouter.of(tester.element(find.byType(Navigator).first));
  }

  void check(WidgetTester tester, String where) {
    expect(tester.takeException(), isNull, reason: where);
    expect(brokenWords(tester), isEmpty, reason: '$where: words split across lines');
    expect(overlappingText(tester), isEmpty, reason: '$where: text on top of other text');
  }

  /// Scrolls the visible list to the end a screen at a time, checking each.
  Future<void> scrollThrough(WidgetTester tester, String where) async {
    final scrollable = find.byType(Scrollable).hitTestable().last;
    for (var i = 0; i < 400; i++) {
      check(tester, '$where (screen ${i + 1})');
      final state = tester.state<ScrollableState>(scrollable);
      final pos = state.position;
      if (pos.pixels >= pos.maxScrollExtent) return;
      pos.jumpTo((pos.pixels + pos.viewportDimension * 0.8).clamp(0, pos.maxScrollExtent));
      await tester.pump();
    }
  }

  for (final locale in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      final label = '$locale at ${(scale * 100).round()}%';

      testWidgets('Quran lists: every surah, juz\' and bookmark ($label)', (tester) async {
        final router = await open(tester, locale, scale);
        router.go(Routes.studentQuran);
        await tester.pumpAndSettle();
        await scrollThrough(tester, 'surahs');
        final tabs = find.byType(Tab);
        expect(tabs, findsNWidgets(3));
        await tester.tap(tabs.at(1));
        await tester.pumpAndSettle();
        await scrollThrough(tester, 'juz');
        await tester.tap(tabs.at(2));
        await tester.pumpAndSettle();
        await scrollThrough(tester, 'bookmarks');
      });

      testWidgets('Athkar: every dhikr of every set ($label)', (tester) async {
        final router = await open(tester, locale, scale);
        router.go(Routes.studentAthkar);
        await tester.pumpAndSettle();
        await scrollThrough(tester, 'athkar menu');
        for (final set in athkarSets) {
          router.go('${Routes.athkar}/${set.id}');
          await tester.pumpAndSettle();
          for (var i = 0; i < set.items.length; i++) {
            final where = '${set.id} #${i + 1}';
            await scrollThrough(tester, where);
            final next = find.byWidgetPredicate((w) => w is BigButton && w.trailingIcon == Arrows.forward);
            await tester.ensureVisible(next);
            await tester.tap(next);
            await tester.pumpAndSettle();
          }
          // After the last one: the "set complete" screen.
          check(tester, '${set.id} complete');
        }
      }, timeout: const Timeout(Duration(minutes: 10)));
    }
  }
}
