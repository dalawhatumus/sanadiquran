import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/backend/teachers.dart';
import 'package:sanadi/core/connectivity.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/call/call_controller.dart';
import 'package:sanadi/features/quran/quran_data.dart';
import 'package:sanadi/features/student/teacher_alert.dart';
import 'package:sanadi/features/student/teachers_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A demo server where the number of free teachers and waiting students
/// can be changed by the test, and "waiting" calls are recorded.
class _Server extends DemoBackend {
  final free = StreamController<int>.broadcast();
  final waiting = <DateTime?>[];
  int waitingStudentsNow = 0;

  @override
  Stream<int> availableTeachers(Gender? gender) => free.stream;

  @override
  Future<void> setWaiting({required Gender gender, DateTime? until}) async => waiting.add(until);

  @override
  Stream<int> waitingStudents(Gender gender) => Stream.value(waitingStudentsNow);
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

/// The teacher list, calling a chosen teacher, favourites, continue
/// reading, "Alert me when a teacher is free", and students waiting.
void main() {
  const s = S(ar: false, female: true);
  final quran = QuranData.parse((
    File('assets/quran/hafs.json').readAsStringSync(),
    File('assets/quran/layout.json').readAsStringSync(),
  ))..attachWidths(File('assets/quran/line_widths.json').readAsStringSync());

  setUpAll(() async {
    await _loadFont('KFGQPC', ['assets/fonts/quran/UthmanicHafs1Ver18.ttf']);
  });

  Future<(ProviderContainer, GoRouter, SharedPreferences)> open(
    WidgetTester tester, {
    String role = 'student',
    Backend? backend,
    Map<String, Object> extra = const {},
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"$role","gender":"female","name":"Fatima",'
          '"permissionsDone":true,"ageGroup":"25-34","nationality":"SA","phone":"+966500000001","tourDone":true,"teacherStatus":"approved","sessions":2}',
      ...extra,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        onlineCheckProvider.overrideWithValue(() async => true),
        micPermissionProvider.overrideWithValue(() async => true),
        quranProvider.overrideWith((ref) async => quran),
        if (backend != null) backendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const SanadiApp()));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    return (container, GoRouter.of(tester.element(find.byType(Navigator).first)), prefs);
  }

  Finder onHome(Finder f) => find.descendant(of: find.byType(Scrollable).first, matching: f);

  testWidgets('home: continue reading opens the page last read', (tester) async {
    final (_, router, _) = await open(tester, extra: {'lastPage': 41});
    final card = find.text(s.readingAt('Al-Baqarah', 41));
    await tester.scrollUntilVisible(card, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(router.state.uri.toString(), Routes.mushafAt(page: 41));
  });

  testWidgets('teachers: tabs, search, favourites, and calling a chosen teacher', (tester) async {
    final (container, router, prefs) = await open(tester);
    // The row on the home screen, free teachers first, with "See all".
    final seeAll = find.text(s.seeAll);
    await tester.scrollUntilVisible(seeAll, 300, scrollable: find.byType(Scrollable).first);
    expect(onHome(find.text('Aisha Rahman')), findsOneWidget);
    await tester.tap(seeAll);
    await tester.pumpAndSettle();
    expect(find.byType(TeachersScreen), findsOneWidget);

    Finder inList(String text) => find.descendant(of: find.byType(TeachersScreen), matching: find.text(text));
    expect(inList('Aisha Rahman'), findsOneWidget);
    expect(inList('Khadijah Noor'), findsOneWidget);
    expect(inList(s.inLesson), findsOneWidget);
    expect(inList(s.away), findsOneWidget);

    await tester.tap(find.text(s.tabAvailable));
    await tester.pumpAndSettle();
    expect(inList('Aisha Rahman'), findsOneWidget);
    expect(inList('Khadijah Noor'), findsNothing);

    await tester.tap(find.text(s.tabFavorites));
    await tester.pumpAndSettle();
    expect(inList(s.noFavorites), findsOneWidget);

    // A heart keeps a teacher in Favourites (on this phone).
    await tester.tap(find.text(s.tabAll));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(s.favorite).at(1));
    await tester.pumpAndSettle();
    expect(container.read(favoriteTeachersProvider), {'demo-teacher-2'});
    expect(prefs.getString('favoriteTeachers'), contains('demo-teacher-2'));
    await tester.tap(find.text(s.tabFavorites));
    await tester.pumpAndSettle();
    expect(inList('Khadijah Noor'), findsOneWidget);
    expect(inList('Aisha Rahman'), findsNothing);

    // Search.
    await tester.tap(find.text(s.tabAll));
    await tester.enterText(find.byType(TextField), 'maryam');
    await tester.pumpAndSettle();
    expect(inList('Maryam Saleh'), findsOneWidget);
    expect(inList('Aisha Rahman'), findsNothing);

    // Only a free teacher can be called, and the call asks for her.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(TeachersScreen), matching: find.text(s.call)), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(TeachersScreen), matching: find.text(s.call)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(router.state.uri.toString(), '${Routes.connecting}?teacher=demo-teacher');
    container.read(callControllerProvider.notifier).cancel();
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('alert: offered when nobody is free; rings once a teacher is, then switches off', (tester) async {
    final server = _Server();
    final (container, _, prefs) = await open(tester, backend: server);
    server.free.add(0);
    await tester.pumpAndSettle();
    expect(find.text(s.alertTitle), findsOneWidget);

    await tester.tap(find.text(s.alertTitle));
    await tester.pumpAndSettle();
    final until = container.read(teacherAlertProvider);
    expect(until, isNotNull);
    expect(until!.difference(DateTime.now()).inMinutes, inInclusiveRange(58, 60));
    expect(prefs.getInt('teacherAlertUntil'), isNotNull);
    expect(server.waiting.single, until, reason: 'teachers see one more student waiting');

    // A teacher switches on: the alert is sent and switches itself off.
    server.free.add(1);
    await tester.pumpAndSettle();
    expect(container.read(teacherAlertProvider), isNull);
    expect(prefs.getInt('teacherAlertUntil'), isNull);
    expect(server.waiting.last, isNull, reason: 'no longer waiting');
    expect(find.text(s.alertTitle), findsNothing);
  });

  testWidgets('alert: an expired alert is forgotten', (tester) async {
    final past = DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch;
    final (container, _, _) = await open(tester, extra: {'teacherAlertUntil': past});
    expect(container.read(teacherAlertProvider), isNull);
  });

  testWidgets('teacher home: how many students are waiting', (tester) async {
    final server = _Server()..waitingStudentsNow = 3;
    await open(tester, role: 'teacher', backend: server);
    expect(find.text(s.waitingCount(3)), findsOneWidget);
  });
}
