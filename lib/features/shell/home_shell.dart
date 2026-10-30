import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../backend/admin.dart';
import '../../backend/chat.dart';
import '../../core/background.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../settings/more_screens.dart';
import '../student/availability_bar.dart';

/// Bottom tabs. Student: Home · Teachers (with Messages inside) · Quran ·
/// Athkar, with the teacher availability bar above Quran and Athkar.
/// Teacher: Home · Students · Quran · Messages (athkar is reached from Quran).
/// Labels stay on one line (capped at 130% text size, then shrunk to fit).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell, required this.teacher});

  final StatefulNavigationShell shell;
  final bool teacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final unread = ref.watch(unreadTotalProvider);
    // Opening the app counts as being active today (for the admins).
    ref.watch(markActiveProvider);
    final home = (const Icon(Icons.home_rounded), s.navHome);
    final quran = (const SIcon(SIcons.rehal), s.navQuran);
    final messages = (const Icon(Icons.chat_bubble_rounded), s.navMessages);
    final items = teacher
        ? [home, (const SIcon(SIcons.students), s.navStudents), quran, messages]
        : [home, (const Icon(Icons.school_rounded), s.navTeachers), quran, (const SIcon(SIcons.misbaha), s.navAthkar)];

    // A paused account sees why on its home tab; the Quran, athkar and
    // messages stay open (the server refuses new messages and calls).
    final paused = ref.watch(pausedProvider).value ?? false;
    // While a teacher is available, Back on the home tabs keeps Sanadi
    // running in the background, so calls can still ring.
    return ValueListenableBuilder<bool>(
      valueListenable: Background.listening,
      builder: (context, listening, child) => PopScope(
        canPop: !(teacher && listening),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Background.moveToBack();
        },
        child: child!,
      ),
      child: Scaffold(
        body: paused && shell.currentIndex == 0 ? const _PausedView() : shell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Students see who is free from Quran and Athkar (Home and
            // Teachers show it themselves).
            if (!teacher && !paused && shell.currentIndex >= 2) const AvailabilityBar(),
            _TabBar(
              items: items,
              // Unread messages show on Messages (teachers) or Teachers (students).
              badges: {teacher ? items.length - 1 : 1: unread},
              selected: shell.currentIndex,
              onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
          ],
        ),
      ),
    );
  }
}

class _PausedView extends StatelessWidget {
  const _PausedView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tt = Theme.of(context).textTheme;
    return StepScaffold(
      center: true,
      content: [
        const Center(child: Illustration(size: 120, child: Icon(Icons.pause_circle_rounded))),
        const SizedBox(height: 20),
        WordSafeText(s.pausedTitle, style: tt.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(s.pausedBody, style: tt.bodyLarge, textAlign: TextAlign.center),
      ],
      bottom: [
        BigButton(
          label: s.contactUs,
          icon: Icons.mail_rounded,
          kind: ButtonKind.outline,
          onPressed: () => contactSanadi(context, subject: 'Sanadi: my account is paused'),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.items, required this.selected, required this.onSelect, this.badges = const {}});

  final List<(Widget, String)> items;

  /// Unread counts shown on tabs, by tab index.
  final Map<int, int> badges;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = S.of(context);
    final ar = context.isAr;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Material(
        color: t.surface,
        elevation: 3,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: i == selected,
                      button: true,
                      label: (badges[i] ?? 0) > 0 ? '${items[i].$2}, ${s.n(badges[i]!)}' : items[i].$2,
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: i == selected ? t.tint : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconTheme(
                                  data: IconThemeData(size: 28, color: i == selected ? t.primary : t.muted),
                                  child: Center(
                                    child: (badges[i] ?? 0) > 0
                                        ? Badge(
                                            label: Text(
                                              s.n(badges[i]! > 99 ? 99 : badges[i]!),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                            ),
                                            backgroundColor: t.warn,
                                            textColor: t.onWarn,
                                            child: items[i].$1,
                                          )
                                        : items[i].$1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              WordSafeText(
                                items[i].$2,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: ar ? 16 : 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: i == selected ? t.primary : t.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
