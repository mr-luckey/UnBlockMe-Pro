import 'package:blocked/audio/game_feel.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

enum ForestNavTab { home, levels, settings }

/// Wood bottom nav: 3 sections, crisp icons — sized to avoid overflow on
/// small phones and large safe-area insets.
class ForestBottomNav extends StatelessWidget {
  const ForestBottomNav({
    Key? key,
    required this.current,
    this.bottomPad,
    this.scale = 1,
  }) : super(key: key);

  final ForestNavTab current;
  final double? bottomPad;
  final double scale;

  void _go(BuildContext context, ForestNavTab tab) {
    if (tab == current) return;
    GameFeel.instance.tap();
    final nav = context.read<NavigatorCubit>();
    switch (tab) {
      case ForestNavTab.home:
        nav.navigateToHome();
        break;
      case ForestNavTab.levels:
        nav.navigateToChapterSelection();
        break;
      case ForestNavTab.settings:
        nav.navigateToSettings();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final inset = bottomPad ?? media.padding.bottom;

    // Width + height driven scale so short / narrow phones stay compact.
    final s = ((width / 390) * (height / 840).clamp(0.85, 1.1) * scale)
        .clamp(0.78, 1.12);

    final iconSize = (26.0 * s).clamp(22.0, 30.0);
    final fontSize = (12.0 * s).clamp(10.5, 13.0);
    final hPad = (10.0 * s).clamp(8.0, 14.0);
    final topPad = (10.0 * s).clamp(8.0, 12.0);
    final bottomPadInner = (6.0 * s).clamp(4.0, 8.0);
    final safeBottom = inset > 0 ? inset : (8.0 * s).clamp(6.0, 10.0);
    // Taller content row — FittedBox still guards against overflow.
    final contentH = (iconSize + fontSize + 18).clamp(58.0, 72.0);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/ui/home/nav_wood.webp',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF6B4226).withValues(alpha: 0.45),
                      const Color(0xFF2A1808).withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 2,
              child: Container(
                color: const Color(0xFFC4A574).withValues(alpha: 0.7),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                topPad,
                hPad,
                safeBottom + bottomPadInner,
              ),
              child: SizedBox(
                height: contentH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _NavSection(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        active: current == ForestNavTab.home,
                        iconSize: iconSize,
                        fontSize: fontSize,
                        accent: const [
                          Color(0xFF9BE85A),
                          Color(0xFF3DAA20),
                        ],
                        onTap: () => _go(context, ForestNavTab.home),
                      ),
                    ),
                    _NavDivider(scale: s),
                    Expanded(
                      child: _NavSection(
                        icon: Icons.grid_view_rounded,
                        label: 'Levels',
                        active: current == ForestNavTab.levels,
                        iconSize: iconSize,
                        fontSize: fontSize,
                        accent: const [
                          Color(0xFFFFE066),
                          Color(0xFFE0A800),
                        ],
                        onTap: () => _go(context, ForestNavTab.levels),
                      ),
                    ),
                    _NavDivider(scale: s),
                    Expanded(
                      child: _NavSection(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        active: current == ForestNavTab.settings,
                        iconSize: iconSize,
                        fontSize: fontSize,
                        accent: const [
                          Color(0xFF7EC8FF),
                          Color(0xFF2E7FD0),
                        ],
                        onTap: () => _go(context, ForestNavTab.settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavDivider extends StatelessWidget {
  const _NavDivider({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final v = (8.0 * scale).clamp(4.0, 12.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: v, horizontal: 1),
      child: Container(
        width: 1.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color(0xFF1A0E06).withValues(alpha: 0.85),
              const Color(0xFFC4A574).withValues(alpha: 0.3),
              const Color(0xFF1A0E06).withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  const _NavSection({
    required this.icon,
    required this.label,
    required this.active,
    required this.iconSize,
    required this.fontSize,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final double iconSize;
  final double fontSize;
  final List<Color> accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF4E0);
    final inactive = cream.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: accent.first.withValues(alpha: 0.25),
          highlightColor: accent.first.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: accent,
                    )
                  : null,
              border: active
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.6,
                    )
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: accent.last.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: iconSize,
                      color: active ? Colors.white : inactive,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    SizedBox(height: (fontSize * 0.35).clamp(3.0, 5.0)),
                    Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: active ? Colors.white : inactive,
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize,
                        letterSpacing: 0.25,
                        height: 1.0,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
