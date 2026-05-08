// import 'package:flutter/material.dart';

// class ThemePreset {
//   const ThemePreset({
//     required this.name,
//     // Brand/action color used for primary buttons and key highlights.
//     required this.primary,
//     // Text/icon color displayed on top of primary color surfaces.
//     required this.onPrimary,
//     // Supportive accent color for secondary emphasis.
//     required this.secondary,
//     // Text/icon color displayed on top of secondary color surfaces.
//     required this.onSecondary,
//     // Tertiary accent used for reward, celebration and supportive UI accents.
//     required this.tertiary,
//     // Text/icon color displayed on top of tertiary color surfaces.
//     required this.onTertiary,
//     // Full-screen app background (dark mode).
//     required this.darkBackground,
//     // Main container surface (dark mode).
//     required this.darkSurface,
//     // Card background (dark mode).
//     required this.darkCard,
//     // Elevated card/chip background (dark mode).
//     required this.darkCard2,
//     // Borders/dividers (dark mode).
//     required this.darkBorder,
//     // Primary readable text color (dark mode).
//     required this.darkOnSurface,
//     // Secondary/subtitle readable text color (dark mode).
//     required this.darkOnSurfaceVariant,
//     // Full-screen app background (light mode).
//     required this.lightBackground,
//     // Main container surface (light mode).
//     required this.lightSurface,
//     // Card background (light mode).
//     required this.lightCard,
//     // Elevated card/chip background (light mode).
//     required this.lightCard2,
//     // Borders/dividers (light mode).
//     required this.lightBorder,
//     // Primary readable text color (light mode).
//     required this.lightOnSurface,
//     // Secondary/subtitle readable text color (light mode).
//     required this.lightOnSurfaceVariant,
//   });

//   final String name;
//   final Color primary;
//   final Color onPrimary;
//   final Color secondary;
//   final Color onSecondary;
//   final Color tertiary;
//   final Color onTertiary;
//   final Color darkBackground;
//   final Color darkSurface;
//   final Color darkCard;
//   final Color darkCard2;
//   final Color darkBorder;
//   final Color darkOnSurface;
//   final Color darkOnSurfaceVariant;
//   final Color lightBackground;
//   final Color lightSurface;
//   final Color lightCard;
//   final Color lightCard2;
//   final Color lightBorder;
//   final Color lightOnSurface;
//   final Color lightOnSurfaceVariant;
// }

