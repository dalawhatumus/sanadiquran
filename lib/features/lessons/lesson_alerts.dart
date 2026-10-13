import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../backend/sessions.dart';
import '../../core/reminders.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';

/// Shows a notification for something new that happened on another phone,
/// while the app is running (replaced in tests).
final showLessonNotesProvider =
    Provider<Future<void> Function({required S s, required String lessonId, required String teacherName})>(
      (ref) => Reminders.instance.lessonNotes,
    );
final showDecisionProvider = Provider<Future<void> Function({required S s, required bool approved})>(
  (ref) => Reminders.instance.applicationDecided,
);

/// A student hears when their teacher adds notes to a lesson; a teacher
/// hears when their application is approved or turned down. Only changes
/// seen while the app runs count (not what was already there when it
/// opened). Watched once, by the app.
final lessonAlertsProvider = Provider<void>((ref) {
  final me = ref.watch(settingsProvider.select((s) => (s.signedIn, s.role, s.locale?.languageCode == 'ar', s.female)));
  if (!me.$1) return;
  S strings() => S(ar: me.$3, female: me.$4);

  if (me.$2 == UserRole.student) {
    // Lessons that already had notes; the first list is the starting point.
    Set<String>? withNotes;
    ref.listen(lessonsProvider, (_, next) {
      final list = next.value;
      if (list == null) return;
      final before = withNotes;
      withNotes = {
        for (final l in list)
          if (l.notes != null && !l.notes!.isEmpty) l.id,
      };
      if (before == null) return;
      for (final l in list) {
        if (withNotes!.contains(l.id) && !before.contains(l.id)) {
          unawaited(ref.read(showLessonNotesProvider)(s: strings(), lessonId: l.id, teacherName: l.teacherName));
        }
      }
    }, fireImmediately: true);
  }

  if (me.$2 == UserRole.teacher) {
    ref.listen(settingsProvider.select((s) => s.teacherStatus), (prev, next) {
      if (prev != TeacherStatus.pending) return;
      if (next == TeacherStatus.approved || next == TeacherStatus.rejected) {
        unawaited(ref.read(showDecisionProvider)(s: strings(), approved: next == TeacherStatus.approved));
      }
    });
  }
});
