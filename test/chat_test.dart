import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/backend/chat.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/layout_checks.dart';

/// Uses chat the way a person would, on the demo backend: unread badge,
/// opening a chat, sending, deleting, reporting, blocking and unblocking.
Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('Tajawal', ['assets/fonts/Tajawal-Medium.ttf', 'assets/fonts/Tajawal-Bold.ttf']);
    await _loadFont('Montserrat', ['assets/fonts/Montserrat-Medium.ttf', 'assets/fonts/Montserrat-Bold.ttf']);
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('chat works from start to finish ($locale)', (tester) async {
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
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
      await tester.pump(const Duration(milliseconds: 1400));
      final router = GoRouter.of(tester.element(find.byType(Navigator).first));
      router.go(Routes.studentMessages);
      await tester.pumpAndSettle();

      // One unread message: badge on the tab and on the conversation.
      expect(container.read(unreadTotalProvider), 1);
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('Aisha Rahman'), findsOneWidget);
      expect(overlappingText(tester), isEmpty);

      // Opening the chat reads it.
      await tester.tap(find.text('Aisha Rahman'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(container.read(unreadTotalProvider), 0);
      expect(find.byType(Badge), findsNothing);
      expect(overlappingText(tester), isEmpty);

      // The microphone shows until something is typed, then Send.
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
      await tester.enterText(find.byType(TextField), 'Can we review Al-Mulk tomorrow?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Can we review Al-Mulk tomorrow?'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

      // Long-press your own message to delete it.
      await tester.longPress(find.text('Can we review Al-Mulk tomorrow?'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, locale == 'ar' ? 'حذف' : 'Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Can we review Al-Mulk tomorrow?'), findsNothing);

      // Someone else's message can't be deleted.
      await tester.longPress(find.textContaining('Al-Mulk is getting stronger'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Report, and block at the same time.
      await tester.tap(find.byIcon(Icons.flag_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text(locale == 'ar' ? 'كلام غير لائق' : 'Inappropriate words'));
      await tester.pump();
      await tester.tap(find.textContaining(locale == 'ar' ? 'حظر Aisha Rahman أيضًا' : 'Also block'));
      await tester.pump();
      await tester.ensureVisible(find.text(locale == 'ar' ? 'إرسال البلاغ' : 'Send report'));
      await tester.tap(find.text(locale == 'ar' ? 'إرسال البلاغ' : 'Send report'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await tester.tap(find.text(locale == 'ar' ? 'تمّ' : 'Done'));
      await tester.pumpAndSettle();

      // Blocked: no way to send; unblock brings the composer back.
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining(locale == 'ar' ? 'لقد حظرتِ' : 'You blocked'), findsOneWidget);
      await tester.tap(find.text(locale == 'ar' ? 'إلغاء الحظر' : 'Unblock'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      // Voice notes show their length; the header offers a call.
      expect(find.text(locale == 'ar' ? '٠:٤٢' : '0:42'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go(Routes.studentHome);
      await tester.pump(const Duration(seconds: 6));
    });
  }
}
