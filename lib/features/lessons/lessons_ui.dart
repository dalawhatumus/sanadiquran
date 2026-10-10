import 'package:flutter/material.dart';

import '../../backend/sessions.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';
import '../quran/quran_data.dart';
import '../quran/surah_index_screen.dart';

/// "Al-Mulk 11–20" (or the surah number while the Quran is loading).
String portionText(S s, QuranData? q, Portion p) =>
    s.portionName(q == null ? s.n(p.sura) : q.sura(p.sura).name(s.ar), p.from, p.to);

/// A small rounded label, e.g. a grade or "Notes".
class Tag extends StatelessWidget {
  const Tag({super.key, required this.text, this.icon, this.warn = false});

  final String text;
  final IconData? icon;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final color = warn ? t.warn : t.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.heading),
            ),
          ),
        ],
      ),
    );
  }
}

/// One lesson in a history list: when, with whom, what was recited, grade.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.q,
    required this.showStudent,
    this.showName = true,
    this.onTap,
  });

  final Lesson lesson;
  final QuranData? q;

  /// Teachers see the student's name; students see the teacher's.
  final bool showStudent;

  /// Off on a page that is already about one person.
  final bool showName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final n = lesson.notes;
    final who = showStudent ? lesson.studentName : lesson.teacherName;
    return SCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.lessonWhen(chatDay(context, lesson.at), lesson.minutes)} · $who', style: tt.bodySmall),
                WordSafeText(
                  n?.recited != null ? portionText(s, q, n!.recited!) : (n == null ? s.noNotes : s.notesTag),
                  style: tt.titleMedium!.copyWith(color: t.heading),
                ),
                if (n != null && (n.grade != null || !n.isEmpty)) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (n.grade != null) Tag(text: s.grades[n.grade!.clamp(0, 2)], warn: n.grade == 0),
                      if (n.note.isNotEmpty || n.practise.isNotEmpty)
                        Tag(text: s.notesTag, icon: Icons.sticky_note_2_rounded),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) Icon(Arrows.next, color: t.primary, size: 32),
        ],
      ),
    );
  }
}

/// Bottom sheet listing the 114 surahs; returns the chosen surah number.
Future<int?> pickSurah(BuildContext context, QuranData q) {
  final s = S.of(context);
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: WordSafeText(s.chooseSurah, style: Theme.of(ctx).textTheme.headlineSmall),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: q.suras.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => SurahTile(sura: q.suras[i], onTap: () => Navigator.pop(ctx, i + 1)),
            ),
          ),
        ],
      ),
    ),
  );
}
