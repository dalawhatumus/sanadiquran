import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';

class SanadiApp extends ConsumerWidget {
  const SanadiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final chosen = ref.watch(settingsProvider.select((s) => s.locale));

    // Before the user picks a language, follow the phone (Arabic if the phone
    // is in Arabic, otherwise English).
    final systemCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final locale = chosen ?? Locale(systemCode == 'ar' ? 'ar' : 'en');

    return MaterialApp.router(
      title: 'Sanadi',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(locale),
    );
  }
}
