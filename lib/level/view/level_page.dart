import 'dart:async';

import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/ADs/banner_ad_widget.dart';
import 'package:blocked/services/app_services.dart';
import 'package:blocked/audio/game_feel.dart';
import 'package:blocked/level/cubit/level_hud_cubit.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level/view/first_level_tutorial.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/solver/solver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LevelPage extends StatelessWidget {
  const LevelPage(
    this.level, {
    Key? key,
    required this.onExit,
    required this.onNext,
    required this.boardControls,
    this.levelNumber,
  }) : super(key: key);

  final Level level;
  final VoidCallback onExit;
  final VoidCallback onNext;
  final Widget boardControls;
  final int? levelNumber;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final hud = LevelHudCubit();
        getBestMoves(level.name).then(hud.setBestMoves);
        solve(level.initialState.puzzle).then((solution) {
          hud.setMinimumMoves(solution?.length);
        });
        return hud;
      },
      child: _LevelPageView(
        level: level,
        onExit: onExit,
        onNext: onNext,
        boardControls: boardControls,
        levelNumber: levelNumber,
      ),
    );
  }
}

class _LevelPageView extends StatefulWidget {
  const _LevelPageView({
    required this.level,
    required this.onExit,
    required this.onNext,
    required this.boardControls,
    this.levelNumber,
  });

  final Level level;
  final VoidCallback onExit;
  final VoidCallback onNext;
  final Widget boardControls;
  final int? levelNumber;

  @override
  State<_LevelPageView> createState() => _LevelPageViewState();
}

class _LevelPageViewState extends State<_LevelPageView> {
  bool _savedCompletion = false;
  bool _shownWinSheet = false;
  bool _loggedLevelStart = false;

  static const _playAssets = 'assets/ui/play';

