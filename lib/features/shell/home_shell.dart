import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

/// Bottom tabs. Student: Home · Quran · Athkar · Messages.
/// Teacher: Home · Students · Quran · Messages (athkar is reached from Quran).
/// Labels stay on one line (capped at 130% text size, then shrunk to fit).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell, required this.teacher});

  final StatefulNavigationShell shell;
  final bool teacher;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final home = (const Icon(Icons.home_rounded), s.navHome);
    final quran = (const SIcon(SIcons.rehal), s.navQuran);
    final messages = (const Icon(Icons.chat_bubble_rounded), s.navMessages);
    final items = teacher
        ? [home, (const SIcon(SIcons.students), s.navStudents), quran, messages]
        : [home, quran, (const SIcon(SIcons.misbaha), s.navAthkar), messages];

    return Scaffold(
      body: shell,
      bottomNavigationBar: _TabBar(
        items: items,
        selected: shell.currentIndex,
        onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.items, required this.selected, required this.onSelect});

  final List<(Widget, String)> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
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
                      label: items[i].$2,
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
                                  child: Center(child: items[i].$1),
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
