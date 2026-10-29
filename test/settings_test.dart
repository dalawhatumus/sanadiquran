import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/reminders.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/athkar/dhikr_screen.dart';
import 'package:sanadi/features/settings/more_screens.dart';

import 'helpers.dart';

/// Settings: change name, athkar reminders, privacy and about.
void main() {
  for (final locale in ['en', 'ar']) {
    testWidgets('settings pages work ($locale)', (tester) async {
      final (container, prefs) = await startApp(
        tester,
        prefs: {'settings.v2': userSettings(locale: locale, teacherStatus: null)},
      );
      final s = S(ar: locale == 'ar', female: true);
      final router = routerOf(tester);
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
      Finder inSheet(Type type) => find.descendant(of: find.byType(BottomSheet), matching: find.byType(type));
      await tapText(s.remindersL);
      expect(inSheet(Switch), findsOneWidget);
      await tester.tap(inSheet(Switch));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).remindersOn, isFalse);
      await tester.tap(inSheet(Switch));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).remindersOn, isTrue);
      await tester.tap(find.text(s.morningAthkar).last);
      await tester.pumpAndSettle();
      final ok = find.text(MaterialLocalizations.of(tester.element(inSheet(Switch))).okButtonLabel);
      await tester.tap(ok);
      await tester.pumpAndSettle();
      expect(prefs.getInt('reminder.morning'), 7 * 60);
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(inSheet(Switch), findsNothing);

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
      if (launched) Reminders.instance.launchRouteForTest = '/athkar/morning';
      await startApp(tester, prefs: {'settings.v2': userSettings(teacherStatus: null)});
      await tester.pumpAndSettle();
      final router = routerOf(tester);
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
