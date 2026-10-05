import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

class ShellTab {
  const ShellTab({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations l10n) label;
}

final studentTabs = <ShellTab>[
  ShellTab(icon: Icons.home_outlined, selectedIcon: Icons.home, label: (l) => l.tabHome),
  ShellTab(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: (l) => l.tabQuran),
  ShellTab(icon: Icons.wb_sunny_outlined, selectedIcon: Icons.wb_sunny, label: (l) => l.tabAthkar),
  ShellTab(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: (l) => l.tabMessages),
];

final teacherTabs = <ShellTab>[
  ShellTab(icon: Icons.home_outlined, selectedIcon: Icons.home, label: (l) => l.tabHome),
  ShellTab(icon: Icons.groups_outlined, selectedIcon: Icons.groups, label: (l) => l.tabStudents),
  ShellTab(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: (l) => l.tabQuran),
  ShellTab(icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: (l) => l.tabMessages),
];

/// Bottom navigation with 4 labelled tabs. The selected tab is shown by
/// colour, a filled icon and the indicator pill, never colour alone.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell, required this.tabs});

  final StatefulNavigationShell shell;
  final List<ShellTab> tabs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label(l10n),
            ),
        ],
      ),
    );
  }
}
