import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanadi/app.dart';
import 'package:sanadi/core/router.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/features/onboarding/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opens every screen at 100% and 200% text, in English and Arabic, on a
/// 360x800 phone. Any layout overflow fails the test.
void main() {
  final student = [
    Routes.studentHome,
    Routes.studentQuran,
    Routes.studentAthkar,
    Routes.studentMessages,
    '${Routes.athkar}/morning',
    '${Routes.athkar}/tasbeeh',
    Routes.progress,
    Routes.teacherNotes,
    Routes.connecting,
    Routes.inCall,
    '${Routes.studentEnded}?s=600',
    Routes.settings,
    Routes.mushafAt(sura: 67, ayah: 1),
    Routes.welcome,
    Routes.role,
    Routes.gender,
    Routes.name,
    Routes.permMic,
    Routes.permNotif,
    '/perm-denied/mic',
    Routes.tour,
  ];
  const teacher = [
    Routes.teacherHome,
    Routes.teacherStudents,
    Routes.incoming,
    '${Routes.inCall}?teacher=1',
    '${Routes.teacherEnded}?s=600',
    Routes.notesForm,
    Routes.permFullScreen,
    '${Routes.apply}/1',
    '${Routes.apply}/2',
    '${Routes.apply}/3',
    '${Routes.apply}/4',
    '${Routes.apply}/5',
    Routes.applySent,
  ];

  for (final locale in ['en', 'ar']) {
    for (final scale in [1.0, 2.0]) {
      for (final (role, paths) in [('student', student), ('teacher', teacher)]) {
        testWidgets('$role screens fit: $locale at ${(scale * 100).round()}%', (tester) async {
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          SharedPreferences.setMockInitialValues({
            'settings.v2':
                '{"locale":"$locale","signedIn":true,"role":"$role","gender":"female",'
                '"name":"Fatima Ahmed","permissionsDone":true,"tourDone":true,"teacherStatus":"approved","sessions":2}',
          });
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
                onlineCheckProvider.overrideWithValue(() async => true),
              ],
              child: const SanadiApp(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 1400));
          await tester.pump(const Duration(milliseconds: 500));

          final context = tester.element(find.byType(Navigator).first);
          final router = GoRouter.of(context);
          for (final path in paths) {
            router.go(path);
            await tester.pump();
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump(const Duration(milliseconds: 400));
            expect(tester.takeException(), isNull, reason: path);
          }
          // Leave no pending timers behind.
          router.go(role == 'student' ? Routes.studentMessages : Routes.teacherStudents);
          await tester.pump(const Duration(seconds: 6));
        });
      }
    }
  }
}
