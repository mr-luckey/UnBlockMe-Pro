import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:blocked/theme/theme.dart';
import 'package:blocked/theme/theme_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Settings screen styled like home/map — forest bg + wood panels.
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  static const _assets = 'assets/ui/home';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (size.height / 840).clamp(0.82, 1.12);
    final side = (size.width * 0.05).clamp(16.0, 26.0);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: topPad + 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: _SettingsHeader(
                  scale: s,
                  onBack: () =>
                      context.read<NavigatorCubit>().navigateToHome(),
                ),
              ),
              SizedBox(height: 12 * s),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(side, 0, side, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WoodSection(
                        title: 'APPEARANCE',
                        icon: Icons.palette_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const _InfoRow(
                              icon: Icons.dark_mode_rounded,
                              label: 'Theme',
                              value: 'Dark',
                            ),
                            SizedBox(height: 12 * s),
                            Text(
                              'Board color',
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFFFF1D6),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 10 * s),
                            _ColorPresetGrid(scale: s),
                          ],
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      _WoodSection(
                        title: 'YOUR PROGRESS',
                        icon: Icons.emoji_events_rounded,
                        child: StreamBuilder<PlayerProgress>(
                          stream: playerProgressStream(),
                          builder: (context, snapshot) {
                            final p = snapshot.data ??
                                const PlayerProgress(
                                  totalStars: 0,
                                  levelsSolved: 0,
                                  currentStreak: 0,
                                  bestStreak: 0,
                                );
                            return Row(
                              children: [
                                Expanded(
                                  child: _ProgressChip(
                                    icon: Icons.star_rounded,
                                    iconColor: const Color(0xFFFFD54F),
                                    label: 'STARS',
                                    value: '${p.totalStars}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ProgressChip(
                                    icon: Icons.check_circle_rounded,
                                    iconColor: const Color(0xFF8FE04A),
                                    label: 'SOLVED',
                                    value: '${p.levelsSolved}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ProgressChip(
                                    icon: Icons.local_fire_department_rounded,
                                    iconColor: const Color(0xFFFF8A1A),
                                    label: 'STREAK',
                                    value: '${p.currentStreak}',
                                    sub: 'Best ${p.bestStreak}',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      _WoodSection(
                        title: 'DATA',
                        icon: Icons.storage_rounded,
                        child: _DangerButton(
                          label: 'CLEAR PROGRESS',
                          icon: Icons.delete_forever_rounded,
                          onTap: () => _confirmClear(context),
                        ),
                      ),
                      SizedBox(height: 8 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4226), Color(0xFF2A1808)],
              ),
              border: Border.all(color: const Color(0xFFC4A574), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFB04A),
                  size: 42,
                ),
                const SizedBox(height: 10),
                Text(
                  'CLEAR PROGRESS?',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFFF1D6),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All stars, streaks and solved levels will be erased. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _DialogAction(
                        label: 'CANCEL',
                        colors: const [Color(0xFF8B5A2B), Color(0xFF5C3A1E)],
                        onTap: () => Navigator.pop(dialogContext, false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogAction(
                        label: 'CLEAR',
                        colors: const [Color(0xFFFF6B5A), Color(0xFFC62828)],
                        onTap: () => Navigator.pop(dialogContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await clearData();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4A2C14),
          content: Text(
            'Progress cleared',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.scale, required this.onBack});

  final double scale;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final btn = (44.0 * scale).clamp(40.0, 52.0);

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: btn,
              height: btn,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5A2B),
                    Color(0xFF5C3A1E),
                    Color(0xFF3A2210),
                  ],
                ),
                border: Border.all(color: const Color(0xFFC4A574), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: btn * 0.48),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 22 * scale,
                vertical: 10 * scale,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7A4A28), Color(0xFF3A2210)],
                ),
                border: Border.all(color: const Color(0xFFC4A574), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'SETTINGS',
                style: GoogleFonts.nunito(
                  color: const Color(0xFFFFF1D6),
                  fontWeight: FontWeight.w900,
                  fontSize: (20 * scale).clamp(17.0, 22.0),
                  letterSpacing: 1.2,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: btn),
      ],
    );
  }
}

class _WoodSection extends StatelessWidget {
  const _WoodSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4226), Color(0xFF3A2210)],
        ),
        border: Border.all(color: const Color(0xFFC4A574), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFD54F), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.nunito(
                  color: const Color(0xFFFFF1D6),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(
          color: const Color(0xFFC4A574).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFF1D6), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFF8FE04A), Color(0xFF2F9A1A)],
              ),
            ),
            child: Text(
              value,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPresetGrid extends StatelessWidget {
  const _ColorPresetGrid({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ThemePresets.all.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10 * scale,
        crossAxisSpacing: 10 * scale,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final preset = ThemePresets.all[index];
        final color = preset.primary;

        return Builder(
          builder: (context) {
            final isSelected = context.select(
              (ThemeColorBloc bloc) =>
                  bloc.state.color.toARGB32() == color.toARGB32(),
            );

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<ThemeColorBloc>().add(ThemeColorChanged(color));
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.black.withValues(alpha: 0.2),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFFD54F)
                          : const Color(0xFFC4A574).withValues(alpha: 0.5),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFFFFD54F).withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: BoardColor(
                          data: BoardColorData.fromColorScheme(
                            createBlockedTheme(
                              Theme.of(context).brightness,
                              accent: color,
                            ).colorScheme,
                          ),
                          child: const ThemeColorPreview(),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Text(
                          preset.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            shadows: const [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFFFD54F),
                            size: 22,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(
          color: const Color(0xFFC4A574).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              height: 1.05,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.4,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: GoogleFonts.nunito(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF8A70), Color(0xFFD32F2F)],
            ),
            border: Border.all(color: const Color(0xFFFFD54F), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC62828).withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
