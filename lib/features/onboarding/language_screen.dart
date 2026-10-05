import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import 'app_title.dart';

/// First screen on first launch. Shown in both languages because the user
/// hasn't chosen one yet.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.read(settingsProvider.notifier);

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
                  const SizedBox(height: 48),
                  Text(
                    'اختر لغتك',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'IBMPlexSansArabic'),
                  ),
                  Text(
                    'Choose your language',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'AtkinsonHyperlegible'),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => settings.setLocale(const Locale('ar')),
                    child: const Text(
                      'العربية',
                      style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: SanadiColors.gold,
                      foregroundColor: SanadiColors.text,
                    ),
                    onPressed: () => settings.setLocale(const Locale('en')),
                    child: const Text(
                      'English',
                      style: TextStyle(fontFamily: 'AtkinsonHyperlegible'),
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
