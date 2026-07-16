import 'package:flutter/material.dart';

class ThemePreset {
  const ThemePreset({
    required this.name,
    // Brand/action color used for primary buttons and key highlights.
    required this.primary,
    // Text/icon color displayed on top of primary color surfaces.
    required this.onPrimary,
    // Supportive accent color for secondary emphasis.
    required this.secondary,
    // Text/icon color displayed on top of secondary color surfaces.
    required this.onSecondary,
    // Tertiary accent used for reward, celebration and supportive UI accents.
    required this.tertiary,
    // Text/icon color displayed on top of tertiary color surfaces.
    required this.onTertiary,
    // Full-screen app background (dark mode).
    required this.darkBackground,
    // Main container surface (dark mode).
    required this.darkSurface,
    // Card background (dark mode).
    required this.darkCard,
    // Elevated card/chip background (dark mode).
    required this.darkCard2,
    // Borders/dividers (dark mode).
    required this.darkBorder,
    // Primary readable text color (dark mode).
    required this.darkOnSurface,
    // Secondary/subtitle readable text color (dark mode).
    required this.darkOnSurfaceVariant,
    // Full-screen app background (light mode).
    required this.lightBackground,
    // Main container surface (light mode).
    required this.lightSurface,
    // Card background (light mode).
    required this.lightCard,
    // Elevated card/chip background (light mode).
    required this.lightCard2,
    // Borders/dividers (light mode).
    required this.lightBorder,
    // Primary readable text color (light mode).
    required this.lightOnSurface,
    // Secondary/subtitle readable text color (light mode).
    required this.lightOnSurfaceVariant,
  });

  final String name;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;
  final Color onTertiary;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkCard;
  final Color darkCard2;
  final Color darkBorder;
  final Color darkOnSurface;
  final Color darkOnSurfaceVariant;
  final Color lightBackground;
  final Color lightSurface;
  final Color lightCard;
  final Color lightCard2;
  final Color lightBorder;
  final Color lightOnSurface;
  final Color lightOnSurfaceVariant;
}

class ThemePresets {
  // ─────────────────────────────────────────────────────────────────────────
  // THEME: "Carved Oak"
  // A single fixed theme (color picker removed) — a warm, tactile wooden
  // game-table look, fitting for a sliding wood-block puzzle.
  //
  // Psychology: Deep walnut/espresso background = a cozy, focused game table,
  // no cold "app" feel. Brass-gold primary = polished hardware/game-piece
  // metal, reads instantly as an interactive "press me" color against dark
  // wood. Burnt-copper secondary = warm leather/varnish accent that supports
  // primary without competing. Bright harvest-gold tertiary = coin/trophy
  // reward color for stars, completions and celebration moments.
  // Color families: Brass-Gold (primary) + Copper (secondary) +
  // Harvest-Gold (tertiary) on Deep Walnut (background) — an analogous warm
  // wood palette with a metallic "game piece" pop.
  // ─────────────────────────────────────────────────────────────────────────
  static const ThemePreset wood = ThemePreset(
    name: 'Carved Oak',
    // Polished brass-gold — the "press me" hardware color for buttons/blocks
    primary: Color(0xFFD79A44),
    // Deep espresso — readable on brass-gold
    onPrimary: Color(0xFF2A1608),
    // Burnt copper — warm supportive accent, leather/varnish feel
    secondary: Color(0xFFC17A42),
    // Deep espresso — readable on copper
    onSecondary: Color(0xFF2A1608),
    // Harvest gold — coin/trophy reward color for stars & celebrations
    tertiary: Color(0xFFF2B93B),
    // Deep espresso-brown — readable on harvest gold
    onTertiary: Color(0xFF2A1A00),
    // Deep stained walnut — immersive wooden game-table background (dark)
    darkBackground: Color(0xFF1B1108),
    // Lifted walnut — main container surface (dark)
    darkSurface: Color(0xFF26170D),
    // Card-level wood grain — puzzle board / cards (dark)
    darkCard: Color(0xFF32210F),
    // Elevated wood grain — chips, highlighted elements (dark)
    darkCard2: Color(0xFF402B15),
    // Warm grain-line brown — borders & dividers visible against dark wood
    darkBorder: Color(0xFF6E4826),
    // Warm parchment white — primary readable text (dark mode)
    darkOnSurface: Color(0xFFFBF1E3),
    // Muted tan — subtitles/secondary text (dark mode)
    darkOnSurfaceVariant: Color(0xFFCBA97C),
    // Pale birch cream — full background (light mode)
    lightBackground: Color(0xFFF8EFDD),
    // Near-pure warm white — main surface (light mode)
    lightSurface: Color(0xFFFFFBF3),
    // Light pale oak — card background (light mode)
    lightCard: Color(0xFFEFDDBC),
    // Slightly deeper oak — elevated card (light mode)
    lightCard2: Color(0xFFE4CC9C),
    // Medium tan-brown — borders (light mode)
    lightBorder: Color(0xFFC9A164),
    // Deep walnut dark — primary text (light mode)
    lightOnSurface: Color(0xFF2E1C0C),
    // Medium warm brown — secondary/subtitle text (light mode)
    lightOnSurfaceVariant: Color(0xFF6E4C29),
  );

  static const List<ThemePreset> all = [wood];

  static ThemePreset resolveByColor(Color color) {
    for (final preset in all) {
      if (preset.primary.value == color.value) {
        return preset;
      }
    }
    return all.first;
  }
}
