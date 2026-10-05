import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

/// Student home (spec §6.2 ST1): one giant "Recite now" button, then the
/// next portion and "my teacher" cards. Data is placeholder until Firebase.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const teachersOnline = 0;

    return Scaffold(
      appBar: SanadiAppBar(title: l10n.tabHome),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(l10n.greeting(l10n.guestName), style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          _ReciteNowButton(
            label: l10n.reciteNow,
            onPressed: () => showComingSoon(context),
          ),
          const SizedBox(height: 16),
          StatusLine(
            active: teachersOnline > 0,
            text: l10n.teachersAvailable(teachersOnline),
          ),
          const SizedBox(height: 24),
          InfoCard(
            icon: Icons.bookmark,
            title: l10n.nextPortionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.nextPortionEmpty, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.go(Routes.studentQuran),
                  icon: const Icon(Icons.menu_book),
                  label: Text(l10n.openInQuran),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InfoCard(
            icon: Icons.person_pin,
            title: l10n.myTeacherTitle,
            child: Text(l10n.myTeacherEmpty, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ReciteNowButton extends StatelessWidget {
  const _ReciteNowButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: SanadiColors.green,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: ConstrainedBox(
            // About 40% of the screen on a normal phone, never too small.
            constraints: BoxConstraints(minHeight: (height * 0.32).clamp(200, 320)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: SanadiColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, size: 64, color: SanadiColors.text),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
