import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/teachers.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../messages/messages_screen.dart';
import '../quran/quran_data.dart';
import 'teacher_alert.dart';
import 'teachers_screen.dart';

/// "Continue reading": the surah and page last read, one tap from the mushaf.
class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final page = ref.watch(lastPageProvider);
    final q = ref.watch(quranProvider).value;
    final sura = q?.sura(q.firstOn(page).sura).name(s.ar);
    return SCard(
      onTap: () => context.push(Routes.mushafAt(page: page)),
      child: Row(
        children: [
          TintBox(child: SIcon(SIcons.rehal, color: t.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WordSafeText(s.continueReading, style: tt.titleMedium!.copyWith(color: t.heading)),
                Text(sura == null ? s.page(page) : s.readingAt(sura, page), style: nameFont(context, tt.bodyMedium!)),
              ],
            ),
          ),
          Icon(Arrows.next, color: t.primary, size: 32),
        ],
      ),
    );
  }
}

/// "Alert me when a teacher is free" (for an hour).
class TeacherAlertCard extends ConsumerWidget {
  const TeacherAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final until = ref.watch(teacherAlertProvider);
    final on = until != null;
    final alert = ref.read(teacherAlertProvider.notifier);
    return Semantics(
      toggled: on,
      button: true,
      child: SCard(
        onTap: on ? alert.turnOff : alert.turnOn,
        child: Row(
          children: [
            Icon(
              on ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              color: on ? t.primary : t.muted,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WordSafeText(s.alertTitle, style: tt.titleMedium!.copyWith(color: t.heading)),
                  const SizedBox(height: 2),
                  WordSafeText(
                    on
                        ? s.alertOnUntil(
                            MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(until)),
                          )
                        : s.alertSub,
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
            ExcludeSemantics(
              child: Switch(value: on, onChanged: (v) => v ? alert.turnOn() : alert.turnOff()),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of teachers (free ones first) with "See all".
class TeachersRow extends ConsumerWidget {
  const TeachersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final gender = ref.watch(settingsProvider.select((x) => x.gender)) ?? Gender.female;
    final list = ref.watch(teachersProvider(gender)).value ?? const <TeacherEntry>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: WordSafeText(s.teachersTitle, style: tt.titleLarge)),
            TextButton(
              onPressed: () => context.push(Routes.teachers),
              style: TextButton.styleFrom(minimumSize: const Size(kMinTap, kMinTap)),
              child: Text(
                s.seeAll,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: t.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Cards size to their content (the word-safe text can't be measured
        // ahead), aligned at the top.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final x in list.take(8)) ...[_TeacherCard(teacher: x), const SizedBox(width: 12)],
            ],
          ),
        ),
      ],
    );
  }
}

class _TeacherCard extends ConsumerWidget {
  const _TeacherCard({required this.teacher});

  final TeacherEntry teacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    final x = teacher;
    final name = x.name.isEmpty ? '—' : x.name;
    final free = x.state == TeacherState.available;
    return SizedBox(
      width: 172,
      child: SCard(
        onTap: () => context.push(Routes.teachers),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(initialOf(name), size: 72, image: x.avatar, ring: free),
            const SizedBox(height: 8),
            FullName(name, style: tt.titleMedium!, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            TeacherStatePill(state: x.state),
            if (free) ...[
              const SizedBox(height: 10),
              BigButton(
                label: s.call,
                icon: Icons.call_rounded,
                compact: true,
                onPressed: () => callTeacher(context, ref, x),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
