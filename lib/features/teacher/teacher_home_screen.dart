import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/backend.dart';
import '../../backend/sessions.dart';
import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../settings/more_screens.dart';
import '../../widgets/ui.dart';

/// 30 · Teacher home, plus 15 (application pending) and 16 (not approved).
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final settings = ref.watch(settingsProvider);
    const header = HomeHeader();
    final body = switch (settings.teacherStatus) {
      TeacherStatus.pending || TeacherStatus.none => _pending(context, s),
      TeacherStatus.rejected => _rejected(context, ref, s),
      TeacherStatus.approved => _approved(context, ref, s, settings),
    };
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [header, const SizedBox(height: 16), ...body],
        ),
      ),
    );
  }

  List<Widget> _pending(BuildContext context, S s) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return [
      SCard(
        color: t.tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.hourglass_top_rounded, color: t.primary, size: 40),
            const SizedBox(height: 10),
            WordSafeText(s.reviewTitle, style: tt.titleLarge),
            const SizedBox(height: 6),
            Text(s.reviewBody, style: tt.bodyMedium),
          ],
        ),
      ),
      const SizedBox(height: 20),
      WordSafeText(s.whileWait, style: tt.titleMedium),
      const SizedBox(height: 10),
      _LinkCard(
        icon: SIcon(SIcons.rehal, color: t.primary),
        label: s.openMushaf,
        onTap: () => context.go(Routes.teacherQuran),
      ),
      const SizedBox(height: 10),
      _LinkCard(
        icon: SIcon(SIcons.misbaha, color: t.primary),
        label: s.athkarTitle,
        onTap: () => context.push(Routes.athkar),
      ),
    ];
  }

  List<Widget> _rejected(BuildContext context, WidgetRef ref, S s) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return [
      const Center(child: Illustration(size: 112, child: Icon(Icons.volunteer_activism_rounded))),
      const SizedBox(height: 16),
      WordSafeText(s.rejectTitle, style: tt.headlineSmall, textAlign: TextAlign.center),
      const SizedBox(height: 6),
      Text(s.rejectThanks, style: tt.bodyMedium, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      SCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.reason, style: tt.titleSmall!.copyWith(color: t.muted)),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                // The admin's own words when they gave a reason.
                final reason = ref.watch(applicationReasonProvider).value ?? '';
                return Text(reason.isEmpty ? s.rejectReason : reason, style: tt.bodyMedium);
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      BigButton(
        label: s.applyAgain,
        icon: Icons.replay_rounded,
        onPressed: () {
          ref.read(settingsProvider.notifier).update((x) => x.copyWith(teacherStatus: TeacherStatus.none));
          context.go('${Routes.apply}/1');
        },
      ),
      const SizedBox(height: 10),
      BigButton(
        label: s.contactUs,
        icon: Icons.mail_rounded,
        kind: ButtonKind.outline,
        onPressed: () => contactSanadi(context),
      ),
    ];
  }

  List<Widget> _approved(BuildContext context, WidgetRef ref, S s, AppSettings settings) {
    final t = context.t;
    final live = ref.watch(backendProvider).live;
    final now = DateTime.now();
    final today = [
      for (final l in ref.watch(lessonsProvider).value ?? const <Lesson>[])
        if (DateUtils.isSameDay(l.at, now)) l,
    ];
    final tt = Theme.of(context).textTheme;
    final on = settings.available;
    void toggle() => ref.read(settingsProvider.notifier).update((x) => x.copyWith(available: !on));
    final fg = on ? t.onPrimary : t.text;
    return [
      Semantics(
        toggled: on,
        button: true,
        child: SCard(
          color: on ? t.primary : t.surface,
          border: on ? t.gold : t.muted,
          onTap: toggle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(on ? Icons.check_circle_rounded : Icons.remove_circle_rounded, color: fg, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    on ? s.on : s.off,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
                  ),
                  const Spacer(),
                  ExcludeSemantics(
                    child: Switch(
                      value: on,
                      onChanged: (_) => toggle(),
                      thumbColor: WidgetStateProperty.all(on ? t.primary : t.surface),
                      trackColor: WidgetStateProperty.all(on ? t.onPrimary : t.offLine),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                on ? s.availOn : s.availOff,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: fg, height: 1.25),
              ),
              const SizedBox(height: 6),
              Text(
                on ? s.availOnSub : s.availOffSub,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: fg),
              ),
            ],
          ),
        ),
      ),
      if (live && on) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.info_rounded, color: t.muted, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(s.keepOpen, style: tt.bodySmall)),
          ],
        ),
      ],
      const SizedBox(height: 14),
      SCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.today, style: tt.bodyMedium!.copyWith(color: t.muted)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Stat(value: s.n(today.length), label: s.sessionsL),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(value: s.n(today.fold<int>(0, (m, l) => m + l.minutes)), label: s.minutesL),
                ),
              ],
            ),
          ],
        ),
      ),
      // Sample only: "students waiting" needs notifications (a later update).
      if (!live) ...[
        const SizedBox(height: 14),
        SCard(
          child: Row(
            children: [
              TintBox(size: 52, circle: true, child: SIcon(SIcons.students, color: t.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.waiting, style: tt.titleSmall),
                    if (!on) Text(s.waitingOff, style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      if (!live) ...[
        const SizedBox(height: 20),
        BigButton(
          label: s.simulateCall,
          icon: Icons.call_received_rounded,
          kind: ButtonKind.tint,
          onPressed: () => context.push(Routes.incoming),
        ),
      ],
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WordSafeText(
            value,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: t.heading, height: 1.1),
          ),
          WordSafeText(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.label, required this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SCard(
      onTap: onTap,
      child: Row(
        children: [
          TintBox(child: icon),
          const SizedBox(width: 14),
          Expanded(
            child: WordSafeText(label, style: Theme.of(context).textTheme.titleLarge!.copyWith(color: t.text)),
          ),
          Icon(Arrows.next, color: t.primary, size: 32),
        ],
      ),
    );
  }
}
