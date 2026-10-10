import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/sessions.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../lessons/lessons_ui.dart';
import '../messages/messages_screen.dart';
import '../quran/quran_data.dart';

/// A student this teacher has taught, from the lesson history.
class TaughtStudent {
  const TaughtStudent({required this.uid, required this.name, this.avatar, required this.lessons});

  final String uid;
  final String name;
  final String? avatar;

  /// Newest first.
  final List<Lesson> lessons;
}

final taughtStudentsProvider = Provider<List<TaughtStudent>>((ref) {
  final byStudent = <String, List<Lesson>>{};
  for (final l in ref.watch(lessonsProvider).value ?? const <Lesson>[]) {
    byStudent.putIfAbsent(l.studentId, () => []).add(l);
  }
  return [
    for (final e in byStudent.entries)
      TaughtStudent(uid: e.key, name: e.value.first.studentName, avatar: e.value.first.studentAvatar, lessons: e.value),
  ]..sort((a, b) => b.lessons.first.at.compareTo(a.lessons.first.at));
});

/// 35 · My students: everyone this teacher has taught, newest first.
class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final students = ref.watch(taughtStudentsProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: WordSafeText(s.navStudents, style: tt.headlineMedium),
            ),
            Expanded(
              child: students.isEmpty
                  ? EmptyState(
                      icon: const SIcon(SIcons.students, size: 52),
                      title: s.studentsSoonTitle,
                      body: s.studentsSoonBody,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: students.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final st = students[i];
                        return SCard(
                          onTap: () => context.push(Routes.studentDetail(st.uid)),
                          child: Row(
                            children: [
                              Avatar(initialOf(st.name), size: 60, image: st.avatar),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FullName(st.name, style: tt.titleLarge!),
                                    WordSafeText(
                                      s.lastLesson(chatDay(context, st.lessons.first.at)),
                                      style: tt.bodySmall,
                                    ),
                                    WordSafeText(s.lessonsCount(st.lessons.length), style: tt.bodySmall),
                                  ],
                                ),
                              ),
                              Icon(Arrows.next, color: t.primary, size: 32),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 36 · One student: their lessons with this teacher (add or edit notes on
/// any of them) and a Message button.
class StudentDetailScreen extends ConsumerWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    final st = ref.watch(taughtStudentsProvider).where((x) => x.uid == studentId).firstOrNull;
    if (st == null) {
      return const StepScaffold(showBack: true, center: true, content: [Center(child: CircularProgressIndicator())]);
    }
    final minutes = st.lessons.fold(0, (m, l) => m + l.minutes);
    final teacherId = st.lessons.first.teacherId;
    return StepScaffold(
      showBack: true,
      content: [
        Row(
          children: [
            Avatar(initialOf(st.name), size: 72, image: st.avatar),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FullName(st.name, style: tt.headlineSmall!),
                  WordSafeText(
                    '${s.lessonsCount(st.lessons.length)} · ${s.minutesCount(minutes)}',
                    style: tt.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BigButton(
          label: s.message,
          icon: Icons.chat_bubble_rounded,
          kind: ButtonKind.outline,
          onPressed: () => context.push(Routes.chat('${studentId}_$teacherId')),
        ),
        const SizedBox(height: 20),
        WordSafeText(s.lessonsL, style: tt.titleLarge),
        const SizedBox(height: 10),
        for (final l in st.lessons) ...[
          LessonCard(
            lesson: l,
            q: q,
            showStudent: true,
            showName: false,
            onTap: () => context.push(Routes.notesFormFor(l.id)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
