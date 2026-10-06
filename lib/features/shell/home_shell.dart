import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../widgets/ui.dart';

/// Bottom tabs. Student: Home · Quran · Athkar · Messages.
/// Teacher: Home · Students · Quran · Messages (athkar is reached from Quran).
/// Tab labels are capped at 130% text size (approved in the design review).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell, required this.teacher});

  final StatefulNavigationShell shell;
  final bool teacher;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final home = NavigationDestination(icon: const Icon(Icons.home_rounded, size: 28), label: s.navHome);
    final quran = NavigationDestination(icon: const SIcon(SIcons.rehal), label: s.navQuran);
    final messages = NavigationDestination(icon: const Icon(Icons.chat_bubble_rounded, size: 28), label: s.navMessages);
    final destinations = teacher
        ? [home, NavigationDestination(icon: const SIcon(SIcons.students), label: s.navStudents), quran, messages]
        : [home, quran, NavigationDestination(icon: const SIcon(SIcons.misbaha), label: s.navAthkar), messages];

    return Scaffold(
      body: shell,
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: destinations,
        ),
      ),
    );
  }
}
