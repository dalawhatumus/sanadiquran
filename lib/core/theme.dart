import 'package:flutter/material.dart';

/// Design tokens from the approved Claude Design system (Phase 1).
/// Light and dark values match the design files exactly.
@immutable
class SanadiTokens extends ThemeExtension<SanadiTokens> {
  const SanadiTokens({
    required this.bg,
    required this.surface,
    required this.line,
    required this.text,
    required this.heading,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.tint,
    required this.sage,
    required this.warn,
    required this.onWarn,
    required this.warnTint,
    required this.warnLine,
    required this.gold,
    required this.offLine,
    required this.disabledBg,
    required this.disabledInk,
    required this.micBg,
    required this.lockBg,
    required this.deep,
  });

  final Color bg;
  final Color surface;
  final Color line;
  final Color text;
  final Color heading;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color tint;
  final Color sage;
  final Color warn;
  final Color onWarn;
  final Color warnTint;
  final Color warnLine;
  final Color gold;
  final Color offLine;
  final Color disabledBg;
  final Color disabledInk;
  final Color micBg;
  final Color lockBg;

  /// Avatar circles and the splash background.
  final Color deep;

  static const light = SanadiTokens(
    bg: Color(0xFFF4F0E8),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFDDE8E1),
    text: Color(0xFF1E3A40),
    heading: Color(0xFF0D4A3C),
    muted: Color(0xFF4F6F60),
    primary: Color(0xFF026C3B),
    onPrimary: Color(0xFFFFFFFF),
    tint: Color(0xFFDDE8E1),
    sage: Color(0xFF8FAE9E),
    warn: Color(0xFFA04A0A),
    onWarn: Color(0xFFFFFFFF),
    warnTint: Color(0xFFFBEFE4),
    warnLine: Color(0xFFE7C9AE),
    gold: Color(0xFFB88A2E),
    offLine: Color(0xFFC9CFC9),
    disabledBg: Color(0xFFE6E2D9),
    disabledInk: Color(0xFF4F6F60),
    micBg: Color(0xFFF4F0E8),
    lockBg: Color(0xFF1E3A40),
    deep: Color(0xFF0D4A3C),
  );

  static const dark = SanadiTokens(
    bg: Color(0xFF101C19),
    surface: Color(0xFF172622),
    line: Color(0xFF23392F),
    text: Color(0xFFECE7DC),
    heading: Color(0xFFA8DCBD),
    muted: Color(0xFFA9BDB2),
    primary: Color(0xFF5CC18A),
    onPrimary: Color(0xFF0B1A14),
    tint: Color(0xFF23392F),
    sage: Color(0xFF3E5A4E),
    warn: Color(0xFFE08A4A),
    onWarn: Color(0xFF1A0E05),
    warnTint: Color(0xFF2A1E14),
    warnLine: Color(0xFF5A3A22),
    gold: Color(0xFFC9A24A),
    offLine: Color(0xFF3E5A4E),
    disabledBg: Color(0xFF1F302B),
    disabledInk: Color(0xFFA9BDB2),
    micBg: Color(0xFF0B1A14),
    lockBg: Color(0xFF0A1311),
    deep: Color(0xFFA8DCBD),
  );

  @override
  SanadiTokens copyWith() => this;

  @override
  SanadiTokens lerp(SanadiTokens? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension SanadiThemeX on BuildContext {
  SanadiTokens get t => Theme.of(this).extension<SanadiTokens>()!;
  bool get isAr => Directionality.of(this) == TextDirection.rtl;
}

/// Font families. Quran text always uses KFGQPC; dhikr uses Noto Naskh.
abstract final class SanadiFonts {
  static const quran = 'KFGQPC';
  static const naskh = 'NotoNaskhArabic';
  static String ui(Locale locale) => locale.languageCode == 'ar' ? 'Tajawal' : 'Montserrat';
}

/// Smallest touch target for elderly users (brief: 56dp, buttons ~64dp).
const double kMinTap = 56;
const double kButtonHeight = 64;

ThemeData buildTheme(Locale locale, Brightness brightness) {
  final tk = brightness == Brightness.dark ? SanadiTokens.dark : SanadiTokens.light;
  final family = SanadiFonts.ui(locale);
  final ar = locale.languageCode == 'ar';

  // Each UI font falls back to the other, so Arabic on an English screen
  // (and Latin on an Arabic one) still uses a brand font.
  final fallback = [ar ? 'Montserrat' : 'Tajawal'];
  TextStyle s(double size, FontWeight w, Color c, [double h = 1.35]) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: size,
    fontWeight: w,
    color: c,
    height: ar ? h + 0.1 : h,
    // Spread extra line height evenly above and below, so text sits in the
    // vertical centre of buttons and pills.
    leadingDistribution: TextLeadingDistribution.even,
  );

  const m = FontWeight.w500;
  const b = FontWeight.w700;
  final textTheme = TextTheme(
    displaySmall: s(40, b, tk.heading, 1.2),
    headlineLarge: s(32, b, tk.heading, 1.25),
    headlineMedium: s(28, b, tk.heading, 1.25),
    headlineSmall: s(24, b, tk.heading, 1.3),
    titleLarge: s(22, b, tk.heading, 1.3),
    titleMedium: s(20, b, tk.text, 1.3),
    titleSmall: s(18, b, tk.text, 1.3),
    bodyLarge: s(20, m, tk.text, 1.45),
    bodyMedium: s(18, m, tk.text, 1.45),
    bodySmall: s(16, m, tk.muted, 1.4),
    labelLarge: s(22, b, tk.text, 1.2),
    labelMedium: s(16, b, tk.text, 1.2),
    labelSmall: s(14, b, tk.muted, 1.2),
  );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: tk.primary,
    onPrimary: tk.onPrimary,
    secondary: tk.heading,
    onSecondary: tk.onPrimary,
    error: tk.warn,
    onError: tk.onWarn,
    surface: tk.bg,
    onSurface: tk.text,
    surfaceContainerHighest: tk.surface,
    outline: tk.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tk.bg,
    fontFamily: family,
    textTheme: textTheme,
    extensions: [tk],
    splashFactory: InkSparkle.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tk.heading,
      contentTextStyle: s(18, m, tk.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tk.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tk.surface,
      showDragHandle: true,
      dragHandleColor: tk.offLine,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (st) => st.contains(WidgetState.selected) ? tk.onPrimary : tk.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? tk.primary : tk.offLine),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tk.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      hintStyle: s(20, m, tk.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tk.muted, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tk.muted, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tk.primary, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tk.warn, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: tk.warn, width: 3),
      ),
      errorStyle: s(18, m, tk.warn),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tk.surface,
      indicatorColor: tk.tint,
      surfaceTintColor: Colors.transparent,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(size: 28, color: st.contains(WidgetState.selected) ? tk.primary : tk.muted),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => s(ar ? 16 : 14, b, st.contains(WidgetState.selected) ? tk.primary : tk.muted, 1.1),
      ),
    ),
  );
}
