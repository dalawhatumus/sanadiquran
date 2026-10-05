import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// Onboarding step 1 (spec §6.1 S4): student or teacher.
class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l10n.roleQuestion, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            _RoleCard(
              icon: Icons.record_voice_over,
              title: l10n.roleStudent,
              hint: l10n.roleStudentHint,
              selected: _selected == UserRole.student,
              onTap: () => setState(() => _selected = UserRole.student),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              icon: Icons.school,
              title: l10n.roleTeacher,
              hint: l10n.roleTeacherHint,
              selected: _selected == UserRole.teacher,
              onTap: () => setState(() => _selected = UserRole.teacher),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _selected == null
                  ? null
                  : () => ref.read(settingsProvider.notifier).setRole(_selected!),
              child: Text(l10n.next),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? SanadiColors.greenLight : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: BorderSide(
            color: selected ? SanadiColors.green : SanadiColors.away.withValues(alpha: 0.4),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 44, color: SanadiColors.green),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(hint, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 32,
                  color: selected ? SanadiColors.green : SanadiColors.away,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
