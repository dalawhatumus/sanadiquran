import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the tests share: the mushaf data, the app's fonts, saved settings
/// for a signed-in person, and starting the app on a typical phone.

/// The mushaf, read straight from the assets (the app's own loader uses an
/// isolate, which widget tests can't wait for).
final testQuran = QuranData.parse((
  File('assets/quran/hafs.json').readAsStringSync(),
  File('assets/quran/layout.json').readAsStringSync(),
))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());

/// Loads the app's real fonts, so text measures as it does on a phone.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(rootBundle.load(f));
    }
    await loader.load();
  }

  await load('Tajawal', ['assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf']);
  await load('Montserrat', ['assets/fonts/Montserrat-Medium.ttf', 'assets/fonts/Montserrat-Bold.ttf']);
  await load('NotoNaskhArabic', [
    'assets/fonts/NotoNaskhArabic-Regular.ttf',
    'assets/fonts/NotoNaskhArabic-Medium.ttf',
    'assets/fonts/NotoNaskhArabic-Bold.ttf',
  ]);
  await load('KFGQPC', ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
}

/// Saved settings (`settings.v2`) for someone signed in who has finished
/// signing up. [sessions] null leaves it out (a first visit).
String userSettings({
  String locale = 'en',
  String role = 'student',
  String gender = 'female',
  String name = 'Fatima',
  String? teacherStatus = 'approved',
  int? sessions = 2,
  Map<String, Object?> extra = const {},
}) => jsonEncode({
  'locale': locale,
  'signedIn': true,
  'role': role,
  'gender': gender,
  'name': name,
  'permissionsDone': true,
  'ageGroup': '25-34',
  'nationality': 'SA',
  'phone': '+966500000001',
  'tourDone': true,
  'teacherStatus': ?teacherStatus,
  'sessions': ?sessions,
  ...extra,
});

/// Starts Sanadi as on a typical budget phone (360×780, animations off so
/// long names don't scroll forever), with [prefs] saved on it, online, and
/// [overrides]. Waits past the splash screen.
Future<(ProviderContainer, SharedPreferences)> startApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  List<Override> overrides = const [],
  bool online = true,
  double? textScale,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  if (textScale != null) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  SharedPreferences.setMockInitialValues(prefs);
  final saved = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(saved),
      onlineCheckProvider.overrideWithValue(() async => online),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
  await tester.pump(const Duration(milliseconds: 1400));
  return (container, saved);
}

/// The app's router.
GoRouter routerOf(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Navigator).first));
