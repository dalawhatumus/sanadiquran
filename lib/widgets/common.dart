import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// App bar used on every tab: title on the start side, profile button on the
/// end side (spec §5: settings live behind the avatar, not a "More" tab).
class SanadiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SanadiAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      title: Text(title),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: IconButton(
            tooltip: l10n.profile,
            iconSize: 32,
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            style: IconButton.styleFrom(
              backgroundColor: SanadiColors.greenLight,
              foregroundColor: SanadiColors.green,
            ),
            icon: const Icon(Icons.person),
            onPressed: () => context.push(Routes.settings),
          ),
        ),
      ],
    );
  }
}

/// White rounded card with an icon + title header.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.child,
    this.color,
  });

  final IconData icon;
  final String title;
  final Widget? child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: SanadiColors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered icon + message for screens that have nothing to show yet.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: SanadiColors.greenLight,
              child: Icon(icon, size: 56, color: SanadiColors.green),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for features that are not built yet.
Future<void> showComingSoon(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.comingSoon),
      content: Text(l10n.comingSoonBody),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}

/// Small coloured dot + text, used for availability lines.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.active, required this.text});

  final bool active;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? SanadiColors.green : SanadiColors.away,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
