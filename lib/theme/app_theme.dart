import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeTokens {
  static const Color bg = Color(0xFF06060F);
  static const Color surf = Color(0xFF0F0F1E);
  static const Color card = Color(0xFF13132B);
  static const Color card2 = Color(0xFF1A1A38);
  static const Color accentPink = Color(0xFFFF2D78);
  static const Color accentPurple = Color(0xFF9B5DFF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color success = Color(0xFF00E5B0);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4444);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8080A0);
  static const Color border = Color(0xFF2D2D50);
}

ThemeData createBlockedTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppThemeTokens.accentPink,
    onPrimary: Colors.white,
    secondary: AppThemeTokens.accentPurple,
    onSecondary: Colors.white,
    tertiary: AppThemeTokens.accentCyan,
    onTertiary: Colors.black,
    error: AppThemeTokens.error,
    onError: Colors.white,
    surface: isDark ? AppThemeTokens.surf : const Color(0xFFF5F3FF),
    onSurface: isDark ? AppThemeTokens.text : const Color(0xFF151226),
    background: isDark ? AppThemeTokens.bg : const Color(0xFFEDEAFD),
    onBackground: isDark ? AppThemeTokens.text : const Color(0xFF151226),
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
      color: AppThemeTokens.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppThemeTokens.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppThemeTokens.text,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        backgroundColor: AppThemeTokens.accentPink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: const BorderSide(color: AppThemeTokens.border),
        backgroundColor: AppThemeTokens.card,
        foregroundColor: AppThemeTokens.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        foregroundColor: AppThemeTokens.accentCyan,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppThemeTokens.border),
    chipTheme: ChipThemeData(
      backgroundColor: AppThemeTokens.card2,
      labelStyle: const TextStyle(color: AppThemeTokens.text),
      side: const BorderSide(color: AppThemeTokens.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppThemeTokens.card2,
      contentTextStyle: TextStyle(color: AppThemeTokens.text),
    ),
  );
}
