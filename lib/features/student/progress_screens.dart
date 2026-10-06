import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../quran/quran_data.dart';

/// 26 · My progress (sample data in this test build).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final empty = ref.watch(settingsProvider).sessions == 0;

    if (empty) {
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

    // Sample: juz 30 and 29 memorised, 28 in progress.
    Color juzColor(int j) => j >= 29 ? t.primary : (j == 28 ? t.gold : t.surface);
    return StepScaffold(
      showBack: true,
      content: [
        Text(s.myProgress, style: tt.headlineMedium),
        const SizedBox(height: 16),
        SCard(
          color: t.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.memorisedL,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: t.onPrimary),
              ),
              Text(
                s.progressSummary,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: t.onPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(s.juzL, style: tt.titleLarge),
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
                label: '${s.juz(j)}: ${j >= 29 ? s.legend[0] : (j == 28 ? s.legend[1] : s.legend[2])}',
                excludeSemantics: true,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: juzColor(j),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: j >= 28 ? juzColor(j) : t.line, width: 2),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.n(j),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: j >= 28 ? t.onPrimary : t.text,
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
              Row(
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
                  Expanded(child: Text(s.legend[i], style: tt.bodySmall)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 20),
        SCard(
          child: Row(
            children: [
              TintBox(child: Icon(Icons.bookmark_rounded, color: t.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nextPortionL, style: tt.bodyMedium!.copyWith(color: t.muted)),
                    Text(s.nextPortion, style: tt.titleLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(s.recentL, style: tt.titleLarge),
        const SizedBox(height: 10),
        for (final (day, what, grade, notes) in s.recentSessions) ...[
          SCard(
            onTap: notes ? () => context.push(Routes.teacherNotes) : null,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day, style: tt.bodySmall),
                      Text(what, style: tt.titleMedium!.copyWith(color: t.heading)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _Tag(text: grade),
                          if (notes) _Tag(text: s.notesTag, icon: Icons.sticky_note_2_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                if (notes)
                  Icon(
                    context.isAr ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    color: t.primary,
                    size: 32,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.check_circle_rounded, size: 18, color: t.primary),
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

/// 25 · Teacher's notes, shown only when a teacher added notes.
class TeacherNotesScreen extends ConsumerWidget {
  const TeacherNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final q = ref.watch(quranProvider).value;
    final practise = q == null ? const <Ayah>[] : [q.ayah(67, 3)!, q.ayah(67, 7)!];

    return StepScaffold(
      showBack: true,
      content: [
        Text(s.tnTitle, style: tt.headlineSmall),
        Text(s.tnSub, style: tt.bodySmall),
        const SizedBox(height: 16),
        SCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.recitedL, style: tt.bodySmall),
                    Text(s.recited, style: tt.titleLarge),
                  ],
                ),
              ),
              _Tag(text: s.gradeGood),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(s.practiseL, style: tt.titleMedium),
        const SizedBox(height: 8),
        for (final a in practise) ...[
          SCard(
            onTap: () => context.push(Routes.mushafAt(sura: a.sura, ayah: a.ayah)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.ayahTitle(q!.sura(67).name(s.ar), a.ayah), style: tt.titleSmall!.copyWith(color: t.primary)),
                const SizedBox(height: 6),
                // Full ayah from the verified text, never cut.
                Text(
                  a.text,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: SanadiFonts.quran, fontSize: 24, color: t.text, height: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Text(s.teacherNoteL, style: tt.titleMedium),
        const SizedBox(height: 8),
        SCard(child: Text(s.noteText, style: tt.bodyMedium)),
        const SizedBox(height: 14),
        SCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.nextPortionL, style: tt.bodyMedium!.copyWith(color: t.muted)),
              Text(s.nextPortion, style: tt.titleLarge),
              const SizedBox(height: 12),
              BigButton(
                label: s.openInQuran,
                iconWidget: const SIcon(SIcons.rehal),
                onPressed: () => context.push(Routes.mushafAt(sura: 67, ayah: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
