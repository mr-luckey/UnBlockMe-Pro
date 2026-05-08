import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeTokens {
  static const Color bg = Color(0xFF0A101C);
  static const Color surf = Color(0xFF121A2A);
  static const Color card = Color(0xFF162236);
  static const Color card2 = Color(0xFF1D2C45);
  static const Color accentPink = Color(0xFFFF4D8D);
  static const Color accentPurple = Color(0xFF7D8CFF);
  static const Color accentCyan = Color(0xFF42C8FF);
  static const Color success = Color(0xFF00E5B0);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4444);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C4DE);
  static const Color border = Color(0xFF355073);
}

ThemeData createBlockedTheme(Brightness brightness, {required Color accent}) {
  final isDark = brightness == Brightness.dark;
  final accentHsl = HSLColor.fromColor(accent);
  final secondary = accentHsl
      .withHue((accentHsl.hue + 28) % 360)
      .withSaturation((accentHsl.saturation * 0.9).clamp(0.45, 0.9))
      .toColor();
  final tertiary = accentHsl
      .withHue((accentHsl.hue + 190) % 360)
      .withSaturation((accentHsl.saturation * 0.75).clamp(0.4, 0.85))
      .toColor();
  final card = accentHsl
      .withSaturation((accentHsl.saturation * 0.3).clamp(0.08, 0.38))
      .withLightness(isDark ? 0.2 : 0.96)
      .toColor();
  final card2 = accentHsl
      .withSaturation((accentHsl.saturation * 0.4).clamp(0.12, 0.5))
      .withLightness(isDark ? 0.26 : 0.92)
      .toColor();
  final border = accentHsl
      .withSaturation((accentHsl.saturation * 0.42).clamp(0.15, 0.6))
      .withLightness(isDark ? 0.44 : 0.75)
      .toColor();

  final scheme = ColorScheme(
    brightness: brightness,
    primary: accent,
    onPrimary: Colors.black,
    secondary: secondary,
    onSecondary: Colors.black,
    tertiary: tertiary,
    onTertiary: Colors.black,
    error: AppThemeTokens.error,
    onError: Colors.white,
    surface: isDark ? AppThemeTokens.surf : const Color(0xFFF3F6FB),
    onSurface: isDark ? AppThemeTokens.text : const Color(0xFF101828),
    background: isDark ? AppThemeTokens.bg : const Color(0xFFEAF0F8),
    onBackground: isDark ? AppThemeTokens.text : const Color(0xFF101828),
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
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppThemeTokens.text,
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
      labelStyle: const TextStyle(color: AppThemeTokens.text),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: card2,
      contentTextStyle: const TextStyle(color: AppThemeTokens.text),
    ),
  );
}
