import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/admin/users_screen.dart';
import 'package:sanadi/features/call/missed_calls.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A demo server whose user is paused.
class _PausedBackend extends DemoBackend {
  @override
  Stream<bool> paused() => Stream.value(true);
}

/// Admin tools (people, pausing, overview), what a paused person sees, and
/// teacher auto-away.
void main() {
  const s = S(ar: false, female: true);

  Future<(ProviderContainer, GoRouter)> open(
    WidgetTester tester, {
    String role = 'student',
    Backend? backend,
    bool settle = true,
  }) async {
    final (container, _) = await startApp(
      tester,
      prefs: {'settings.v2': userSettings(role: role)},
      overrides: [if (backend != null) backendProvider.overrideWithValue(backend)],
    );
    if (settle) await tester.pumpAndSettle();
    return (container, routerOf(tester));
  }

  testWidgets('an admin pauses and restores an account', (tester) async {
    final (_, router) = await open(tester);
    router.push(Routes.adminUsers);
    await tester.pumpAndSettle();
    Finder inList(String text) => find.descendant(of: find.byType(UsersScreen), matching: find.text(text));
    expect(inList('Ahmad'), findsOneWidget);
    expect(inList('Aisha Rahman'), findsOneWidget);
    expect(find.text(s.pausedTag), findsNothing);

    // Search narrows the list.
    await tester.enterText(find.byType(TextField), 'ahmad');
    await tester.pumpAndSettle();
    expect(inList('Aisha Rahman'), findsNothing);

    await tester.tap(find.text('Ahmad'));
    await tester.pumpAndSettle();
    // Their details first (Ahmad hasn't given them yet), then Pause.
    expect(find.text(s.notGivenYet), findsNWidgets(3));
    await tester.tap(find.text(s.pauseAccount));
    await tester.pumpAndSettle();
    expect(find.text(s.pauseQ('Ahmad')), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Unkind messages');
    await tester.tap(find.text(s.pauseAccount));
    await tester.pumpAndSettle();
    expect(find.text(s.pausedTag), findsOneWidget);

    await tester.tap(find.text('Ahmad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.restoreAccount));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.restoreAccount).last);
    await tester.pumpAndSettle();
    expect(find.text(s.pausedTag), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the overview shows the counts', (tester) async {
    final (_, router) = await open(tester);
    router.push(Routes.adminStats);
    await tester.pumpAndSettle();
    expect(find.text(s.statTeachers), findsOneWidget);
    expect(find.text(s.statMinutes), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
    await tester.tap(find.text(s.refresh));
    await tester.pumpAndSettle();
    expect(find.text('33'), findsOneWidget);
  });

  testWidgets('a paused person sees why on home; the Quran stays open', (tester) async {
    final (_, router) = await open(tester, backend: _PausedBackend(), settle: false);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(s.pausedTitle), findsOneWidget);
    expect(find.text(s.recite), findsNothing);
    router.go(Routes.studentQuran);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(s.pausedTitle), findsNothing);
  });

  testWidgets('terms and the code of conduct open from their links', (tester) async {
    final (_, router) = await open(tester);
    router.push(Routes.terms);
    await tester.pumpAndSettle();
    expect(find.text(s.termsSections.first.$1), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    router.push(Routes.codeOfConduct);
    await tester.pumpAndSettle();
    expect(find.text(s.codeSections.first.$1), findsOneWidget);
  });

  test('a teacher who misses two calls in a row is set to away', () async {
    SharedPreferences.setMockInitialValues({
      'settings.v2': '{"signedIn":true,"role":"teacher","teacherStatus":"approved","available":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final away = c.read(autoAwayProvider.notifier);

    // A missed call, then an answered one: the count starts again.
    away.missed();
    away.responded();
    away.missed();
    expect(c.read(settingsProvider).available, isTrue);
    expect(c.read(autoAwayProvider), isFalse);

    away.missed();
    expect(c.read(settingsProvider).available, isFalse);
    expect(c.read(autoAwayProvider), isTrue);
    expect(prefs.getBool('autoAwayNotice'), isTrue);

    away.dismiss();
    expect(c.read(autoAwayProvider), isFalse);
    expect(prefs.getBool('autoAwayNotice'), isNull);
  });
}
