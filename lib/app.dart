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
    // Only what the app shell needs, so other settings changes don't
    // rebuild every screen.
    final settings = ref.watch(settingsProvider.select((s) => (s.locale, s.themeMode, s.gender)));

    // Before the user picks a language, follow the phone (Arabic if the phone
    // is in Arabic, otherwise English).
    final systemCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final locale = settings.$1 ?? Locale(systemCode == 'ar' ? 'ar' : 'en');

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
      themeMode: settings.$2,
      builder: (context, child) => StringsScope(
        s: S(ar: locale.languageCode == 'ar', female: settings.$3 == Gender.female),
        child: child!,
      ),
    );
  }
}
