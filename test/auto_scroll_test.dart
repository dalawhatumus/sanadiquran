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
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/quran/large_text_view.dart';
import 'package:sanadi/features/quran/mushaf_screen.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auto scroll in the mushaf: the text moves by itself in large text, pages
/// turn by themselves in mushaf pages, at the chosen speed.
void main() {
  final quran = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());
  const s = S(ar: false, female: true);

  setUpAll(() async {
    final loader = FontLoader('KFGQPC')..addFont(rootBundle.load('assets/fonts/quran/UthmanicHafs1Ver18.ttf'));
    await loader.load();
  });

  Future<(ProviderContainer, SharedPreferences)> open(WidgetTester tester, String mode, {int? speed}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"student","gender":"female","name":"Fatima",'
          '"permissionsDone":true,"ageGroup":"25-34","nationality":"SA","phone":"+966500000001","tourDone":true,'
          '"mushafMode":"$mode"}',
      'autoScrollSpeed': ?speed,
      'mushafHint': true,
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
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Navigator).first)).push(Routes.mushafAt(page: 77));
    await tester.pumpAndSettle();
    return (container, prefs);
  }

  Future<void> run(WidgetTester tester, Duration d) async {
    for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 100)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('large text moves by itself; slower, faster, pause and stop', (tester) async {
    final (container, prefs) = await open(tester, 'large');
    double offset() => tester
        .state<ScrollableState>(
          find.descendant(of: find.byType(LargeTextView), matching: find.byType(Scrollable)).first,
        )
        .position
        .pixels;

    await tester.tap(find.byTooltip(s.autoScroll));
    await tester.pump();
    final start = offset();
    await run(tester, const Duration(seconds: 2));
    // Speed 3: 14 pixels a second.
    expect(offset() - start, closeTo(2 * autoScrollPixels(3), 4));

    // A tap shows the controls (the text keeps moving).
    await tester.tapAt(const Offset(180, 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(s.speedN(3)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('auto-faster')));
    await tester.pump();
    expect(prefs.getInt('autoScrollSpeed'), 4);
    expect(find.text(s.speedN(4)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('auto-slower')));
    await tester.tap(find.byKey(const ValueKey('auto-slower')));
    await tester.pump();
    expect(container.read(autoScrollSpeedProvider), 2);

    await tester.tap(find.byKey(const ValueKey('auto-pause')));
    await tester.pump();
    final paused = offset();
    await run(tester, const Duration(seconds: 1));
    expect(offset(), paused);
    await tester.tap(find.byKey(const ValueKey('auto-pause')));
    await run(tester, const Duration(seconds: 1));
    expect(offset(), greaterThan(paused));

    await tester.tap(find.byKey(const ValueKey('auto-stop')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('auto-scroll-bar')), findsNothing);
    final stopped = offset();
    await run(tester, const Duration(seconds: 1));
    expect(offset(), stopped);
    expect(find.byTooltip(s.autoScroll), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mushaf pages turn by themselves at the chosen speed', (tester) async {
    final (container, _) = await open(tester, 'page', speed: 10);
    await tester.tap(find.byTooltip(s.autoScroll));
    await tester.pump();
    // (Opening at a page doesn't count as reading it until it changes.)
    expect(container.read(lastPageProvider), isNot(78));
    await run(tester, autoTurnAfter(10) - const Duration(seconds: 2));
    expect(container.read(lastPageProvider), isNot(78));
    await run(tester, const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(container.read(lastPageProvider), 78);

    // Once stopped, the page stays.
    await tester.tapAt(const Offset(180, 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('auto-stop')));
    await tester.pump(const Duration(milliseconds: 300));
    await run(tester, autoTurnAfter(10) + const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(container.read(lastPageProvider), 78);
  });
}
