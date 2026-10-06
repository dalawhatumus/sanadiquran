import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/settings.dart';
import 'core/strings.dart';
import 'core/theme.dart';

class SanadiApp extends ConsumerWidget {
  const SanadiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // Before the user picks a language, follow the phone (Arabic if the phone
    // is in Arabic, otherwise English).
    final systemCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final locale = settings.locale ?? Locale(systemCode == 'ar' ? 'ar' : 'en');

    return MaterialApp.router(
      title: 'Sanadi',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(locale, Brightness.light),
      darkTheme: buildTheme(locale, Brightness.dark),
      themeMode: settings.themeMode,
      builder: (context, child) => StringsScope(s: StringsScope.fromSettings(settings, locale), child: child!),
    );
  }
}
