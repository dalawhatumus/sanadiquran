import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/backend/calls.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/features/call/call_controller.dart';

import 'helpers.dart';

/// Teachers who answer (or not) as a test says: [answers] maps a teacher to
/// what they do when rung.
class _Teachers extends DemoBackend {
  _Teachers(this.answers);

  final Map<String, CallStatus?> answers;
  final rung = <String>[];

  @override
  Future<List<Candidate>> freeTeachers(Gender gender, {Set<String> exclude = const {}}) async => [
    for (final t in answers.keys)
      if (!exclude.contains(t)) Candidate(t),
  ];

  @override
  Future<void> ring(String callId, String teacherId) async {
    rung.add(teacherId);
    await super.ring(callId, teacherId);
  }
}

/// Changes how the demo backend's pretend teacher behaves.
class _RingThen extends _Teachers {
  _RingThen(super.answers);

  @override
  Future<void> ring(String callId, String teacherId) async {
    rung.add(teacherId);
    final what = answers[teacherId];
    // Ring, then decline / answer / say nothing.
    await setCallStatus(callId, CallStatus.ringing);
    if (what == null) return;
    Timer(const Duration(seconds: 1), () {
      if (what == CallStatus.active) {
        acceptCall(callId, name: 'Teacher $teacherId');
      } else {
        setCallStatus(callId, what);
      }
    });
  }
}

/// A teacher's call to this student, or a student who never answers the
/// teacher's call. Records the statuses set.
class _TeacherCalls extends DemoBackend {
  _TeacherCalls({this.ringStudent = false});

  /// Ring this student from their teacher.
  final bool ringStudent;
  final statuses = <CallStatus>[];

  static const call = CallInfo(
    id: 'teacher-call',
    studentId: 'demo',
    studentName: 'Fatima',
    teacherId: 'demo-teacher',
    teacherName: 'Aisha Rahman',
    status: CallStatus.ringing,
    fromTeacher: true,
  );

  @override
  Stream<List<CallInfo>> callsFromTeachers() =>
      // Rings a moment after the student has opened the app.
      Stream.fromFuture(Future.delayed(const Duration(seconds: 2), () => ringStudent ? const [call] : const []));

  @override
  Future<String> callStudent({
    required String studentId,
    required String studentName,
    String? studentAvatar,
    required String name,
    String? avatar,
    required Gender gender,
  }) async => call.id;

  @override
  Stream<CallInfo?> watchCall(String callId) =>
      callId == call.id ? (StreamController<CallInfo?>()..add(call)).stream : super.watchCall(callId);

  @override
  Future<void> setCallStatus(String callId, CallStatus status) async {
    statuses.add(status);
    await super.setCallStatus(callId, status);
  }
}

