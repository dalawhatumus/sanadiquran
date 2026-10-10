import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/quran/mushaf_page.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:sanadi/features/quran/recitation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uses every control of the mushaf screen the way a reader would.
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
    await _loadFont('NotoNaskhArabic', ['assets/fonts/NotoNaskhArabic-Medium.ttf']);
    await _loadFont('KFGQPC', ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
  });

  for (final locale in ['en', 'ar']) {
    testWidgets('mushaf controls all work ($locale)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'settings.v2':
            '{"locale":"$locale","signedIn":true,"role":"student","gender":"female","name":"Fatima",'
            '"permissionsDone":true,"tourDone":true,"mushafMode":"page"}',
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
      final router = GoRouter.of(tester.element(find.byType(Navigator).first));
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

      // Tapping near the left edge turns forward, near the right edge back.
      await tester.tapAt(const Offset(20, 420));
      await tester.pumpAndSettle();
      expect(shownPage(), 79);
      await tester.tapAt(const Offset(340, 420));
      await tester.pumpAndSettle();
      expect(shownPage(), 78);

      // Tapping the middle shows and hides the bars.
      await tester.pump(const Duration(seconds: 5));
      await tester.tapAt(const Offset(180, 420));
      await tester.pumpAndSettle();
      final back = find.byIcon(Icons.bookmark_border_rounded);
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
      await tester.tap(find.byIcon(Icons.menu_book_rounded).hitTestable().first);
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).mushafMode, MushafMode.page);
      expect(shownPage(), 300);

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
