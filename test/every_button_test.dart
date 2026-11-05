import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/features/call/call_controller.dart';
import 'package:sanadi/features/quran/quran_data.dart';

import 'helpers.dart';

/// Every screen, every button: each one is tapped in turn (on a fresh copy
/// of its screen) and must not crash, throw, or leave text that doesn't fit.
/// Student and teacher, English and Arabic.
void main() {
  setUpAll(loadAppFonts);

  const studentRoutes = [
    Routes.studentHome,
    Routes.studentTeachers,
    Routes.studentQuran,
    Routes.studentAthkar,
    Routes.settings,
    Routes.progress,
    Routes.messages,
    'chat:demo-chat',
    Routes.mushaf,
    Routes.about,
    Routes.privacy,
    Routes.terms,
    Routes.codeOfConduct,
    Routes.editDetails,
  ];
  const teacherRoutes = [
    Routes.teacherHome,
    Routes.teacherStudents,
    Routes.teacherQuran,
    Routes.teacherMessages,
    Routes.athkar,
    Routes.settings,
    'student:demo',
    'notes:demo-lesson-1',
    Routes.mushaf,
  ];

  /// Things a finger can tap.
  bool tappable(Widget w) =>
      (w is InkWell && w.onTap != null) ||
      (w is IconButton && w.onPressed != null) ||
      (w is ButtonStyleButton && w.onPressed != null) ||
      (w is ListTile && w.onTap != null) ||
      (w is Switch && w.onChanged != null) ||
      (w is Checkbox && w.onChanged != null);

  String path(String r) => switch (r.split(':')) {
    ['chat', final id] => Routes.chat(id),
    ['student', final id] => Routes.studentDetail(id),
    ['notes', final id] => Routes.lessonNotes(id),
    _ => r,
  };

  Future<void> sweep(WidgetTester tester, {required String role, required String locale, double? textScale}) async {
    final quran = testQuran;
    final (container, _) = await startApp(
      tester,
      prefs: {'settings.v2': userSettings(role: role, locale: locale)},
      textScale: textScale,
      overrides: [
        quranProvider.overrideWith((ref) async => quran),
        micPermissionProvider.overrideWithValue(() async => true),
      ],
    );
    final router = routerOf(tester);
    final home = role == 'student' ? Routes.studentHome : Routes.teacherHome;
    final problems = <String>[];
    final tapped = <String, int>{};

    Future<void> open(String route) async {
      final c = container.read(callControllerProvider.notifier);
      if (container.read(callControllerProvider).searching) await c.cancel();
      if (container.read(callControllerProvider).inCall) await c.hangUp();
      c.reset();
      router.go(home);
      await tester.pump();
      final p = path(route);
      if (p != home) router.push(p);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    for (final route in role == 'student' ? studentRoutes : teacherRoutes) {
      await open(route);
      final first = tester.takeException();
      if (first != null) problems.add('$route (opening): $first');
      final count = find.byWidgetPredicate(tappable).evaluate().length;
      tapped[route] = count;
      for (var i = 0; i < count && i < 60; i++) {
        await open(route);
        final all = find.byWidgetPredicate(tappable);
        if (i >= all.evaluate().length) break;
        // This exact button, even after scrolling to it rebuilds the list.
        final element = all.evaluate().elementAt(i);
        final target = find.byElementPredicate((e) => identical(e, element));
        final label = _describe(tester, target);
        try {
          await tester.ensureVisible(target);
          await tester.pump();
          // A real finger: down, a moment, up.
          final at = tester.getCenter(target, warnIfMissed: false);
          final g = await tester.startGesture(at, kind: PointerDeviceKind.touch);
          await tester.pump(const Duration(milliseconds: 60));
          await g.up();
          for (var k = 0; k < 8; k++) {
            await tester.pump(const Duration(milliseconds: 250));
          }
        } catch (e) {
          problems.add('$route → "$label": $e');
        }
        final e = tester.takeException();
        if (e != null) problems.add('$route → "$label": $e');
      }
    }
    // Leave nothing running.
    await open(home);
    await tester.pump(const Duration(minutes: 3));
    // ignore: avoid_print
    print('Buttons per screen ($role, $locale, ${textScale ?? 1}x): $tapped');
    expect(tapped.values.every((n) => n > 0), isTrue, reason: 'a screen with no buttons found: $tapped');
    expect(problems, isEmpty, reason: problems.join('\n'));
  }

  for (final role in ['student', 'teacher']) {
    for (final locale in ['en', 'ar']) {
      testWidgets('every button works: $role, $locale', (tester) async {
        await sweep(tester, role: role, locale: locale);
      });
      // Large text, as many elderly users have their phones set.
      testWidgets('every button works: $role, $locale, text at 200%', (tester) async {
        await sweep(tester, role: role, locale: locale, textScale: 2);
      });
    }
  }
}

/// The text (or tooltip) on a button, to say which one failed.
String _describe(WidgetTester tester, Finder f) {
  final texts = find.descendant(of: f, matching: find.byType(Text)).evaluate();
  for (final t in texts) {
    final w = t.widget as Text;
    final s = w.data ?? w.textSpan?.toPlainText();
    if (s != null && s.trim().isNotEmpty) return s.trim();
  }
  final w = f.evaluate().first.widget;
  if (w is IconButton && w.tooltip != null) return w.tooltip!;
  return w.runtimeType.toString();
}
