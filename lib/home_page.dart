import 'dart:async';

import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/audio/game_feel.dart';
import 'package:blocked/audio/game_music.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Home: dense forest layout — logo, board, stats, Play CTA, wood nav (shell).
class HomePage extends StatelessWidget {
  const HomePage({Key? key, required this.chapters}) : super(key: key);

  final List<LevelChapter> chapters;

  @override
  Widget build(BuildContext context) {
    return _HomeView(chapters: chapters);
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView({required this.chapters});

  final List<LevelChapter> chapters;

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final adManager = AdManager();
  bool _openingLevel = false;

  static const _assets = 'assets/ui/home';

  @override
  void initState() {
    super.initState();
    // Ads bootstrap is deferred from main — don't pile on first home frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adManager.ensureLoaded();
      unawaited(GameFeel.instance.prewarm());
    });
  }

  Future<void> _play() async {
    if (_openingLevel) return;
    _openingLevel = true;
    try {
      GameFeel.instance.tap();
      // Always read prefs — never a stale cache (progress is local, not network).
      final level = await getFirstUncompletedLevel(widget.chapters);
      if (!mounted) return;
      if (level[0].isEmpty) return;
      context.read<NavigatorCubit>().navigateToLevel(level[0], level[1]);
    } finally {
      _openingLevel = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final w = size.width;
    final s = (h / 840).clamp(0.82, 1.15);
    final side = (w * 0.055).clamp(18.0, 28.0);

    final playH = (h * 0.125).clamp(92.0, 118.0);
    final gap = (6.0 * s).clamp(4.0, 9.0);
    final titleH = (h * 0.19).clamp(108.0, 148.0);

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
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(side, 4, side, gap),
                    child: Column(
                      children: [
                        SizedBox(
                          height: titleH + gap * 0.4,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: gap * 0.2,
                                left: 0,
                                right: 0,
                                child: Image.asset(
                                  '$_assets/title_banner.png',
                                  height: titleH,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  gaplessPlayback: true,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: GameMusic.instance.muted,
                                  builder: (context, muted, _) {
                                    return _MuteChip(
                                      muted: muted,
                                      onTap: () {
                                        GameFeel.instance.tap();
                                        GameMusic.instance.toggleMute();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: Image.asset(
                              '$_assets/puzzle_preview.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        StreamBuilder<PlayerProgress>(
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
                                  child: _StatCard(
                                    scale: s,
                                    iconAsset: '$_assets/icon_flame.png',
                                    label: 'STREAK',
                                    value: '${p.currentStreak}',
                                    colors: const [
                                      Color(0xFFB07BFF),
                                      Color(0xFF7A35E8),
                                    ],
                                  ),
                                ),
                                SizedBox(width: gap + 2),
                                Expanded(
                                  child: _StatCard(
                                    scale: s,
                                    iconAsset: '$_assets/icon_trophy.png',
                                    label: 'SOLVED',
                                    value: '${p.levelsSolved}',
                                    colors: const [
                                      Color(0xFF5CB0FF),
                                      Color(0xFF1A75E8),
                                    ],
                                  ),
                                ),
                                SizedBox(width: gap + 2),
                                Expanded(
                                  child: _StatCard(
                                    scale: s,
                                    iconAsset: '$_assets/icon_star.png',
                                    label: 'STARS',
                                    value: '${p.totalStars}',
                                    colors: const [
                                      Color(0xFFFFD954),
                                      Color(0xFFE8A500),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: gap + 4),
                        _CtaButton(
                          asset: '$_assets/btn_play.png',
                          height: playH,
                          onTap: _play,
                          semanticLabel: 'Play',
                        ),
                        SizedBox(height: gap + 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MuteChip extends StatelessWidget {
  const _MuteChip({required this.muted, required this.onTap});
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5A2B), Color(0xFF3A2210)],
            ),
            border: Border.all(color: const Color(0xFFC4A574), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            color: const Color(0xFFFFF1D6),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.scale,
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.colors,
  });

  final double scale;
  final String iconAsset;
  final String label;
  final String value;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final iconH = (30.0 * scale).clamp(26.0, 36.0);
    final labelSize = (10.5 * scale).clamp(9.5, 12.0);
    final valueSize = (24.0 * scale).clamp(20.0, 28.0);
    final radius = (18.0 * scale).clamp(14.0, 22.0);
    final vPad = (10.0 * scale).clamp(8.0, 13.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconAsset, height: iconH, fit: BoxFit.contain),
          SizedBox(height: 2 * scale),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: labelSize,
              letterSpacing: 0.5,
              height: 1.05,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: valueSize,
              height: 1.05,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width CTA with press scale — fills the home screen properly.
class _CtaButton extends StatefulWidget {
  const _CtaButton({
    required this.asset,
    required this.height,
    required this.onTap,
    required this.semanticLabel,
  });

  final String asset;
  final double height;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.96,
      upperBound: 1,
      value: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press.reverse(),
        onTapCancel: () => _press.forward(),
        onTap: () {
          _press.forward();
          widget.onTap();
        },
        child: ScaleTransition(
          scale: _press,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              widget.asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              alignment: Alignment.center,
              gaplessPlayback: true,
            ),
          ),
        ),
      ),
    );
  }
}