// class ThemePresets {
//   static const List<ThemePreset> all = [
//     ThemePreset(
//       name: 'Calm Blue',
//       primary: Color(0xFF5B8DEF),
//       onPrimary: Color(0xFF0B1220),
//       secondary: Color(0xFF7AA3F2),
//       onSecondary: Color(0xFF0B1220),
//       tertiary: Color(0xFF86C5F6),
//       onTertiary: Color(0xFF0B1220),
//       darkBackground: Color(0xFF101A2B),
//       darkSurface: Color(0xFF17243A),
//       darkCard: Color(0xFF1D2E49),
//       darkCard2: Color(0xFF24395A),
//       darkBorder: Color(0xFF3C5E8E),
//       darkOnSurface: Color(0xFFF4F8FF),
//       darkOnSurfaceVariant: Color(0xFFBFCDE3),
//       lightBackground: Color(0xFFF1F6FF),
//       lightSurface: Color(0xFFFBFDFF),
//       lightCard: Color(0xFFE9F1FF),
//       lightCard2: Color(0xFFDDE9FF),
//       lightBorder: Color(0xFFB8CBEA),
//       lightOnSurface: Color(0xFF0F1D33),
//       lightOnSurfaceVariant: Color(0xFF4A607F),
//     ),
//     ThemePreset(
//       name: 'Soft Teal',
//       primary: Color(0xFF42AFA2),
//       onPrimary: Color(0xFF081A18),
//       secondary: Color(0xFF65C3B8),
//       onSecondary: Color(0xFF081A18),
//       tertiary: Color(0xFF8ED7CB),
//       onTertiary: Color(0xFF081A18),
//       darkBackground: Color(0xFF0F1D1C),
//       darkSurface: Color(0xFF172928),
//       darkCard: Color(0xFF1D3433),
//       darkCard2: Color(0xFF254140),
//       darkBorder: Color(0xFF3B6F6B),
//       darkOnSurface: Color(0xFFF2FCFA),
//       darkOnSurfaceVariant: Color(0xFFBEDDD8),
//       lightBackground: Color(0xFFF1FAF8),
//       lightSurface: Color(0xFFFAFEFD),
//       lightCard: Color(0xFFE5F4F1),
//       lightCard2: Color(0xFFD9ECE8),
//       lightBorder: Color(0xFFB4D4CF),
//       lightOnSurface: Color(0xFF112A27),
//       lightOnSurfaceVariant: Color(0xFF4A6D69),
//     ),
//     ThemePreset(
//       name: 'Gentle Green',
//       primary: Color(0xFF6BBF7A),
//       onPrimary: Color(0xFF0D1D10),
//       secondary: Color(0xFF8BCF97),
//       onSecondary: Color(0xFF0D1D10),
//       tertiary: Color(0xFFB0E3B7),
//       onTertiary: Color(0xFF0D1D10),
//       darkBackground: Color(0xFF111E16),
//       darkSurface: Color(0xFF1A2A20),
//       darkCard: Color(0xFF223628),
//       darkCard2: Color(0xFF2A4432),
//       darkBorder: Color(0xFF4C7653),
//       darkOnSurface: Color(0xFFF4FCF6),
//       darkOnSurfaceVariant: Color(0xFFC5DEC8),
//       lightBackground: Color(0xFFF3FAF4),
//       lightSurface: Color(0xFFFCFEFC),
//       lightCard: Color(0xFFE8F4EA),
//       lightCard2: Color(0xFFDDEADF),
//       lightBorder: Color(0xFFBFD6C2),
//       lightOnSurface: Color(0xFF162919),
//       lightOnSurfaceVariant: Color(0xFF507254),
//     ),
//     ThemePreset(
//       name: 'Dusty Steel',
//       primary: Color(0xFF8FA4C7),
//       onPrimary: Color(0xFF111826),
//       secondary: Color(0xFFA8BAD4),
//       onSecondary: Color(0xFF111826),
//       tertiary: Color(0xFFC4D1E3),
//       onTertiary: Color(0xFF111826),
//       darkBackground: Color(0xFF131A24),
//       darkSurface: Color(0xFF1D2736),
//       darkCard: Color(0xFF253244),
//       darkCard2: Color(0xFF2E3E54),
//       darkBorder: Color(0xFF536B8F),
//       darkOnSurface: Color(0xFFF5F8FD),
//       darkOnSurfaceVariant: Color(0xFFC7D2E3),
//       lightBackground: Color(0xFFF3F6FB),
//       lightSurface: Color(0xFFFCFDFF),
//       lightCard: Color(0xFFE9EEF7),
//       lightCard2: Color(0xFFDFE6F3),
//       lightBorder: Color(0xFFC0CBE0),
//       lightOnSurface: Color(0xFF1A2536),
//       lightOnSurfaceVariant: Color(0xFF556983),
//     ),
//     ThemePreset(
//       name: 'Muted Lavender',
//       primary: Color(0xFFA48EDB),
//       onPrimary: Color(0xFF181125),
//       secondary: Color(0xFFB7A6E4),
//       onSecondary: Color(0xFF181125),
//       tertiary: Color(0xFFCBBEEA),
//       onTertiary: Color(0xFF181125),
//       darkBackground: Color(0xFF191626),
//       darkSurface: Color(0xFF241F37),
//       darkCard: Color(0xFF2E2746),
//       darkCard2: Color(0xFF3A3157),
//       darkBorder: Color(0xFF65558D),
//       darkOnSurface: Color(0xFFF8F5FD),
//       darkOnSurfaceVariant: Color(0xFFD4CBE7),
//       lightBackground: Color(0xFFF7F3FC),
//       lightSurface: Color(0xFFFDFBFF),
//       lightCard: Color(0xFFF0EAF8),
//       lightCard2: Color(0xFFE7DEF2),
//       lightBorder: Color(0xFFCDC1DF),
//       lightOnSurface: Color(0xFF2A2240),
//       lightOnSurfaceVariant: Color(0xFF6A5B86),
//     ),
//     ThemePreset(
//       name: 'Warm Sand',
//       primary: Color(0xFFE3A96F),
//       onPrimary: Color(0xFF23170B),
//       secondary: Color(0xFFEABD8E),
//       onSecondary: Color(0xFF23170B),
//       tertiary: Color(0xFFF0D1AE),
//       onTertiary: Color(0xFF23170B),
//       darkBackground: Color(0xFF221A13),
//       darkSurface: Color(0xFF31251C),
//       darkCard: Color(0xFF3D2F23),
//       darkCard2: Color(0xFF4B3A2C),
//       darkBorder: Color(0xFF82664C),
//       darkOnSurface: Color(0xFFFFF8F2),
//       darkOnSurfaceVariant: Color(0xFFE4D2C2),
//       lightBackground: Color(0xFFFCF7F2),
//       lightSurface: Color(0xFFFFFCFA),
//       lightCard: Color(0xFFF7ECE1),
//       lightCard2: Color(0xFFF0E1D2),
//       lightBorder: Color(0xFFDCC5AF),
//       lightOnSurface: Color(0xFF3A2A1A),
//       lightOnSurfaceVariant: Color(0xFF7D624A),
//     ),
//     ThemePreset(
//       name: 'Sky Blue',
//       primary: Color(0xFF5FA7D6),
//       onPrimary: Color(0xFF0B1823),
//       secondary: Color(0xFF7DBADE),
//       onSecondary: Color(0xFF0B1823),
//       tertiary: Color(0xFFA3D1EC),
//       onTertiary: Color(0xFF0B1823),
//       darkBackground: Color(0xFF101B27),
//       darkSurface: Color(0xFF182839),
//       darkCard: Color(0xFF203448),
//       darkCard2: Color(0xFF29405A),
//       darkBorder: Color(0xFF467097),
//       darkOnSurface: Color(0xFFF4FAFF),
//       darkOnSurfaceVariant: Color(0xFFC2D8E9),
//       lightBackground: Color(0xFFF1F8FD),
//       lightSurface: Color(0xFFFBFEFF),
//       lightCard: Color(0xFFE6F1F8),
//       lightCard2: Color(0xFFD9E9F4),
//       lightBorder: Color(0xFFB6CFE0),
//       lightOnSurface: Color(0xFF122638),
//       lightOnSurfaceVariant: Color(0xFF4D6F88),
//     ),
//   ];

