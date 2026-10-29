import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/backend/calls.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/call/call_controller.dart';
import 'package:sanadi/features/call/call_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A demo server with chosen free teachers and lesson history, which
/// records who is rung (and never answers).
class _Server extends DemoBackend {
  _Server({this.free = const [], this.history = const []});

  final List<Candidate> free;
  final List<String> history;
  final rung = <String>[];
  final count = StreamController<int>.broadcast();

  @override
  Future<List<Candidate>> freeTeachers(Gender gender, {Set<String> exclude = const {}}) async => [
    for (final c in free)
      if (!exclude.contains(c.uid)) c,
  ];

  @override
  Future<void> ring(String callId, String teacherId) async => rung.add(teacherId);

  @override
  Stream<List<Lesson>> lessons() => Stream.value([
    for (final (i, t) in history.indexed)
      Lesson(
        id: 'l$i',
        studentId: 'demo',
        teacherId: t,
        studentName: 'F',
        teacherName: 'T',
        at: DateTime(2026, 10, 14 - i),
      ),
  ]);

  @override
  Stream<int> availableTeachers(Gender? gender) => count.stream;
}

/// Automatic matching: who a student's call rings first, strict gender
/// pairing, and the availability bar with its Call button.
void main() {
  const s = S(ar: false, female: true);

  test('the chosen teacher, then favourites, then past teachers, then the least busy', () {
    const free = [
      Candidate('busy', lessonsToday: 6),
      Candidate('new', lessonsToday: 1),
      Candidate('old'),
      Candidate('fav', lessonsToday: 9),
      Candidate('older'),
      Candidate('idle'),
    ];
    List<String> order({String? preferred, Set<String> favourites = const {}, List<String> previous = const []}) =>
        rankCandidates(
          free,
          preferred: preferred,
          favourites: favourites,
          previous: previous,
        ).map((c) => c.uid).toList();

    expect(order(), ['old', 'older', 'idle', 'new', 'busy', 'fav']);
    expect(order(previous: ['older', 'old']), ['older', 'old', 'idle', 'new', 'busy', 'fav']);
    expect(order(favourites: {'fav'}, previous: ['old']), ['fav', 'old', 'older', 'idle', 'new', 'busy']);
    expect(order(preferred: 'busy', favourites: {'fav'}), ['busy', 'fav', 'old', 'older', 'idle', 'new']);
    // A chosen teacher who isn't free is simply not there.
    expect(order(preferred: 'gone').first, 'old');
  });

  Future<(ProviderContainer, _Server)> container({
    String gender = '"gender":"female",',
    String favourites = '[]',
    List<String> history = const [],
  }) async {
    SharedPreferences.setMockInitialValues({
      'settings.v2': '{"locale":"en","signedIn":true,"role":"student",$gender"name":"F","permissionsDone":true}',
      'favoriteTeachers': favourites,
    });
    final prefs = await SharedPreferences.getInstance();
    final server = _Server(
      free: const [Candidate('new'), Candidate('old'), Candidate('fav', lessonsToday: 4)],
      history: history,
    );
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        backendProvider.overrideWithValue(server),
        micPermissionProvider.overrideWithValue(() async => true),
      ],
    );
    addTearDown(c.dispose);
    // Loaded, as the home screen keeps it while the app runs.
    c.listen(lessonsProvider, (_, _) {});
    await c.read(lessonsProvider.future);
    return (c, server);
  }

  Future<String> firstRung(ProviderContainer c, _Server server) async {
    final calls = c.read(callControllerProvider.notifier);
    unawaited(calls.startAsStudent());
    for (var i = 0; i < 100 && server.rung.isEmpty; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await calls.cancel();
    return server.rung.first;
  }

  test('a call rings a favourite first, then a past teacher', () async {
    var (c, server) = await container(favourites: '["fav"]', history: ['old']);
    expect(await firstRung(c, server), 'fav');
    (c, server) = await container(history: ['old']);
    expect(await firstRung(c, server), 'old');
    (c, server) = await container();
    expect(await firstRung(c, server), 'new'); // fewer lessons today than "fav"
  });

  test('no gender, no call: teachers are matched only by gender', () async {
    final (c, server) = await container(gender: '');
    await c.read(callControllerProvider.notifier).startAsStudent();
    expect(c.read(callControllerProvider).phase, CallPhase.failed);
    expect(server.rung, isEmpty);
  });

  testWidgets('away from home, a bar shows who is free, with Call', (tester) async {
    final server = _Server();
    await startApp(
      tester,
      prefs: {'settings.v2': userSettings(teacherStatus: null)},
      overrides: [backendProvider.overrideWithValue(server)],
    );
    await tester.pumpAndSettle();
    final router = routerOf(tester);
    final bar = find.byKey(const ValueKey('availability-bar'));
    server.count.add(2);
    await tester.pumpAndSettle();
    expect(bar, findsNothing); // home has its own

    router.go(Routes.studentAthkar);
    await tester.pumpAndSettle();
    expect(find.descendant(of: bar, matching: find.text(s.teachersAvailable(2))), findsOneWidget);
    server.count.add(0);
    await tester.pumpAndSettle();
    expect(find.descendant(of: bar, matching: find.text(s.teachersAvailable(0))), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-call')), findsNothing);
    server.count.add(1);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bar-call')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ConnectingScreen), findsOneWidget);
  });
}
