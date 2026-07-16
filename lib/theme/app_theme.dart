import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_presets.dart';

ThemeData createBlockedTheme(Brightness brightness) {
  const appError = Color(0xFFFF5252);
  final isDark = brightness == Brightness.dark;
  final preset = ThemePresets.wood;
  final card = isDark ? preset.darkCard : preset.lightCard;
  final card2 = isDark ? preset.darkCard2 : preset.lightCard2;
  final border = isDark ? preset.darkBorder : preset.lightBorder;
  final onSurface = isDark ? preset.darkOnSurface : preset.lightOnSurface;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: preset.primary,
    onPrimary: preset.onPrimary,
    secondary: preset.secondary,
    onSecondary: preset.onSecondary,
    tertiary: preset.tertiary,
    onTertiary: preset.onTertiary,
    error: appError,
    onError: Colors.white,
    surface: isDark ? preset.darkSurface : preset.lightSurface,
    onSurface: onSurface,
    background: isDark ? preset.darkBackground : preset.lightBackground,
    onBackground: onSurface,
  );

  final baseText = GoogleFonts.dmSansTextTheme(
    ThemeData.dark(useMaterial3: true).textTheme,
  ).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  final textTheme = baseText.copyWith(
    displayLarge: GoogleFonts.orbitron(
      textStyle: baseText.displayLarge,
      fontWeight: FontWeight.w800,
      fontSize: 44,
      letterSpacing: 1.2,
    ),
    displayMedium: GoogleFonts.orbitron(
      textStyle: baseText.displayMedium,
      fontWeight: FontWeight.w800,
      fontSize: 34,
      letterSpacing: 1.1,
    ),
    displaySmall: GoogleFonts.orbitron(
      textStyle: baseText.displaySmall,
      fontWeight: FontWeight.w700,
      fontSize: 26,
      letterSpacing: 0.8,
    ),
    headlineSmall: GoogleFonts.orbitron(
      textStyle: baseText.headlineSmall,
      fontWeight: FontWeight.w700,
      fontSize: 24,
    ),
    titleLarge: GoogleFonts.dmSans(
      textStyle: baseText.titleLarge,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    titleMedium: GoogleFonts.dmSans(
      textStyle: baseText.titleMedium,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    bodyLarge: GoogleFonts.dmSans(
      textStyle: baseText.bodyLarge,
      fontSize: 16,
    ),
    bodyMedium: GoogleFonts.dmSans(
      textStyle: baseText.bodyMedium,
      fontSize: 14,
    ),
    bodySmall: GoogleFonts.dmSans(
      textStyle: baseText.bodySmall,
      fontSize: 12,
    ),
    labelLarge: GoogleFonts.dmSans(
      textStyle: baseText.labelLarge,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: GoogleFonts.dmSans(
      textStyle: baseText.labelMedium,
      fontSize: 12,
    ),
    labelSmall: GoogleFonts.dmSans(
      textStyle: baseText.labelSmall,
      fontSize: 11,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.background,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: border),
        backgroundColor: card,
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        foregroundColor: scheme.tertiary,
      ),
    ),
    dividerTheme: DividerThemeData(color: border),
    chipTheme: ChipThemeData(
      backgroundColor: card2,
      labelStyle: TextStyle(color: onSurface),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: card2,
      contentTextStyle: TextStyle(color: onSurface),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withOpacity(0.28),
      selectionHandleColor: scheme.primary,
    ),
  );
}
