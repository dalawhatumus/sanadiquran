import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/quran/mushaf_page.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:sanadi/features/quran/recitation.dart';

import 'helpers.dart';

/// Uses every control of the mushaf screen the way a reader would.

void main() {
  final quran = testQuran;

  setUpAll(loadAppFonts);

  for (final locale in ['en', 'ar']) {
    testWidgets('mushaf controls all work ($locale)', (tester) async {
      final (container, prefs) = await startApp(
        tester,
        prefs: {
          'settings.v2': userSettings(
            locale: locale,
            teacherStatus: null,
            sessions: null,
            extra: {'mushafMode': 'page'},
          ),
        },
        overrides: [quranProvider.overrideWith((ref) async => quran)],
      );
      final router = routerOf(tester);
      router.go(Routes.studentHome);
      await tester.pumpAndSettle();
      router.push(Routes.mushafAt(page: 77));
      await tester.pumpAndSettle();
      int shownPage() => tester.widget<MushafPage>(find.byType(MushafPage).hitTestable().first).page;
      int lastPage() => container.read(lastPageProvider);
      expect(shownPage(), 77);

      // A swipe from left to right turns to the next page (pages turn
      // right-to-left, like a printed mushaf); the other way goes back.
      await tester.fling(find.byType(PageView), const Offset(250, 0), 1500);
      await tester.pumpAndSettle();
      expect(shownPage(), 78);
      expect(lastPage(), 78);
      await tester.fling(find.byType(PageView), const Offset(-250, 0), 1500);
      await tester.pumpAndSettle();
      expect(shownPage(), 77);

      // Even a short, slow swipe turns the page.
      await tester.timedDragFrom(const Offset(150, 420), const Offset(60, 0), const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(shownPage(), 78, reason: 'short swipe');

      // A tap never turns the page, even near the edges (only swipes do).
      await tester.tapAt(const Offset(20, 420));
      await tester.pumpAndSettle();
      expect(shownPage(), 78);
      await tester.tapAt(const Offset(340, 420));
      await tester.pumpAndSettle();
      expect(shownPage(), 78);

      // The Quran text gets no extra letter spacing (it pulls the harakat
      // off their letters and hides the small alif).
      for (final rt in tester.widgetList<RichText>(
        find.descendant(of: find.byType(MushafPage), matching: find.byType(RichText)),
      )) {
        void check(InlineSpan span, double inherited) {
          final ls = span.style?.letterSpacing ?? inherited;
          expect(ls, 0, reason: 'letter spacing on "${span.toPlainText()}"');
          if (span is TextSpan) {
            for (final c in span.children ?? const <InlineSpan>[]) {
              check(c, ls);
            }
          }
        }

        check(rt.text, 0);
      }

      // Each tap shows or hides the bars.
      final back = find.byIcon(Icons.bookmark_border_rounded);
      final shown = back.hitTestable().evaluate().isNotEmpty;
      await tester.tapAt(const Offset(180, 420));
      await tester.pumpAndSettle();
      expect(back.hitTestable().evaluate().isNotEmpty, !shown, reason: 'a tap toggles the bars');
      if (shown) {
        await tester.tapAt(const Offset(180, 420));
        await tester.pumpAndSettle();
      }
      expect(back.hitTestable(), findsOneWidget, reason: 'bars shown after tap');

      // Bookmark this page.
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).pageBookmarks, contains(78));

      // Go to page 300 from the sheet.
      await tester.tap(find.byIcon(Icons.list_alt_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '300');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(shownPage(), 300);
      expect(lastPage(), 300);

      // Long-press an ayah: its actions appear; copy puts it on the clipboard.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      await tester.longPressAt(const Offset(180, 500));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.content_copy_rounded));
      await tester.pumpAndSettle();
      expect(copied, isNotNull);
      expect(copied!.contains('['), isTrue);

      // A student can set the ayah as her next portion.
      await tester.longPressAt(const Offset(180, 500));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.flag_rounded));
      await tester.pumpAndSettle();
      final own = container.read(ownNextPortionProvider);
      expect(own, isNotNull);
      expect(own!.$1.sura, 18, reason: 'page 300 is in Al-Kahf');
      await tester.pump(const Duration(seconds: 6)); // let the toast go
      await tester.pumpAndSettle();

      // Switch to Large text and back: the same place stays open.
      await tester.tapAt(const Offset(180, 420));
      await tester.pumpAndSettle();
      if (find.byIcon(Icons.format_size_rounded).hitTestable().evaluate().isEmpty) {
        await tester.tapAt(const Offset(180, 420));
        await tester.pumpAndSettle();
      }

      // Recitation settings: repeat each ayah three times.
      await tester.tap(find.byIcon(Icons.tune_rounded).hitTestable().first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(S(ar: locale == 'ar', female: true).repeatTimes(3)));
      await tester.pumpAndSettle();
      expect(container.read(recitationProvider).repeat, 3);
      expect(prefs.getInt('recitation.repeat'), 3);
      await tester.tapAt(const Offset(180, 40));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.format_size_rounded));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).mushafMode, MushafMode.large);
      expect(find.byType(MushafPage), findsNothing);
      expect(tester.takeException(), isNull);

      // In Large text, read on a few pages, then tap twice: the text must
      // stay exactly where it is.
      for (var i = 0; i < 8 && lastPage() == 300; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
        await tester.pumpAndSettle();
      }
      final onScreen = lastPage();
      expect(onScreen, greaterThan(300));
      final pageBox = find.byKey(ValueKey(onScreen), skipOffstage: false);
      final before = tester.getTopLeft(pageBox);
      for (var i = 0; i < 2; i++) {
        await tester.tapAt(const Offset(180, 420));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(pageBox), before, reason: 'tap ${i + 1} moved the text');
        expect(lastPage(), onScreen);
      }
      await tester.tap(find.byIcon(Icons.menu_book_rounded).hitTestable().first);
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).mushafMode, MushafMode.page);
      expect(shownPage(), onScreen, reason: 'the pages reopen where Large text was left');

      // Opening a surah from the index lands on its first page.
      router.pop();
      await tester.pumpAndSettle();
      router.push(Routes.mushafAt(sura: 18, ayah: 1));
      await tester.pumpAndSettle();
      expect(shownPage(), 293);
      router.pop();
      await tester.pumpAndSettle();
      router.push(Routes.mushafAt(sura: 114, ayah: 1));
      await tester.pumpAndSettle();
      expect(shownPage(), 604);
      router.pop();
      await tester.pump(const Duration(seconds: 6));
    });
  }
}