//   static ThemePreset resolveByColor(Color color) {
//     for (final preset in all) {
//       if (preset.primary.value == color.value) {
//         return preset;
//       }
//     }
//     return all.first;
//   }
// }
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
  static const List<ThemePreset> all = [
    // ─────────────────────────────────────────────────────────────────────────
    // THEME 1: "Ember Night"
    // Psychology: Orange-red triggers urgency & action (perfect for puzzle CTA).
    // Gold tertiary = reward/celebration dopamine hit on level complete.
    // Near-black warm background = full focus/immersion, no distraction.
    // Color families: Warm Orange (primary) + Gold (tertiary) on Cool Charcoal bg.
    // Contrast: Electric warm vs deep dark = maximum visual punch.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Ember Night',
      // Vivid orange-red — urgency, "move the block!" action energy
      primary: Color(0xFFE8572A),
      // Near-black warm dark — readable on orange-red
      onPrimary: Color(0xFF1A0A04),
      // Warm amber — supportive warm accent, not competing with primary
      secondary: Color(0xFFF09A3E),
      // Near-black warm dark — readable on amber
      onSecondary: Color(0xFF1A0A04),
      // Golden yellow — reward, celebration, level-complete feel (dopamine)
      tertiary: Color(0xFFF5D05B),
      // Near-black — readable on gold
      onTertiary: Color(0xFF1A1000),
      // Very dark warm charcoal — full-screen immersive game background (dark)
      darkBackground: Color(0xFF130C07),
      // Slightly lifted warm dark — main container surface (dark)
      darkSurface: Color(0xFF1E1410),
      // Card-level warm dark — puzzle board card background (dark)
      darkCard: Color(0xFF2A1C14),
      // Elevated warm dark — chips, highlighted cards (dark)
      darkCard2: Color(0xFF362618),
      // Burnt sienna border — dividers & outlines visible against dark bg
      darkBorder: Color(0xFF6B3D20),
      // Warm white — primary readable text (dark mode)
      darkOnSurface: Color(0xFFFFF5EE),
      // Muted warm cream — subtitles, secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFFD4A882),
      // Warm cream white — full-screen background (light mode)
      lightBackground: Color(0xFFFFF6F0),
      // Near-pure warm white — main surface (light mode)
      lightSurface: Color(0xFFFFFBF9),
      // Pale peach — card background (light mode)
      lightCard: Color(0xFFFFE8D8),
      // Slightly deeper peach — elevated card (light mode)
      lightCard2: Color(0xFFFFD8C4),
      // Warm terracotta light — borders & dividers (light mode)
      lightBorder: Color(0xFFF0B490),
      // Deep warm dark brown — primary text (light mode)
      lightOnSurface: Color(0xFF2D1106),
      // Medium warm brown — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF7A4228),
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // THEME 2: "Neon Noir"
    // Psychology: Cyan on near-black = high-tech focus. Hot pink = excitement
    // burst for interactive elements. Lime = energy, youth, completion.
    // Color families: Cyan (primary) + Magenta (secondary) + Lime (tertiary)
    // — triadic contrast, maximum visual energy for gamers.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Neon Noir',
      // Electric cyan — high-tech, futuristic action color for buttons/blocks
      primary: Color(0xFF00E5D4),
      // Deep near-black teal — readable on bright cyan
      onPrimary: Color(0xFF001A18),
      // Hot magenta pink — electric accent, excitement for secondary UI
      secondary: Color(0xFFFF4DC4),
      // Deep dark — readable on hot pink
      onSecondary: Color(0xFF1A0010),
      // Electric lime — high-energy reward/celebration (completion moments)
      tertiary: Color(0xFFAAFF57),
      // Deep forest dark — readable on electric lime
      onTertiary: Color(0xFF0A1500),
      // Near-black with blue undertone — game immersion background (dark)
      darkBackground: Color(0xFF060810),
      // Slightly lifted midnight blue — main container (dark)
      darkSurface: Color(0xFF0E1220),
      // Card-level deep navy — puzzle board background (dark)
      darkCard: Color(0xFF141828),
      // Elevated deep navy — chips and highlighted cards (dark)
      darkCard2: Color(0xFF1C2235),
      // Deep blue-purple — borders & dividers (dark)
      darkBorder: Color(0xFF2C3A60),
      // Crisp ice white — primary text (dark mode, max contrast)
      darkOnSurface: Color(0xFFF0FEFF),
      // Muted cyan-grey — subtitles/secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFF88BCC8),
      // Light ice blue-white — full background (light mode)
      lightBackground: Color(0xFFF0FDFC),
      // Near-pure white with cyan hint — main surface (light mode)
      lightSurface: Color(0xFFFAFFFE),
      // Pale aqua — card background (light mode)
      lightCard: Color(0xFFDEF7F4),
      // Slightly deeper aqua — elevated card (light mode)
      lightCard2: Color(0xFFCCEFEB),
      // Medium teal — borders (light mode)
      lightBorder: Color(0xFF88D0CA),
      // Near-black cyan-dark — primary text (light mode)
      lightOnSurface: Color(0xFF041414),
      // Dark teal — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF2E6860),
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // THEME 3: "Forest Dusk"
    // Psychology: Deep forest green = calm focus & nature immersion.
    // Coral/salmon primary = warm human energy standing out from cool bg —
    // high contrast complementary pair (red-orange vs green).
    // Gold tertiary = achievement glow (reward system).
    // Color families: Coral (primary) on Deep Forest (bg) = complementary.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Forest Dusk',
      // Vivid coral-salmon — warm, exciting action color on cool green bg
      primary: Color(0xFFFF6B4A),
      // Very dark near-black warm — readable on coral
      onPrimary: Color(0xFF1A0600),
      // Warm peach — supportive softer accent for secondary UI
      secondary: Color(0xFFFFAB7A),
      // Very dark warm — readable on peach
      onSecondary: Color(0xFF1A0800),
      // Amber-gold — warm reward/achievement celebration color
      tertiary: Color(0xFFFFCA44),
      // Deep warm dark — readable on amber gold
      onTertiary: Color(0xFF1A0C00),
      // Deep forest green — immersive nature game background (dark)
      darkBackground: Color(0xFF091510),
      // Lifted forest green — main container surface (dark)
      darkSurface: Color(0xFF111E18),
      // Card-level forest — puzzle board cards (dark)
      darkCard: Color(0xFF192A20),
      // Elevated forest card — chips, highlighted elements (dark)
      darkCard2: Color(0xFF21382A),
      // Forest mid-tone — borders & dividers (dark)
      darkBorder: Color(0xFF3A6444),
      // Crisp light green-white — primary text (dark mode)
      darkOnSurface: Color(0xFFF4FFF6),
      // Muted sage — subtitles/secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFFA0C8A8),
      // Pale mint green — full background (light mode)
      lightBackground: Color(0xFFF2FFF4),
      // Near-pure white mint — main surface (light mode)
      lightSurface: Color(0xFFFBFFFB),
      // Light sage — card background (light mode)
      lightCard: Color(0xFFE4F5E6),
      // Slightly deeper sage — elevated card (light mode)
      lightCard2: Color(0xFFD4EAD7),
      // Medium sage green — borders (light mode)
      lightBorder: Color(0xFFA0C8A5),
      // Deep forest dark — primary text (light mode)
      lightOnSurface: Color(0xFF0A1E0C),
      // Medium forest — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF3A6040),
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // THEME 4: "Cosmic Indigo"
    // Psychology: Deep space indigo = mystery, depth, premium feel.
    // Electric yellow on deep purple = MAXIMUM contrast (complementary split).
    // Yellow triggers fastest human eye response — instant readability.
    // Coral secondary = warm counterbalance to cool purple bg.
    // Cyan tertiary = space/tech cool celebration.
    // Color families: Yellow (primary) + Coral (secondary) + Cyan (tertiary)
    // on Deep Purple (bg) = triadic contrast on complementary base.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Cosmic Indigo',
      // Electric yellow — fastest color the eye processes, max contrast on purple
      primary: Color(0xFFFFE040),
      // Near-black warm — readable on electric yellow
      onPrimary: Color(0xFF1A1400),
      // Vivid coral-orange — warm energetic accent, high contrast on purple
      secondary: Color(0xFFFF7055),
      // Near-black warm — readable on coral
      onSecondary: Color(0xFF1A0400),
      // Electric cyan — cool space-tech celebration/reward color
      tertiary: Color(0xFF3DE8E0),
      // Deep dark teal — readable on cyan
      onTertiary: Color(0xFF001A19),
      // Deep space indigo — mystery, premium, full immersion background (dark)
      darkBackground: Color(0xFF0C0818),
      // Lifted deep indigo — main container surface (dark)
      darkSurface: Color(0xFF16102A),
      // Card-level indigo — puzzle board background (dark)
      darkCard: Color(0xFF201838),
      // Elevated indigo — chips, highlighted cards (dark)
      darkCard2: Color(0xFF2A2048),
      // Mid-purple — borders & dividers (dark)
      darkBorder: Color(0xFF4C3A7A),
      // Crisp lavender-white — primary text (dark mode)
      darkOnSurface: Color(0xFFFAF8FF),
      // Muted soft purple — subtitles/secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFFC0B0E0),
      // Pale lavender — full background (light mode)
      lightBackground: Color(0xFFF8F5FF),
      // Near-pure white lavender — main surface (light mode)
      lightSurface: Color(0xFFFDFBFF),
      // Light lavender — card background (light mode)
      lightCard: Color(0xFFECE4FF),
      // Slightly deeper lavender — elevated card (light mode)
      lightCard2: Color(0xFFE0D5FF),
      // Medium lavender — borders (light mode)
      lightBorder: Color(0xFFC0AAEE),
      // Deep indigo dark — primary text (light mode)
      lightOnSurface: Color(0xFF180E34),
      // Medium purple — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF583E80),
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // THEME 5: "Cherry Blossom"
    // Psychology: Deep burgundy = intensity, drama, premium.
    // Crimson-pink primary = passion, urgency, emotional engagement.
    // Violet secondary = creativity, mystery — contrasts with pink on warm bg.
    // Mint teal tertiary = fresh, calm reward — opposite of warm bg = pop.
    // Color families: Crimson-Pink (primary) + Violet (secondary) + Mint (tertiary)
    // on Deep Burgundy (bg) — analogous with a cool mint surprise contrast.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Cherry Blossom',
      // Deep crimson-pink — passion, urgency, emotionally engaging action color
      primary: Color(0xFFE01A5A),
      // Deep dark — readable on crimson-pink
      onPrimary: Color(0xFF1A001A),
      // Rich violet-purple — creative, mysterious secondary accent
      secondary: Color(0xFF8B5CF6),
      // Deep dark — readable on violet
      onSecondary: Color(0xFF0F0020),
      // Mint teal — fresh, calm, high-contrast reward (opposite of warm bg)
      tertiary: Color(0xFF06D6A0),
      // Deep dark teal — readable on mint
      onTertiary: Color(0xFF001A12),
      // Deep burgundy-maroon — dramatic, premium game background (dark)
      darkBackground: Color(0xFF180810),
      // Lifted burgundy — main container surface (dark)
      darkSurface: Color(0xFF240E1C),
      // Card-level burgundy — puzzle board cards (dark)
      darkCard: Color(0xFF301428),
      // Elevated burgundy card — chips, highlighted elements (dark)
      darkCard2: Color(0xFF3C1C34),
      // Deep rose border — dividers visible against dark burgundy
      darkBorder: Color(0xFF6A2850),
      // Soft rose-white — primary text (dark mode)
      darkOnSurface: Color(0xFFFFF0F5),
      // Muted rose — subtitles/secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFFD0A0B8),
      // Pale blush — full background (light mode)
      lightBackground: Color(0xFFFFF0F5),
      // Near-pure white blush — main surface (light mode)
      lightSurface: Color(0xFFFFFAFC),
      // Light rose — card background (light mode)
      lightCard: Color(0xFFFFDEEC),
      // Slightly deeper rose — elevated card (light mode)
      lightCard2: Color(0xFFFFCCDE),
      // Medium rose — borders (light mode)
      lightBorder: Color(0xFFF0A0BE),
      // Deep burgundy dark — primary text (light mode)
      lightOnSurface: Color(0xFF2A0018),
      // Medium deep rose — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF702848),
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // THEME 6: "Golden Hour"
    // Psychology: Warm amber-brown bg = comfort, nostalgia, natural warmth.
    // Electric cobalt blue primary = COOL on WARM = strongest contrast type
    // (temperature contrast — more powerful than value contrast alone).
    // Lime secondary = nature energy on warm bg, surprising pop.
    // Amber gold tertiary = harvest reward, continuation of warm theme.
    // Color families: Blue (primary) + Lime (secondary) on Amber (bg)
    // — split-complementary scheme with temperature drama.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Golden Hour',
      // Electric cobalt blue — cool on warm bg = strongest temperature contrast
      primary: Color(0xFF2979FF),
      // Near-black cool dark — readable on electric blue
      onPrimary: Color(0xFF000A20),
      // Electric lime-green — energetic nature pop on warm amber background
      secondary: Color(0xFF64DD17),
      // Deep forest dark — readable on electric lime
      onSecondary: Color(0xFF041200),
      // Rich amber gold — warm harvest reward, on-theme celebration color
      tertiary: Color(0xFFFFB300),
      // Deep warm dark — readable on amber gold
      onTertiary: Color(0xFF1A0A00),
      // Rich dark amber-brown — cozy warm immersion background (dark)
      darkBackground: Color(0xFF180E00),
      // Lifted warm brown — main container surface (dark)
      darkSurface: Color(0xFF261600),
      // Card-level warm brown — puzzle board cards (dark)
      darkCard: Color(0xFF342008),
      // Elevated warm card — chips, highlighted elements (dark)
      darkCard2: Color(0xFF402C10),
      // Warm caramel border — dividers on dark warm bg
      darkBorder: Color(0xFF785020),
      // Warm off-white — primary text (dark mode)
      darkOnSurface: Color(0xFFFFF9F0),
      // Muted gold-cream — subtitles/secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFFD4B47A),
      // Warm cream — full background (light mode)
      lightBackground: Color(0xFFFFFCF0),
      // Near-pure warm white — main surface (light mode)
      lightSurface: Color(0xFFFFFEFA),
      // Pale golden — card background (light mode)
      lightCard: Color(0xFFFFF3CC),
      // Slightly deeper golden — elevated card (light mode)
      lightCard2: Color(0xFFFFE8AA),
      // Medium warm gold — borders (light mode)
      lightBorder: Color(0xFFE8C060),
      // Deep warm dark — primary text (light mode)
      lightOnSurface: Color(0xFF1A0E00),
      // Medium warm brown — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF785820),
    ),

    // ─────────────────────────────────────────────────────────────────────────
    // THEME 7: "Arctic Storm"
    // Psychology: Near-black navy = cold, intense, dramatic focus.
    // Electric red primary = DANGER signal — human eyes detect red first.
    // Red on black = maximum urgency contrast (traffic signal science).
    // Orange secondary = hot energy, just below red on urgency scale.
    // Ice blue tertiary = calm cool reward after the red tension — relief.
    // Color families: Red (primary) + Orange (secondary) + Ice Blue (tertiary)
    // on Near-Black Navy (bg) — analogous warm split + cold contrast release.
    // ─────────────────────────────────────────────────────────────────────────
    ThemePreset(
      name: 'Arctic Storm',
      // Electric crimson-red — human eye priority #1, max urgency, action CTA
      primary: Color(0xFFFF2942),
      // Very deep dark red — readable on crimson red
      onPrimary: Color(0xFF1A0004),
      // Vivid electric orange — second on urgency scale, energetic secondary
      secondary: Color(0xFFFF8C00),
      // Very deep dark warm — readable on vivid orange
      onSecondary: Color(0xFF1A0600),
      // Ice blue — calm, cool relief/reward (psychological contrast to red)
      tertiary: Color(0xFF48CAF5),
      // Deep dark navy — readable on ice blue
      onTertiary: Color(0xFF001A22),
      // Near-black deep navy — dramatic, intense focus background (dark)
      darkBackground: Color(0xFF030810),
      // Slightly lifted midnight navy — main container surface (dark)
      darkSurface: Color(0xFF080F1E),
      // Card-level deep navy — puzzle board cards (dark)
      darkCard: Color(0xFF0E1828),
      // Elevated dark navy — chips, highlighted cards (dark)
      darkCard2: Color(0xFF142034),
      // Deep navy blue — borders & dividers (dark)
      darkBorder: Color(0xFF1E3050),
      // Crisp white with ice tint — primary text (dark mode, max contrast)
      darkOnSurface: Color(0xFFF4F9FF),
      // Muted ice blue-grey — subtitles/secondary text (dark mode)
      darkOnSurfaceVariant: Color(0xFFA0C0D8),
      // Pale ice white — full background (light mode)
      lightBackground: Color(0xFFF4F9FF),
      // Near-pure ice white — main surface (light mode)
      lightSurface: Color(0xFFFAFCFF),
      // Pale sky blue — card background (light mode)
      lightCard: Color(0xFFE4EEF8),
      // Slightly deeper sky — elevated card (light mode)
      lightCard2: Color(0xFFD8E6F4),
      // Medium blue-grey — borders (light mode)
      lightBorder: Color(0xFFB0C8DC),
      // Deep navy dark — primary text (light mode)
      lightOnSurface: Color(0xFF04101E),
      // Medium navy — secondary/subtitle text (light mode)
      lightOnSurfaceVariant: Color(0xFF385870),
    ),
  ];

  static ThemePreset resolveByColor(Color color) {
    for (final preset in all) {
      if (preset.primary.value == color.value) {
        return preset;
      }
    }
    return all.first;
  }
}
