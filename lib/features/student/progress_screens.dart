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

/// 26 · My progress: lessons so far, the juz recited in, the next portion and
/// recent lessons with the teacher's notes.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final lessons = ref.watch(lessonsProvider).value ?? const <Lesson>[];
    final q = ref.watch(quranProvider).value;
    final next = ref.watch(nextPortionProvider);

    if (lessons.isEmpty) {
      return StepScaffold(
        showBack: true,
        center: true,
        content: [
          EmptyState(icon: const Icon(Icons.insights_rounded), title: s.progressEmptyTitle, body: s.progressEmptyBody),
        ],
        bottom: [
          BigButton(
            label: s.recite,
            icon: Icons.mic_rounded,
            onPressed: () => context.pushReplacement(Routes.connecting),
          ),
        ],
      );
    }

    final minutes = lessons.fold(0, (m, l) => m + l.minutes);
    // Each ayah recited once counts once; the best grade decides a juz.
    final recited = <String>{};
    final juzBest = <int, int>{}; // juz -> 0 recited well, 1 needs practice
    if (q != null) {
      for (final l in lessons) {
        final p = l.notes?.recited;
        if (p == null) continue;
        final status = l.notes!.grade == 0 ? 1 : 0;
        for (var a = p.from; a <= p.to; a++) {
          final ayah = q.ayah(p.sura, a);
          if (ayah == null) continue;
          recited.add(ayah.key);
          final was = juzBest[ayah.juz];
          if (was == null || status < was) juzBest[ayah.juz] = status;
        }
      }
    }
    Color juzColor(int? st) => switch (st) {
      0 => t.primary,
      1 => t.gold,
      _ => t.surface,
    };

    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.myProgress, style: tt.headlineMedium),
        const SizedBox(height: 16),
        SCard(
          color: t.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.progressHeadline,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.onPrimary),
              ),
              WordSafeText(
                '${s.lessonsCount(lessons.length)} · ${s.minutesCount(minutes)}',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: t.onPrimary),
              ),
              if (recited.isNotEmpty)
                Text(
                  s.ayahsRecited(recited.length),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.onPrimary),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NextPortionCard(next: next, q: q),
        const SizedBox(height: 20),
        WordSafeText(s.juzLegendTitle, style: tt.titleLarge),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (var j = 1; j <= 30; j++)
              Semantics(
                label: '${s.juz(j)}: ${s.juzLegend[juzBest[j] ?? 2]}',
                excludeSemantics: true,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: juzColor(juzBest[j]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: juzBest[j] != null ? juzColor(juzBest[j]) : t.line, width: 2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.n(j),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: juzBest[j] != null ? t.onPrimary : t.text,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, c) in [(0, t.primary), (1, t.gold), (2, t.surface)])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: t.line, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s.juzLegend[i], style: tt.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        WordSafeText(s.recentL, style: tt.titleLarge),
        const SizedBox(height: 10),
        for (final l in lessons) ...[
          LessonCard(
            lesson: l,
            q: q,
            showStudent: false,
            onTap: (l.notes?.isEmpty ?? true) ? null : () => context.push(Routes.lessonNotes(l.id)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NextPortionCard extends StatelessWidget {
  const _NextPortionCard({required this.next, required this.q});

  final Portion? next;
  final QuranData? q;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final p = next;
    return SCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TintBox(child: Icon(Icons.bookmark_rounded, color: t.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nextPortionL, style: tt.bodyMedium!.copyWith(color: t.muted)),
                    if (p != null)
                      WordSafeText(portionText(s, q, p), style: tt.titleLarge)
                    else
                      Text(s.noNextYet, style: tt.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (p != null) ...[
            const SizedBox(height: 14),
            BigButton(
              label: s.openInQuran,
              iconWidget: const SIcon(SIcons.rehal),
              kind: ButtonKind.outline,
              onPressed: () => context.push(Routes.mushafAt(sura: p.sura, ayah: p.from)),
            ),
          ],
        ],
      ),
    );
  }
}

/// 25 · Notes from the teacher on one lesson.
class LessonNotesScreen extends ConsumerWidget {
  const LessonNotesScreen({super.key, this.lessonId});

  /// Without an id, the newest lesson with notes.
  final String? lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    final all = ref.watch(lessonsProvider).value ?? const <Lesson>[];
    final lesson = lessonId == null
        ? all.where((l) => !(l.notes?.isEmpty ?? true)).firstOrNull
        : all.where((l) => l.id == lessonId).firstOrNull;
    if (lesson == null) {
      return const StepScaffold(showBack: true, center: true, content: [Center(child: CircularProgressIndicator())]);
    }
    final n = lesson.notes ?? const LessonNotes();
    final recited = n.recited;
    final practise = [
      if (q != null && recited != null)
        for (final a in n.practise) ?q.ayah(recited.sura, a),
    ];

    return StepScaffold(
      showBack: true,
      content: [
        WordSafeText(s.notesFromName(lesson.teacherName), style: tt.headlineSmall),
        Text(s.lessonWhen(chatDay(context, lesson.at), lesson.minutes), style: tt.bodySmall),
        const SizedBox(height: 16),
        if (recited != null || n.grade != null) ...[
          SCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WordSafeText(s.recitedL, style: tt.bodySmall),
                      if (recited != null) WordSafeText(portionText(s, q, recited), style: tt.titleLarge),
                    ],
                  ),
                ),
                if (n.grade != null) Tag(text: s.grades[n.grade!.clamp(0, 2)], warn: n.grade == 0),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (practise.isNotEmpty) ...[
          WordSafeText(s.practiseL, style: tt.titleMedium),
          const SizedBox(height: 8),
          for (final a in practise) ...[
            SCard(
              onTap: () => context.push(Routes.mushafAt(sura: a.sura, ayah: a.ayah)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.ayahTitle(q!.sura(a.sura).name(s.ar), a.ayah),
                    style: nameFont(context, tt.titleSmall!.copyWith(color: t.primary)),
                  ),
                  const SizedBox(height: 6),
                  // Full ayah from the verified text, never cut.
                  Text(
                    a.text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: SanadiFonts.quran,
                      letterSpacing: 0,
                      fontSize: 24,
                      color: t.text,
                      height: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        if (n.note.isNotEmpty) ...[
          WordSafeText(s.teacherNoteL, style: tt.titleMedium),
          const SizedBox(height: 8),
          SCard(
            child: Text(n.note, textDirection: textDirectionOf(n.note), style: tt.bodyMedium),
          ),
          const SizedBox(height: 14),
        ],
        if (n.next != null)
          SCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.nextPortionL, style: tt.bodyMedium!.copyWith(color: t.muted)),
                WordSafeText(portionText(s, q, n.next!), style: tt.titleLarge),
                const SizedBox(height: 12),
                BigButton(
                  label: s.openInQuran,
                  iconWidget: const SIcon(SIcons.rehal),
                  onPressed: () => context.push(Routes.mushafAt(sura: n.next!.sura, ayah: n.next!.from)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