  @override
  void initState() {
    super.initState();
    // Silent SFX preload only — no haptic / no auto sounds on level open.
    unawaited(GameFeel.instance.init());
    if (!_loggedLevelStart) {
      _loggedLevelStart = true;
      unawaited(
        analyticsService.logLevelStarted(
          levelNumber: widget.levelNumber,
          source: 'level_page',
        ),
      );
    }
    // Defer ad work until after the first gameplay frame paints — avoids
    // competing with navigation + board build on the same frame as Play tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AdManager().prefetchRewardedAds();
    });
  }

  @override
  void dispose() {
    if (!_savedCompletion) {
      unawaited(
        analyticsService.logLevelAbandoned(
          levelNumber: widget.levelNumber,
          source: 'level_page',
        ),
      );
    }
    AdManager().leaveGameplayBanner();
    super.dispose();
  }

  void _showPauseMenu(BuildContext context) {
    showDialog<void>(
      context: context,
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
                colors: [Color(0xFF6B4226), Color(0xFF3A2210)],
              ),
              border: Border.all(color: const Color(0xFFC4A574), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PAUSED',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFFF1D6),
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 16),
                _PauseAction(
                  label: 'RESUME',
                  color: const Color(0xFF4CBB28),
                  onTap: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(height: 10),
                _PauseAction(
                  label: 'RESTART',
                  color: const Color(0xFFFF8A1A),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    context.read<LevelBloc>().add(const LevelReset());
                    context.read<LevelHudCubit>().resetTimer();
                  },
                ),
                const SizedBox(height: 10),
                _PauseAction(
                  label: 'MAP',
                  color: const Color(0xFF2E8DE8),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    widget.onExit();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final s = (size.height / 840).clamp(0.78, 1.12);
    final side = (size.width * 0.04).clamp(12.0, 22.0);
    final levelNo = widget.levelNumber ?? 1;

    return BlocProvider(
      create: (context) => LevelBloc(widget.level.initialState),
      child: BlocProvider(
        create: (context) => PuzzleSolverBloc(context.read<LevelBloc>()),
        child: Builder(
          builder: (context) {
            return Provider(
              create: (context) => LevelNavigation(
                onExit: widget.onExit,
                onNext: () {
                  if (context.read<LevelBloc>().state.isCompleted) {
                    widget.onNext();
                  }
                },
              ),
              child: LevelShortcutListener(
                levelBloc: context.read<LevelBloc>(),
                child: BlocConsumer<LevelBloc, LevelState>(
                  listenWhen: (previous, current) =>
                      previous.isCompleted != current.isCompleted ||
                      previous.latestMove != current.latestMove,
                  listener: (context, state) async {
                    if (state.isCompleted && !_savedCompletion) {
                      _savedCompletion = true;
                      GameFeel.instance.win();
                      // Block until prefs are on disk — online ad traffic must
                      // not race ahead of this write.
                      await _saveCompletionAndCelebrate(context, state.moves);
                    }
                  },
                  builder: (context, state) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          '$_playAssets/bg.webp',
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                        ),
                        Column(
                          children: [
                            SizedBox(height: pad.top + 4),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: _PlayHeader(
                                scale: s,
                                levelNumber: levelNo,
                                onBack: widget.onExit,
                                onPause: () => _showPauseMenu(context),
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _WoodStatPlank(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Moves: ',
                                              style: GoogleFonts.nunito(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14 * s,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '${state.moves}',
                                              style: GoogleFonts.nunito(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18 * s,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10 * s),
                                  Expanded(
                                    child: _WoodStatPlank(
                                      child: BlocBuilder<LevelHudCubit,
                                          LevelHudState>(
                                        buildWhen: (a, b) =>
                                            a.elapsed != b.elapsed,
                                        builder: (context, hud) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                color: const Color(0xFFFFD54F),
                                                size: 18 * s,
                                              ),
                                              SizedBox(width: 6 * s),
                                              Text(
                                                _formatDuration(hud.elapsed),
                                                style: GoogleFonts.nunito(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 18 * s,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: side),
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: FittedBox(
                                      child: Hero(
                                        // Tagged per level so the board only
                                        // flies to and from its own map tile.
                                        // Level to level shares no tag, which
                                        // keeps the board inside the page and
                                        // sliding along with the background.
                                        tag: widget.level.name,
                                        flightShuttleBuilder: (
                                          flightContext,
                                          animation,
                                          flightDirection,
                                          fromHeroContext,
                                          toHeroContext,
                                        ) {
                                          final toHero =
                                              toHeroContext.widget as Hero;
                                          return BlocProvider.value(
                                            value: context.read<LevelBloc>(),
                                            child: Material(
                                              type: MaterialType.transparency,
                                              child: toHero.child,
                                            ),
                                          );
                                        },
                                        child: const Puzzle(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8 * s),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: side),
                              child: SizedBox(
                                height: (88 * s).clamp(72.0, 96.0),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: size.width - side * 2,
                                    height: 88,
                                    child: Hero(
                                      tag: 'controls_${widget.level.name}',
                                      flightShuttleBuilder: (
                                        flightContext,
                                        animation,
                                        flightDirection,
                                        fromHeroContext,
                                        toHeroContext,
                                      ) {
                                        final toHero =
                                            toHeroContext.widget as Hero;
                                        return BlocProvider.value(
                                          value: context.read<LevelBloc>(),
                                          child: BlocProvider.value(
                                            value: context
                                                .read<PuzzleSolverBloc>(),
                                            child: Material(
                                              type: MaterialType.transparency,
                                              child: toHero.child,
                                            ),
                                          ),
                                        );
                                      },
                                      child: widget.boardControls,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12 * s),
                            BannerAdBar(
                              slot: BannerAdSlot.play,
                              includeBottomSafeArea: true,
                              topGap: 8 * s,
                            ),
                          ],
                        ),
                        if (levelNo == 1)
                          FirstLevelTutorial(levelState: state),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWinSheet(BuildContext context, int moveCount) {
    final hud = context.read<LevelHudCubit>();
    final stars = calculateStars(
      moves: moveCount,
      minimumMoves: hud.state.minimumMoves ?? moveCount,
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xE61A0D04),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: _ResultBackdrop(
            child: _LevelCompletePanel(
              levelName: widget.level.name,
              stars: stars,
              moves: moveCount,
              bestMoves: hud.state.bestMoves ?? moveCount,
              time: _formatDuration(hud.elapsed),
              coins: stars * 25,
              onNext: () async {
                Navigator.pop(dialogContext);
                await AdManager().showInterstitial();
                if (!context.mounted) return;
                context.read<LevelNavigation>().onNext();
              },
              onPlayAgain: () {
                Navigator.pop(dialogContext);
                context.read<LevelBloc>().add(const LevelReset());
                _savedCompletion = false;
                _shownWinSheet = false;
                context.read<LevelHudCubit>().resetTimer();
              },
              onHome: () async {
                Navigator.pop(dialogContext);
                await AdManager().showInterstitial();
                if (!context.mounted) return;
                context.read<NavigatorCubit>().navigateToHome();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCompletionAndCelebrate(
    BuildContext context,
    int moveCount,
  ) async {
    final hud = context.read<LevelHudCubit>();
    final minimumMoves = hud.state.minimumMoves ?? moveCount;
    // Result screen must never appear before prefs are written.
    await markLevelAsCompleted(
      widget.level.name,
      moves: moveCount,
      elapsedSeconds: hud.elapsed.inSeconds,
      minimumMoves: minimumMoves,
    );
    unawaited(
      analyticsService.logLevelCompleted(
        levelNumber: widget.levelNumber,
        moves: moveCount,
        timeSeconds: hud.elapsed.inSeconds,
        source: 'level_page',
      ),
    );
    if (!mounted) return;
    final best = await getBestMoves(widget.level.name);
    if (mounted) hud.setBestMoves(best);
    if (!_shownWinSheet && mounted) {
      _shownWinSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showWinSheet(context, moveCount);
      });
    }
  }
}

String _formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _PlayHeader extends StatelessWidget {
  const _PlayHeader({
    required this.scale,
    required this.levelNumber,
    required this.onBack,
    required this.onPause,
  });

  final double scale;
  final int levelNumber;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final btn = (44.0 * scale).clamp(40.0, 52.0);
    final bannerH = (64.0 * scale).clamp(54.0, 76.0);

    return Row(
      children: [
        _WoodSquareButton(
          size: btn,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        Expanded(
          child: SizedBox(
            height: bannerH,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/ui/play/banner_blank.webp',
                  height: bannerH,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: bannerH * 0.18),
                  child: Text(
                    'LEVEL $levelNumber',
                    style: GoogleFonts.nunito(
                      color: const Color(0xFFFFF1D6),
                      fontWeight: FontWeight.w900,
                      fontSize: (22.0 * scale).clamp(18.0, 26.0),
                      letterSpacing: 1,
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
              ],
            ),
          ),
        ),
        _WoodSquareButton(
          size: btn,
          icon: Icons.pause_rounded,
          onTap: onPause,
        ),
      ],
    );
  }
}

class _WoodSquareButton extends StatelessWidget {
  const _WoodSquareButton({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1E), Color(0xFF3A2210)],
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
          child: Icon(icon, color: Colors.white, size: size * 0.48),
        ),
      ),
    );
  }
}

class _WoodStatPlank extends StatelessWidget {
  const _WoodStatPlank({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7A4A28), Color(0xFF4A2C14)],
        ),
        border: Border.all(color: const Color(0xFFC4A574), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PauseAction extends StatelessWidget {
  const _PauseAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid dark-brown board behind the result content — the panel used to sit on
/// a transparent dialog, so the gameplay screen showed through it.
class _ResultBackdrop extends StatelessWidget {
  const _ResultBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = (MediaQuery.sizeOf(context).height / 840).clamp(0.78, 1.05);

    return Container(
      padding: EdgeInsets.fromLTRB(14 * s, 16 * s, 14 * s, 16 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2A12), Color(0xFF2C1708), Color(0xFF1A0D04)],
        ),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LevelCompletePanel extends StatelessWidget {
  const _LevelCompletePanel({
    required this.levelName,
    required this.stars,
    required this.moves,
    required this.bestMoves,
    required this.time,
    required this.coins,
    required this.onNext,
    required this.onPlayAgain,
    required this.onHome,
  });

  final String levelName;
  final int stars;
  final int moves;
  final int bestMoves;
  final String time;
  final int coins;
  final Future<void> Function() onNext;
  final VoidCallback onPlayAgain;
  final Future<void> Function() onHome;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (size.height / 840).clamp(0.78, 1.05);
    final perfect = stars >= 3;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/ui/complete/banner.webp',
            height: (72 * s).clamp(58.0, 86.0),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          SizedBox(height: 8 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final earned = i < stars;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * s),
                child: Icon(
                  Icons.star_rounded,
                  size: (42 * s).clamp(34.0, 48.0),
                  color: earned
                      ? const Color(0xFFFFD54F)
                      : Colors.white.withValues(alpha: 0.28),
                  shadows: earned
                      ? const [
                          Shadow(
                            color: Color(0xFFFFB300),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          SizedBox(height: 6 * s),
          Image.asset(
            'assets/ui/complete/trophy.webp',
            height: (88 * s).clamp(70.0, 110.0),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          SizedBox(height: 10 * s),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 16 * s, 14 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4226), Color(0xFF3A2210)],
              ),
              border: Border.all(color: const Color(0xFFC4A574), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _CompleteRow(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFFFD54F),
                  label: 'RATING',
                  value: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: i < stars
                            ? const Color(0xFFFFD54F)
                            : Colors.white38,
                      ),
                    ),
                  ),
                ),
                _CompleteRow(
                  icon: Icons.gps_fixed_rounded,
                  iconColor: const Color(0xFFFF6B5A),
                  label: 'MOVES',
                  value: Text(
                    '$moves',
                    style: _valueStyle,
                  ),
                ),
                _CompleteRow(
                  icon: Icons.emoji_events_rounded,
                  iconColor: const Color(0xFFFFD54F),
                  label: 'BEST',
                  value: Text('$bestMoves', style: _valueStyle),
                ),
                _CompleteRow(
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFFFFD54F),
                  label: 'TIME',
                  value: Text(time, style: _valueStyle),
                ),
                _CompleteRow(
                  icon: Icons.monetization_on_rounded,
                  iconColor: const Color(0xFFFFD54F),
                  label: 'COINS EARNED',
                  value: Text('+$coins', style: _valueStyle),
                  isLast: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          _CompleteButton(
            label: 'NEXT LEVEL',
            icon: Icons.play_arrow_rounded,
            colors: const [Color(0xFF8FE04A), Color(0xFF2F9A1A)],
            onTap: () {
              onNext();
            },
          ),
          SizedBox(height: 8 * s),
          _CompleteButton(
            label: 'PLAY AGAIN',
            icon: Icons.refresh_rounded,
            colors: const [Color(0xFF5EC8FF), Color(0xFF1578C4)],
            onTap: onPlayAgain,
          ),
          SizedBox(height: 8 * s),
          _CompleteButton(
            label: 'HOME',
            icon: Icons.home_rounded,
            colors: const [Color(0xFFFFB04A), Color(0xFFE06A00)],
            onTap: () {
              onHome();
            },
          ),
          SizedBox(height: 10 * s),
          Text(
            perfect
                ? 'Excellent! You solved the puzzle perfectly!'
                : 'Nice work! Can you beat it with fewer moves?',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13 * s,
              shadows: const [
                Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final _valueStyle = GoogleFonts.nunito(
    color: Colors.white,
    fontWeight: FontWeight.w900,
    fontSize: 18,
  );
}

class _CompleteRow extends StatelessWidget {
  const _CompleteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Widget value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
          ),
          value,
        ],
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
              border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.6,
                    shadows: const [
                      Shadow(
                        color: Colors.black38,
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
    );
  }
}