void main() {
  setUpAll(loadAppFonts);

  Future<(ProviderContainer, GoRouter)> open(WidgetTester tester, {String role = 'student', Backend? backend}) async {
    final (container, _) = await startApp(
      tester,
      prefs: {'settings.v2': userSettings(role: role, sessions: 0)},
      overrides: [
        micPermissionProvider.overrideWithValue(() async => true),
        if (backend != null) backendProvider.overrideWithValue(backend),
      ],
    );
    final router = routerOf(tester);
    router.go(role == 'student' ? Routes.studentHome : Routes.teacherHome);
    await tester.pumpAndSettle();
    return (container, router);
  }

  Future<void> settle(WidgetTester tester, [Duration d = const Duration(seconds: 1)]) async {
    for (var i = 0; i < d.inMilliseconds ~/ 250; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('student: Recite now finds a teacher, talks, ends', (tester) async {
    final (container, router) = await open(tester);
    await tester.tap(find.text('Recite now'));
    await tester.pump();
    await settle(tester);
    expect(find.text('Calling a teacher…'), findsOneWidget);
    await settle(tester, const Duration(seconds: 3));
    // Connected to the (demo) teacher.
    expect(find.text('Aisha Rahman'), findsOneWidget);
    expect(find.text('Good connection'), findsOneWidget);
    expect(container.read(callControllerProvider).phase, CallPhase.active);

    // Mute shows the banner; speaker toggles.
    await tester.tap(find.text('Mute'));
    await tester.pump();
    expect(find.textContaining("Muted."), findsOneWidget);
    expect(container.read(callControllerProvider).muted, isTrue);

    await settle(tester, const Duration(seconds: 3));
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end call'));
    await settle(tester);
    expect(find.text('May Allah reward you'), findsOneWidget);
    expect(find.textContaining('with Aisha Rahman'), findsOneWidget);
    expect(container.read(settingsProvider).sessions, 1);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(container.read(callControllerProvider).phase, CallPhase.idle);
    router.go(Routes.studentHome);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('student: a teacher declines, the next one answers', (tester) async {
    final b = _RingThen({'t1': CallStatus.declined, 't2': CallStatus.active});
    final (container, _) = await open(tester, backend: b);
    await tester.tap(find.text('Recite now'));
    await settle(tester, const Duration(seconds: 4));
    expect(b.rung.toSet(), {'t1', 't2'});
    expect(container.read(callControllerProvider).phase, CallPhase.active);
    expect(container.read(callControllerProvider).otherName, isNotEmpty);
    await container.read(callControllerProvider.notifier).hangUp();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('student: an unanswered call moves on after 30 seconds', (tester) async {
    final b = _RingThen({'t1': null, 't2': CallStatus.active});
    final (container, _) = await open(tester, backend: b);
    await tester.tap(find.text('Recite now'));
    await settle(tester, const Duration(seconds: 5));
    expect(container.read(callControllerProvider).phase, CallPhase.ringing);
    await settle(tester, const Duration(seconds: 30));
    expect(b.rung.length, 2);
    expect(container.read(callControllerProvider).phase, CallPhase.active);
    await container.read(callControllerProvider.notifier).hangUp();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('student: no teacher free, then try again or go back', (tester) async {
    final b = _Teachers({});
    final (container, _) = await open(tester, backend: b);
    await tester.tap(find.text('Recite now'));
    await settle(tester, const Duration(seconds: 125));
    expect(container.read(callControllerProvider).phase, CallPhase.unmatched);
    expect(find.text('No teacher is free right now'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(container.read(callControllerProvider).phase, CallPhase.idle);
    expect(find.text('Recite now'), findsOneWidget);
  });

  testWidgets('student: cancel while looking', (tester) async {
    final (container, _) = await open(tester);
    await tester.tap(find.text('Recite now'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancel'));
    await settle(tester, const Duration(seconds: 4));
    expect(container.read(callControllerProvider).phase, CallPhase.idle);
    expect(find.text('Recite now'), findsOneWidget);
  });

  testWidgets('teacher: answers a call, talks, ends', (tester) async {
    final (container, router) = await open(tester, role: 'teacher');
    unawaited(router.push(Routes.incoming));
    await tester.pumpAndSettle();
    expect(find.text('Incoming call'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await settle(tester);
    expect(container.read(callControllerProvider).phase, CallPhase.active);
    expect(find.text('Good connection'), findsOneWidget);
    await settle(tester, const Duration(seconds: 2));
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end call'));
    await settle(tester);
    expect(find.text('Call ended'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(container.read(callControllerProvider).phase, CallPhase.idle);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('teacher: a call not answered in 30 seconds is missed', (tester) async {
    final (_, router) = await open(tester, role: 'teacher');
    unawaited(router.push(Routes.incoming));
    await tester.pumpAndSettle();
    await settle(tester, const Duration(seconds: 31));
    expect(find.text('Call not answered'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Incoming call'), findsNothing);
  });

  testWidgets('teacher: calls a student, who answers; they talk, then end', (tester) async {
    final (container, router) = await open(tester, role: 'teacher');
    unawaited(router.push(Routes.callStudent('demo-student')));
    await tester.pump();
    await settle(tester);
    expect(find.textContaining('Calling'), findsOneWidget);
    expect(container.read(callControllerProvider).phase, CallPhase.ringing);
    // The (demo) student answers after a moment.
    await settle(tester, const Duration(seconds: 3));
    expect(container.read(callControllerProvider).phase, CallPhase.active);
    expect(find.text('Good connection'), findsOneWidget);
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end call'));
    await settle(tester);
    expect(find.text('Call ended'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(container.read(callControllerProvider).phase, CallPhase.idle);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('teacher: a student who doesn\'t answer in 30 seconds; try again or go back', (tester) async {
    final backend = _TeacherCalls();
    final (container, router) = await open(tester, role: 'teacher', backend: backend);
    unawaited(router.push(Routes.callStudent('demo')));
    await tester.pump();
    await settle(tester, const Duration(seconds: 31));
    expect(container.read(callControllerProvider).phase, CallPhase.unmatched);
    expect(find.textContaining("didn't answer"), findsOneWidget);
    expect(backend.statuses, contains(CallStatus.unmatched));
    await tester.tap(find.text('Back'));
    await settle(tester);
    expect(find.textContaining("didn't answer"), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('teacher: cancelling while it rings stops the call', (tester) async {
    final backend = _TeacherCalls();
    final (container, router) = await open(tester, role: 'teacher', backend: backend);
    unawaited(router.push(Routes.callStudent('demo')));
    await tester.pump();
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(backend.statuses, [CallStatus.cancelled]);
    expect(container.read(callControllerProvider).phase, CallPhase.idle);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('student: their teacher calls; it rings with her name, and Accept connects', (tester) async {
    final backend = _TeacherCalls(ringStudent: true);
    final (container, _) = await open(tester, backend: backend);
    await settle(tester, const Duration(seconds: 3));
    expect(find.text('Incoming call'), findsOneWidget);
    expect(find.text('Aisha Rahman'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await settle(tester);
    expect(backend.statuses, [CallStatus.active]);
    expect(container.read(callControllerProvider).phase, CallPhase.active);
    expect(container.read(callControllerProvider).asTeacher, isFalse);
    await tester.tap(find.text('End call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, end call'));
    await settle(tester);
    expect(find.text('May Allah reward you'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('student: declining their teacher\'s call', (tester) async {
    final backend = _TeacherCalls(ringStudent: true);
    await open(tester, backend: backend);
    await settle(tester, const Duration(seconds: 3));
    await tester.tap(find.text('Decline'));
    await settle(tester);
    expect(backend.statuses, [CallStatus.declined]);
    expect(find.text('Incoming call'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
  });
}
