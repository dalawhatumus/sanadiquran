import 'package:flutter/material.dart';

/// Brand colours from docs/SPEC.md §11. Busy/warning states use dark orange,
/// never bright red.
abstract final class SanadiColors {
  static const green = Color(0xFF1F5E4B);
  static const greenLight = Color(0xFFDCEBE4);
  static const gold = Color(0xFFC8A04A);
  static const goldLight = Color(0xFFF4E9CF);
  static const background = Color(0xFFFAF7F0);
  static const text = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF4A4A4A);
  static const away = Color(0xFF6B6B6B);
  static const warning = Color(0xFFB4530A);
}

/// Minimum tap target from the spec (56dp); we go a bit larger for
/// primary actions.
const double kMinTapTarget = 56;
const double kPrimaryButtonHeight = 64;
const double kRadius = 16;

ThemeData buildTheme(Locale locale) {
  final isArabic = locale.languageCode == 'ar';
  final family = isArabic ? 'IBMPlexSansArabic' : 'AtkinsonHyperlegible';
  final fallback = [isArabic ? 'AtkinsonHyperlegible' : 'IBMPlexSansArabic'];

  final scheme = ColorScheme.fromSeed(
    seedColor: SanadiColors.green,
    primary: SanadiColors.green,
    onPrimary: Colors.white,
    secondary: SanadiColors.gold,
    onSecondary: SanadiColors.text,
    surface: SanadiColors.background,
    onSurface: SanadiColors.text,
    onSurfaceVariant: SanadiColors.textMuted,
    error: SanadiColors.warning,
  );

  // Body text never below 18sp (spec §3). The system font scale is applied
  // on top of these sizes automatically.
  const textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.3),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.3),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
    bodyLarge: TextStyle(fontSize: 20, height: 1.5),
    bodyMedium: TextStyle(fontSize: 18, height: 1.5),
    bodySmall: TextStyle(fontSize: 18, height: 1.5),
    labelLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    labelSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );

  final themedText = textTheme.apply(
    fontFamily: family,
    fontFamilyFallback: fallback,
    bodyColor: SanadiColors.text,
    displayColor: SanadiColors.text,
  );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius));
  final buttonText = themedText.labelLarge;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SanadiColors.background,
    fontFamily: family,
    fontFamilyFallback: fallback,
    textTheme: themedText,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: SanadiColors.background,
      foregroundColor: SanadiColors.text,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 72,
      titleTextStyle: themedText.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kPrimaryButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: buttonText,
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        foregroundColor: SanadiColors.green,
        side: const BorderSide(color: SanadiColors.green, width: 2),
        textStyle: buttonText,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        foregroundColor: SanadiColors.green,
        textStyle: themedText.labelMedium,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: shape,
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 14,
      minTileHeight: kMinTapTarget + 16,
      titleTextStyle: themedText.bodyLarge,
      subtitleTextStyle: themedText.bodyMedium?.copyWith(color: SanadiColors.textMuted),
      iconColor: SanadiColors.green,
      shape: shape,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 84,
      backgroundColor: Colors.white,
      indicatorColor: SanadiColors.goldLight,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => themedText.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected)
              ? SanadiColors.green
              : SanadiColors.textMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 30,
          color: states.contains(WidgetState.selected)
              ? SanadiColors.green
              : SanadiColors.textMuted,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: shape,
      titleTextStyle: themedText.titleLarge,
      contentTextStyle: themedText.bodyLarge,
    ),
  );
}
