import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/reminders.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import 'athkar_data.dart';

/// 45 · Athkar menu: reminder card and 6 full-width buttons.
class AthkarMenuScreen extends ConsumerWidget {
  const AthkarMenuScreen({super.key, this.standalone = false});

  /// Teachers open athkar from the Quran tab, so it gets a Back button.
  final bool standalone;

  static Widget iconFor(String id, Color c) => switch (id) {
    'morning' => Icon(Icons.light_mode_rounded, color: c),
    'evening' => Icon(Icons.nights_stay_rounded, color: c),
    'salah' => SIcon(SIcons.prayerMat, color: c),
    'tasbeeh' => SIcon(SIcons.misbaha, color: c),
    'sleep' => SIcon(SIcons.moonPillow, color: c),
    _ => SIcon(SIcons.waking, color: c),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(settingsProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (standalone)
              Align(alignment: AlignmentDirectional.centerStart, child: const BackPill())
            else
              Row(
                children: [
                  Expanded(child: WordSafeText(s.athkarTitle, style: tt.headlineMedium)),
                  const SettingsChip(),
                ],
              ),
            if (standalone) ...[const SizedBox(height: 12), WordSafeText(s.athkarTitle, style: tt.headlineMedium)],
            const SizedBox(height: 16),
            if (settings.remindersOn)
              SCard(
                color: t.tint,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notifications_rounded, color: t.primary, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.nextReminder, style: tt.bodyMedium),
                          Builder(
                            builder: (context) {
                              final (morning, at) = nextReminder(ref.watch(reminderTimesProvider));
                              return WordSafeText(
                                s.reminderAt(morning, MaterialLocalizations.of(context).formatTimeOfDay(at)),
                                style: tt.titleSmall,
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => showReminderSheet(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(96, 52),
                              side: BorderSide(color: t.primary, width: 2),
                              foregroundColor: t.primary,
                              backgroundColor: t.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(s.change, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              SCard(
                border: t.muted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_off_rounded, color: t.text, size: 28),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.remindersOff, style: tt.titleSmall)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BigButton(
                      label: s.turnOnReminders,
                      icon: Icons.notifications_rounded,
                      kind: ButtonKind.outline,
                      onPressed: () =>
                          ref.read(settingsProvider.notifier).update((st) => st.copyWith(remindersOn: true)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            for (final set in athkarSets) ...[
              SCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => context.push('${Routes.athkar}/${set.id}'),
                child: Row(
                  children: [
                    TintBox(size: 56, circle: true, child: iconFor(set.id, t.primary)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WordSafeText(_label(s, set), style: tt.titleLarge!.copyWith(color: t.text)),
                          if (settings.athkarDone[set.id] == today)
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: t.primary, size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    s.doneToday,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.primary),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Icon(Arrows.next, color: t.primary, size: 32),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  static String _label(S s, AthkarSet set) => s.t(
    const {
      'morning': 'Morning',
      'evening': 'Evening',
      'salah': 'After salah',
      'tasbeeh': 'Tasbeeh',
      'sleep': 'Before sleep',
      'waking': 'On waking',
    }[set.id]!,
    const {
      'morning': 'أذكار الصباح',
      'evening': 'أذكار المساء',
      'salah': 'بعد الصلاة',
      'tasbeeh': 'التسبيح',
      'sleep': 'قبل النوم',
      'waking': 'عند الاستيقاظ',
    }[set.id]!,
  );
}

/// Reminders on or off, and their times.
void showReminderSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final s = S.of(ctx);
        final t = ctx.t;
        final tt = Theme.of(ctx).textTheme;
        final on = ref.watch(settingsProvider.select((x) => x.remindersOn));
        final times = ref.watch(reminderTimesProvider);
        final l = MaterialLocalizations.of(ctx);
        Widget timeRow(String label, TimeOfDay at, ValueChanged<TimeOfDay> set) => SCard(
          onTap: on
              ? () async {
                  final picked = await showTimePicker(context: ctx, initialTime: at);
                  if (picked != null) set(picked);
                }
              : null,
          child: Row(
            children: [
              Expanded(child: WordSafeText(label, style: tt.titleMedium)),
              Text(
                s.n(l.formatTimeOfDay(at)),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: on ? t.primary : t.muted),
              ),
            ],
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: WordSafeText(s.remindersL, style: tt.headlineSmall)),
                  Switch(
                    value: on,
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((x) => x.copyWith(remindersOn: v)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(s.reminderTimesHint, style: tt.bodySmall),
              const SizedBox(height: 14),
              timeRow(s.morningAthkar, times.morningTime, ref.read(reminderTimesProvider.notifier).setMorning),
              const SizedBox(height: 10),
              timeRow(s.eveningAthkar, times.eveningTime, ref.read(reminderTimesProvider.notifier).setEvening),
            ],
          ),
        );
      },
    ),
  );
}
