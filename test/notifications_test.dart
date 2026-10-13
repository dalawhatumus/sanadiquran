import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanadi/backend/backend.dart';
import 'package:sanadi/backend/sessions.dart';
import 'package:sanadi/core/background.dart';
import 'package:sanadi/core/reminders.dart';
import 'package:sanadi/core/settings.dart';
import 'package:sanadi/core/strings.dart';
import 'package:sanadi/features/lessons/lesson_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifications for things that happen on another phone, where each one
/// may lead, and the background service's safe defaults.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, List<String>, DemoBackend)> start(String role, {String status = 'none'}) async {
    SharedPreferences.setMockInitialValues({
      'settings.v2':
          '{"locale":"en","signedIn":true,"role":"$role","gender":"female","name":"Fatima",'
          '"permissionsDone":true,"tourDone":true,"teacherStatus":"$status"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final shown = <String>[];
    final backend = DemoBackend();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        backendProvider.overrideWithValue(backend),
        showLessonNotesProvider.overrideWithValue(({
          required S s,
          required String lessonId,
          required String teacherName,
        }) async {
          shown.add('notes $lessonId from $teacherName');
        }),
        showDecisionProvider.overrideWithValue(({required S s, required bool approved}) async {
          shown.add(approved ? 'approved' : 'not approved');
        }),
      ],
    );
    addTearDown(c.dispose);
    c.listen(lessonAlertsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return (c, shown, backend);
  }

  test('a student hears when the teacher adds notes (not about notes already there)', () async {
    final (_, shown, backend) = await start('student');
    expect(shown, isEmpty, reason: 'the sample lessons already had notes');
    await backend.recordLesson(
      callId: 'call-9',
      studentId: 'demo',
      teacherId: 'demo-teacher',
      studentName: 'Fatima',
      teacherName: 'Aisha Rahman',
      gender: Gender.female,
      startedAt: DateTime.now(),
      durationSec: 600,
    );
    await Future<void>.delayed(Duration.zero);
    expect(shown, isEmpty, reason: 'a lesson without notes yet');
    await backend.saveNotes('call-9', const LessonNotes(grade: 2));
    await Future<void>.delayed(Duration.zero);
    expect(shown, ['notes call-9 from Aisha Rahman']);
  });

  test('a teacher hears when the application is decided', () async {
    final (c, shown, _) = await start('teacher', status: 'pending');
    c.read(settingsProvider.notifier).update((s) => s.copyWith(teacherStatus: TeacherStatus.approved));
    await Future<void>.delayed(Duration.zero);
    expect(shown, ['approved']);
  });

  test('notifications open only known places', () {
    for (final ok in ['/notes?id=call-9', '/call/incoming?id=abc_123', '/t/home', '/s/home', '/chat/s1_t1']) {
      expect(Reminders.safeRoute(ok), ok, reason: ok);
    }
    for (final bad in ['/notes?id=../x', '/notes?id=a&b=1', '/call/incoming?id=', '/call/live', '/t/students']) {
      expect(Reminders.safeRoute(bad), isNull, reason: bad);
    }
  });

  test('the background service does nothing where the phone can\'t run it', () async {
    await Background.startListening(const S(ar: false, female: true));
    expect(Background.running, isFalse);
    await Background.stopListening();
    await Background.overLockScreen(true);
    await Background.overLockScreen(false);
    await Background.moveToBack();
    expect(Background.running, isFalse);
  });
}
