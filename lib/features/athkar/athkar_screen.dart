import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

/// Athkar menu (spec §6.5): six full-width buttons with icons. The dhikr
/// screens with tap counters come in the athkar milestone.
class AthkarScreen extends StatelessWidget {
  const AthkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = <(IconData, String)>[
      (Icons.wb_sunny, l10n.athkarMorning),
      (Icons.nights_stay, l10n.athkarEvening),
      (Icons.mosque, l10n.athkarAfterSalah),
      (Icons.touch_app, l10n.athkarTasbeeh),
      (Icons.bedtime, l10n.athkarSleep),
      (Icons.wb_twilight, l10n.athkarWaking),
    ];

    return Scaffold(
      appBar: SanadiAppBar(title: l10n.athkarTitle),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (icon, label) = categories[i];
          return _AthkarButton(
            icon: icon,
            label: label,
            onTap: () => showComingSoon(context),
          );
        },
      ),
    );
  }
}

class _AthkarButton extends StatelessWidget {
  const _AthkarButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadius),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: SanadiColors.greenLight,
                  child: Icon(icon, size: 30, color: SanadiColors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.titleMedium),
                ),
                const Icon(Icons.chevron_right, size: 32, color: SanadiColors.green),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
