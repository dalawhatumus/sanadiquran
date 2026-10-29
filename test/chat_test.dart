import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/chat.dart';
import 'package:sanadi/core/router.dart';

import 'helpers/layout_checks.dart';

import 'helpers.dart';

/// Uses chat the way a person would, on the demo backend: unread badge,
/// opening a chat, sending, deleting, reporting, blocking and unblocking.

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['en', 'ar']) {
    testWidgets('chat works from start to finish ($locale)', (tester) async {
      final (container, prefs) = await startApp(
        tester,
        prefs: {'settings.v2': userSettings(locale: locale, teacherStatus: null)},
      );
      final router = routerOf(tester);
      router.go(Routes.studentTeachers);
      await tester.pumpAndSettle();

      // One unread message: a badge on the Teachers tab and on its Messages
      // button, which opens the conversations.
      expect(container.read(unreadTotalProvider), 1);
      expect(find.byType(Badge), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('messages-button')));
      await tester.pumpAndSettle();
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
