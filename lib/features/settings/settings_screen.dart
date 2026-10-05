import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

const appVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final code = settings.locale?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(l10n.settingsLanguage),
          _ChoiceTile(
            label: l10n.languageArabic,
            selected: code == 'ar',
            onTap: () => notifier.setLocale(const Locale('ar')),
          ),
          _ChoiceTile(
            label: l10n.languageEnglish,
            selected: code == 'en',
            onTap: () => notifier.setLocale(const Locale('en')),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.settingsTextSize),
          ListTile(
            leading: const Icon(Icons.format_size, size: 32),
            title: Text(l10n.settingsTextSizeHint),
          ),
          const SizedBox(height: 16),
          _SectionTitle(l10n.settingsPreviewRole),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.settingsPreviewRoleHint, style: theme.textTheme.bodyMedium),
          ),
          _ChoiceTile(
            label: l10n.roleStudent,
            selected: settings.role == UserRole.student,
            onTap: () => _switchRole(context, ref, UserRole.student),
          ),
          _ChoiceTile(
            label: l10n.roleTeacher,
            selected: settings.role == UserRole.teacher,
            onTap: () => _switchRole(context, ref, UserRole.teacher),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(l10n.settingsSignOut),
            onPressed: () {
              notifier.signOut();
              context.go(Routes.welcome);
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsVersion(appVersion),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: SanadiColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _switchRole(BuildContext context, WidgetRef ref, UserRole role) {
    ref.read(settingsProvider.notifier).setRole(role);
    context.go(Routes.homeFor(role));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SanadiColors.green),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedColor: SanadiColors.green,
      selectedTileColor: SanadiColors.greenLight,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 30,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
