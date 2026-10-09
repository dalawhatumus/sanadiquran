import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, [Map<String, Object> prefs = const {}, bool online = true]) async {
  // A typical budget Android phone: 360x800 logical pixels.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  // Names that don't fit would otherwise scroll (marquee) forever.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(instance),
        onlineCheckProvider.overrideWithValue(() async => online),
      ],
      child: const SanadiApp(),
    ),
  );
  // Splash waits 1.3 s, then moves on.
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

/// Settings saved by a finished onboarding.
Map<String, Object> done({
  String role = 'student',
  String gender = 'female',
  String locale = 'en',
  String status = 'none',
}) => {
  'settings.v2':
      '{"locale":"$locale","signedIn":true,"role":"$role","gender":"$gender","name":"Fatima Ahmed","permissionsDone":true,"tourDone":true,"teacherStatus":"$status"}',
};

void main() {
  testWidgets('first launch asks for language in both languages', (tester) async {
    await pumpApp(tester);
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('اختيار اللغة'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('English student onboarding reaches the home screen', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'English');
    await tapText(tester, 'Continue · متابعة');
    expect(find.text('Recite the Quran to a teacher, anytime.'), findsOneWidget);

    await tapText(tester, 'Continue with Google');
    expect(find.text('Step 1 of 4'), findsOneWidget);
    await tapText(tester, 'Memorise and recite');
    await tapText(tester, 'Next');

    expect(find.text('Step 2 of 4'), findsOneWidget);
    await tapText(tester, 'Female');
    await tapText(tester, 'Next');

    // Name is checked when Next is tapped.
    await tapText(tester, 'Next');
    expect(find.text('Please write your name.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Fatima Ahmed');
    await tapText(tester, 'Next');

    expect(find.text('Allow the microphone'), findsOneWidget);
    await tapText(tester, 'Not now');
    expect(find.text('Allow notifications'), findsOneWidget);
    await tapText(tester, 'Not now');

    expect(find.text('Tap Recite now'), findsOneWidget);
    await tapText(tester, 'Skip');

    expect(find.text('Recite now'), findsOneWidget);
    expect(find.text('Fatima Ahmed'), findsOneWidget);
    expect(find.text('Welcome to Sanadi'), findsOneWidget);
  });

  testWidgets('Arabic is written for a female student', (tester) async {
    await pumpApp(tester, done(locale: 'ar'));
    expect(find.text('سمِّعي الآن'), findsOneWidget);
    expect(find.text('اضغطي للاتصال بمعلّمة'), findsOneWidget);
  });

  testWidgets('Arabic is written for a male student', (tester) async {
    await pumpApp(tester, done(locale: 'ar', gender: 'male'));
    expect(find.text('سمِّع الآن'), findsOneWidget);
    expect(find.text('اضغط للاتصال بمعلّم'), findsOneWidget);
  });

  testWidgets('teacher application ends on the pending home', (tester) async {
    await pumpApp(tester, {
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"teacher","gender":"female","name":"Aisha","permissionsDone":true}',
    });
    expect(find.text('Application · 1 of 5'), findsOneWidget);
    await tapText(tester, 'South Africa');
    await tapText(tester, 'English');
    await tapText(tester, 'Next');
    expect(find.text('What can you teach?'), findsOneWidget);
    await tapText(tester, 'Next');
    await tapText(tester, 'The whole Quran');
    await tapText(tester, 'Next');
    expect(find.text('Record a short sample'), findsOneWidget);
  });

  testWidgets('pending teacher sees the review screen with mushaf and athkar', (tester) async {
    await pumpApp(tester, done(role: 'teacher', status: 'pending'));
    expect(find.text('Your application is being reviewed'), findsOneWidget);
    expect(find.text('Open the mushaf'), findsOneWidget);
  });

  testWidgets('approved teacher can go away and back', (tester) async {
    await pumpApp(tester, done(role: 'teacher', status: 'approved'));
    expect(find.text("I'm available to teach"), findsOneWidget);
    await tapText(tester, "I'm available to teach");
    expect(find.text('You are away'), findsOneWidget);
  });

  testWidgets('athkar menu opens a counter that counts taps', (tester) async {
    await pumpApp(tester, done());
    await tapText(tester, 'Athkar');
    expect(find.text('Morning'), findsOneWidget);
    await tapText(tester, 'Tasbeeh');
    expect(find.text('0 / 33'), findsOneWidget);
    await tester.tap(find.text('Tap to count'));
    await tester.pump();
    expect(find.text('1 / 33'), findsOneWidget);
  });

  testWidgets('without internet, the Quran and athkar still open from the welcome screen', (tester) async {
    await pumpApp(tester, {'settings.v2': '{"locale":"en"}'}, false);
    await tapText(tester, 'Continue with Google');
    expect(find.text('No internet connection. Connect to Wi-Fi or mobile data, then try again.'), findsOneWidget);
    expect(find.text('The Quran and athkar work without internet.'), findsOneWidget);
    await tapText(tester, 'Athkar');
    expect(find.text('Morning'), findsOneWidget);
  });

  testWidgets('without internet, Recite now explains and the rest still works', (tester) async {
    await pumpApp(tester, done(), false);
    await tapText(tester, 'Recite now');
    expect(find.text('No internet'), findsOneWidget);
    expect(find.text('Needs internet'), findsOneWidget);
    await tapText(tester, 'Athkar');
    expect(find.text('Morning'), findsOneWidget);
  });
}
