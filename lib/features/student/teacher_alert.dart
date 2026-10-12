import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/backend.dart';
import '../../core/reminders.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';

/// "Alert me when a teacher is free": on for one hour. While on, teachers
/// of the student's gender see one more student waiting, and the phone
/// shows a notification as soon as a teacher is free (then it switches
/// off). The state is when it ends, or null when off.
class TeacherAlert extends Notifier<DateTime?> {
  static const window = Duration(hours: 1);
  static const _key = 'teacherAlertUntil';

  @override
  DateTime? build() {
    final ms = ref.read(sharedPreferencesProvider).getInt(_key);
    if (ms == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    return until.isAfter(DateTime.now()) ? until : null;
  }

  Gender? get _gender => ref.read(settingsProvider).gender;

  void turnOn() {
    final until = DateTime.now().add(window);
    state = until;
    ref.read(sharedPreferencesProvider).setInt(_key, until.millisecondsSinceEpoch);
    final g = _gender;
    if (g != null) unawaited(ref.read(backendProvider).setWaiting(gender: g, until: until).catchError((_) {}));
  }

  void turnOff() {
    if (state == null && ref.read(sharedPreferencesProvider).getInt(_key) == null) return;
    state = null;
    ref.read(sharedPreferencesProvider).remove(_key);
    final g = _gender;
    if (g != null) unawaited(ref.read(backendProvider).setWaiting(gender: g).catchError((_) {}));
  }
}

final teacherAlertProvider = NotifierProvider<TeacherAlert, DateTime?>(TeacherAlert.new);

/// Watches for a free teacher while the alert is on (watched once, by the
/// app). Sends the notification once, then switches the alert off; also
/// switches it off when the hour is up.
final teacherAlertWatchProvider = Provider<void>((ref) {
  final until = ref.watch(teacherAlertProvider);
  final me = ref.watch(settingsProvider.select((s) => (s.role, s.gender, s.locale?.languageCode == 'ar')));
  if (until == null || me.$1 != UserRole.student || me.$2 == null) return;
  final alert = ref.read(teacherAlertProvider.notifier);
  final left = until.difference(DateTime.now());
  final timer = Timer(left.isNegative ? Duration.zero : left, alert.turnOff);
  ref.onDispose(timer.cancel);
  ref.listen(availableTeachersProvider(me.$2), (_, next) {
    if ((next.value ?? 0) > 0) {
      unawaited(Reminders.instance.teacherFree(S(ar: me.$3, female: me.$2 == Gender.female)));
      alert.turnOff();
    }
  }, fireImmediately: true);
});
