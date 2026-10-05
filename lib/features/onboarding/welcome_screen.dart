import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import 'app_title.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppTitle(),
                  const SizedBox(height: 24),
                  Text(
                    l10n.appTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  // Google sign-in is wired up in the Firebase milestone; for
                  // now this continues straight to the role question.
                  FilledButton.icon(
                    onPressed: () => context.push(Routes.role),
                    icon: const Icon(Icons.login, size: 28),
                    label: Text(l10n.continueWithGoogle),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => showComingSoon(context),
                        child: Text(l10n.privacyPolicy),
                      ),
                      TextButton(
                        onPressed: () => showComingSoon(context),
                        child: Text(l10n.terms),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.language),
                        onPressed: () => ref
                            .read(settingsProvider.notifier)
                            .setLocale(Locale(isArabic ? 'en' : 'ar')),
                        label: Text(isArabic ? l10n.languageEnglish : l10n.languageArabic),
                      ),
                    ],
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
