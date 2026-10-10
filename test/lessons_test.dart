import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/features/call/call_controller.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lesson history on the demo backend: progress and notes for the student,
/// the rating after a call, and the teacher's students, notes and stats.
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
    await _loadFont('KFGQPC', ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
  });

  Future<(ProviderContainer, GoRouter)> open(WidgetTester tester, {String role = 'student', int sessions = 2}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"$role","gender":"female","name":"Fatima",'
          '"permissionsDone":true,"tourDone":true,"teacherStatus":"approved","sessions":$sessions}',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        onlineCheckProvider.overrideWithValue(() async => true),
        micPermissionProvider.overrideWithValue(() async => true),
        quranProvider.overrideWith((ref) async => quran),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
    await tester.pump(const Duration(milliseconds: 1400));
    final router = GoRouter.of(tester.element(find.byType(Navigator).first));
    router.go(role == 'student' ? Routes.studentHome : Routes.teacherHome);
    await tester.pumpAndSettle();
    return (container, router);
  }

  Future<void> settle(WidgetTester tester, [Duration d = const Duration(seconds: 1)]) async {
    for (var i = 0; i < d.inMilliseconds ~/ 250; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('student: next portion, progress and the teacher\'s notes', (tester) async {
    final (_, router) = await open(tester);
    // Home: the next portion from the latest notes.
    expect(find.text('Al-Mulk 11–20'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('2 lessons'), 300);
    expect(find.text('2 lessons'), findsOneWidget);

    unawaited(router.push(Routes.progress));
    await tester.pumpAndSettle();
    expect(find.text('2 lessons · 33 minutes'), findsOneWidget);
    expect(find.text('Ayahs recited: 14'), findsOneWidget);
    expect(find.text('Al-Mulk 1–10'), findsOneWidget);
    expect(find.text('Al-Ikhlāṣ 1–4'), findsOneWidget);

    await tester.ensureVisible(find.text('Al-Mulk 1–10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Al-Mulk 1–10'));
    await tester.pumpAndSettle();
    expect(find.text('Notes from Aisha Rahman'), findsOneWidget);
    expect(find.text('Ayahs to practise'), findsOneWidget);
    expect(find.textContaining('madd in ayah 3'), findsOneWidget);
    expect(find.text('Al-Mulk 11–20'), findsOneWidget);
  });

  testWidgets('student: a call is saved as a lesson, and the rating with it', (tester) async {
    final (container, _) = await open(tester);
    await tester.tap(find.text('Recite now'));
    await settle(tester, const Duration(seconds: 4));
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end call'));
    await settle(tester);
    final id = container.read(callControllerProvider).callId;
    await tester.tap(find.text('Good'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    // (Lists update when their screen is showing again.)
    final lessons = container.read(lessonsProvider).value!;
    expect(lessons.length, 3);
    expect(lessons.first.id, id);
    expect(lessons.first.rating, 2);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('teacher: students, a student\'s lessons, and notes', (tester) async {
    final (container, router) = await open(tester, role: 'teacher');
    router.go(Routes.teacherStudents);
    await tester.pumpAndSettle();
    expect(find.text('Fatima'), findsOneWidget);
    expect(find.text('2 lessons'), findsOneWidget);
    await tester.tap(find.text('Fatima'));
    await tester.pumpAndSettle();
    expect(find.text('Message'), findsOneWidget);

    // Edit the notes of the older lesson: grade, then save.
    await tester.tap(find.text('Al-Ikhlāṣ 1–4'));
    await tester.pumpAndSettle();
    expect(find.text('Notes for Fatima'), findsOneWidget);
    await tester.ensureVisible(find.text('Needs practice'));
    await tester.tap(find.text('Needs practice'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save notes'));
    await tester.tap(find.text('Save notes'));
    await tester.pumpAndSettle();
    final l = container.read(lessonsProvider).value!.firstWhere((x) => x.id == 'demo-lesson-1');
    expect(l.notes!.grade, 0);
    expect(l.notes!.recited, const Portion(112, 1, 4));
  });

  testWidgets('teacher: notes after a call start from the last next portion', (tester) async {
    final (container, router) = await open(tester, role: 'teacher');
    // A new lesson without notes for the same student.
    unawaited(router.push(Routes.incoming));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await settle(tester);
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end call'));
    await settle(tester);
    await tester.tap(find.textContaining('Add notes'));
    await tester.pumpAndSettle();
    // Recited: where she was asked to go next (Al-Mulk 11–20); next: 21–30.
    expect(find.text('سورة المُلك (67)'), findsNothing);
    expect(find.textContaining('Al-Mulk'), findsNWidgets(2));
    expect(find.text('11'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('teacher: today\'s lessons and minutes on the home screen', (tester) async {
    await open(tester, role: 'teacher');
    final now = DateTime.now();
    final threeHoursAgo = now.subtract(const Duration(hours: 3));
    // The sample lesson from 3 hours ago counts if it was today.
    if (DateUtils.isSameDay(threeHoursAgo, now)) {
      expect(find.text('18'), findsOneWidget);
    }
  });
}
