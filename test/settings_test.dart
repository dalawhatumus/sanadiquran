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
import 'package:sanadi/features/athkar/dhikr_screen.dart';
import 'package:sanadi/features/settings/more_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings: change name, athkar reminders, privacy and about.
void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets('settings pages work ($locale)', (tester) async {
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
            '"permissionsDone":true,"tourDone":true,"sessions":2}',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onlineCheckProvider.overrideWithValue(() async => true),
        ],
      );
      addTearDown(container.dispose);
      final s = S(ar: locale == 'ar', female: true);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
      await tester.pump(const Duration(milliseconds: 1400));
      final router = GoRouter.of(tester.element(find.byType(Navigator).first));
      router.go(Routes.studentHome);
      await tester.pumpAndSettle();
      router.push(Routes.settings);
      await tester.pumpAndSettle();

      Future<void> tapText(String text) async {
        final f = find.text(text).hitTestable(at: Alignment.center);
        await tester.ensureVisible(find.text(text).first);
        await tester.pumpAndSettle();
        await tester.tap(f.evaluate().isEmpty ? find.text(text).first : f.first);
        await tester.pumpAndSettle();
      }

      // Change name: an empty name is refused; a new one is saved.
      await tapText(s.changeName);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(s.save));
      await tester.pumpAndSettle();
      expect(find.text(s.nameEmpty), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Fatima Zahra');
      await tester.tap(find.text(s.save));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(container.read(settingsProvider).name, 'Fatima Zahra');

      // Athkar reminders: turn off and on, and confirm a time.
      await tapText(s.remindersL);
      expect(find.byType(Switch), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).remindersOn, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).remindersOn, isTrue);
      await tester.tap(find.text(s.morningAthkar).last);
      await tester.pumpAndSettle();
      final ok = find.text(MaterialLocalizations.of(tester.element(find.byType(Switch))).okButtonLabel);
      await tester.tap(ok);
      await tester.pumpAndSettle();
      expect(prefs.getInt('reminder.morning'), 7 * 60);
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);

      // Privacy policy and About open, and come back.
      await tapText(s.privacyTitle);
      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(find.text(s.privacySections.first.$1), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tapText(s.aboutTitle);
      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text(s.acknowledgements.first.$1), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      // Demo mode has no account to delete or people to unblock.
      expect(find.text(s.deleteAccount), findsNothing);
      expect(find.text(s.blockedTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final launched in [false, true]) {
    testWidgets('a tapped athkar reminder opens over home, and Back returns (launched: $launched)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      SharedPreferences.setMockInitialValues({
        'settings.v2':
            '{"locale":"en","signedIn":true,"role":"student","gender":"female","name":"Fatima",'
            '"permissionsDone":true,"tourDone":true,"sessions":2}',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onlineCheckProvider.overrideWithValue(() async => true),
        ],
      );
      addTearDown(container.dispose);
      if (launched) Reminders.instance.launchRouteForTest = '/athkar/morning';
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(Navigator).first));
      if (!launched) {
        expect(router.state.matchedLocation, Routes.studentHome);
        Reminders.instance.onOpen!('/athkar/evening');
        await tester.pumpAndSettle();
      }
      expect(find.byType(DhikrScreen), findsOneWidget);
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(DhikrScreen), findsNothing);
      expect(router.state.matchedLocation, Routes.studentHome);
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
