import 'dart:async';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/level/widgets/how_to_play_sheet.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/solver/solver.dart';
import 'package:blocked/solver/puzzle_solver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class LevelPage extends StatelessWidget {
  const LevelPage(
    this.level, {
    Key? key,
    required this.onExit,
    required this.onNext,
    required this.boardControls,
  }) : super(key: key);

  final Level level;
  final VoidCallback onExit;
  final VoidCallback onNext;
  final Widget boardControls;

  @override
  Widget build(BuildContext context) => _LevelPageView(
        level: level,
        onExit: onExit,
        onNext: onNext,
        boardControls: boardControls,
      );
}

class _LevelPageView extends StatefulWidget {
  const _LevelPageView({
    required this.level,
    required this.onExit,
    required this.onNext,
    required this.boardControls,
  });

  final Level level;
  final VoidCallback onExit;
  final VoidCallback onNext;
  final Widget boardControls;

  @override
  State<_LevelPageView> createState() => _LevelPageViewState();
}

class _LevelPageViewState extends State<_LevelPageView> {
  late final Stopwatch _stopwatch;
  Timer? _ticker;
  bool _savedCompletion = false;
  bool _shownWinSheet = false;
  // Lets the BlocConsumer listener tell "block actually slid" apart from
  // "block bumped into a wall" apart from "just a rebuild", so haptics only
  // fire once per real move, not once per frame.
  Move? _lastLatestMove;
  late final Future<int?> _minimumMovesFuture;
  int? _minimumMoves;

  // Controls the confetti burst shown the instant a level completes.
  final GlobalKey<_ConfettiBurstState> _confettiKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _minimumMovesFuture = _loadMinimumMoves();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    _maybeShowTutorial();
  }

  // Shows the "How to Play" sheet exactly once per install, the first time
  // any level page opens. Runs after the first frame so it layers on top of
  // an already-built board instead of racing the page's own entrance
  // animation, and pauses the stopwatch while it's up so reading the rules
  // doesn't cost the player moves-per-second/time-based stats.
  Future<void> _maybeShowTutorial() async {
    final seen = await hasSeenTutorial();
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _stopwatch.stop();
      await HowToPlaySheet.show(context);
      if (!mounted) return;
      _stopwatch.start();
      await markTutorialSeen();
    });
  }

  Future<int?> _loadMinimumMoves() async {
    final solution = await solve(widget.level.initialState.puzzle);
    final value = solution?.length;
    if (mounted) {
      setState(() {
        _minimumMoves = value;
      });
    } else {
      _minimumMoves = value;
    }
    return value;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVerticalLayout =
        MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;

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
                  listener: (context, state) {
                    final move = state.latestMove;
                    if (move != _lastLatestMove) {
                      _lastLatestMove = move;
                      if (move is Move) {
                        // Real slide: light, crisp tick — confirms the drop.
                        // Blocked against a wall: a slightly heavier buzz —
                        // reads as "resistance" instead of silence, so a
                        // failed drag still feels intentional, not broken.
                        if (move.didMove) {
                          HapticFeedback.selectionClick();
                        } else {
                          HapticFeedback.lightImpact();
                        }
                      }
                    }
                    if (state.isCompleted && !_savedCompletion) {
                      _savedCompletion = true;
                      HapticFeedback.mediumImpact();
                      _confettiKey.currentState?.burst();
                      _saveCompletionAndCelebrate(context, state.moves);
                    }
                  },
                  buildWhen: (previous, current) =>
                      previous.latestMove != current.latestMove,
                  builder: (context, state) {
                    final levelName = widget.level.name;
                    final par =
                        (widget.level.initialState.blocks.length * 2) + 2;

                    final content = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton(
                              onPressed: widget.onExit,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const Spacer(),
                            Text(
                              levelName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                            const Spacer(),
                            _StatChip(
                              icon: Icons.timer_outlined,
                              label: _formatDuration(_stopwatch.elapsed),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _HudCard(
                          moves: state.moves,
                          par: par,
                          best: _minimumMoves,
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: FittedBox(
                                  child: Hero(
                                    tag: 'puzzle',
                                    flightShuttleBuilder: (
                                      BuildContext flightContext,
                                      Animation<double> animation,
                                      HeroFlightDirection flightDirection,
                                      BuildContext fromHeroContext,
                                      BuildContext toHeroContext,
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
                              // Confetti sits above the board but ignores
                              // touch, so it never blocks a replay tap.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _ConfettiBurst(key: _confettiKey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Hero(
                          tag: 'puzzle_controls',
                          flightShuttleBuilder: (
                            BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext,
                          ) {
                            final toHero = toHeroContext.widget as Hero;
                            return BlocProvider.value(
                              value: context.read<LevelBloc>(),
                              child: BlocProvider.value(
                                value: context.read<PuzzleSolverBloc>(),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: toHero.child,
                                ),
                              ),
                            );
                          },
                          child: widget.boardControls,
                        ),
                      ],
                    );

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        8,
                        16,
                        8,
                        12,
                      ),
                      child: isVerticalLayout
                          ? content
                          : Center(
                              child: IntrinsicWidth(
                                child: SizedBox(
                                  width: 700,
                                  child: content,
                                ),
                              ),
                            ),
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
    final stars = calculateStars(
      moves: moveCount,
      minimumMoves: _minimumMoves ?? moveCount,
    );
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPerfect = stars == 3;

    // Badge reads at a glance: gold trophy only for a perfect solve, silver
    // medal for a solid clear, a plain check for a scrappy one.
    final badgeIcon = stars == 3
        ? Icons.emoji_events_rounded
        : stars == 2
            ? Icons.military_tech_rounded
            : Icons.check_circle_rounded;
    final badgeColor = stars == 3
        ? colors.tertiary
        : stars == 2
            ? colors.secondary
            : colors.primary;

    // showGeneralDialog (instead of showDialog) so the whole card can pop in
    // with a scale+fade instead of Flutter's default flat fade — matches the
    // confetti/star-pop energy already happening behind it.
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Level complete',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.outline.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: badgeColor.withOpacity(0.18),
                      blurRadius: 60,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Badge: soft radial glow behind a trophy/medal icon ---
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  badgeColor.withOpacity(0.28),
                                  badgeColor.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: badgeColor.withOpacity(0.14),
                              border: Border.all(
                                color: badgeColor.withOpacity(0.5),
                                width: 1.4,
                              ),
                            ),
                            child: Icon(badgeIcon, color: badgeColor, size: 30),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.level.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stars pop in one-by-one instead of appearing all at once.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: index < stars ? 1 : 0),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) => Transform.scale(
                              scale: 0.6 + (0.4 * value),
                              child: child,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              size: 40,
                              color: index < stars
                                  ? colors.tertiary
                                  : colors.outline.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPerfect ? 'Excellent!' : 'Completed!',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: isPerfect ? colors.tertiary : colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isPerfect
                          ? 'Perfect solve! Maximum stars earned!'
                          : 'Nice solve! Keep improving your moves.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // --- Stats: three scannable chips instead of one plain
                    // bordered box with dividers, each carrying its own icon
                    // and accent so the eye can compare them at a glance.
                    Row(
                      children: [
                        Expanded(
                          child: _WinStatChip(
                            icon: Icons.timer_rounded,
                            color: colors.primary,
                            value: _formatDuration(_stopwatch.elapsed),
                            label: 'Time',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WinStatChip(
                            icon: Icons.swap_horiz_rounded,
                            color: colors.secondary,
                            value: '$moveCount',
                            label: 'Moves',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WinStatChip(
                            icon: Icons.star_rounded,
                            color: colors.tertiary,
                            value: '+${stars * 10}',
                            label: 'Stars',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    // --- Primary CTA: gradient-filled, full width — reads as
                    // "the one thing to tap" instead of competing with Retry
                    // and Levels for attention.
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors.primary, colors.tertiary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  context.read<LevelNavigation>().onNext();
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Next Level',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: colors.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded,
                                        color: colors.onPrimary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // --- Secondary actions: demoted below the primary CTA,
                    // plain text buttons so they don't visually compete.
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<LevelBloc>().add(const LevelReset());
                              _savedCompletion = false;
                              _shownWinSheet = false;
                              _stopwatch
                                ..reset()
                                ..start();
                              setState(() {});
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Retry'),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<LevelNavigation>().onExit();
                            },
                            icon: const Icon(Icons.grid_view_rounded, size: 18),
                            label: const Text('Levels'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final eased = Curves.easeOutBack.transform(animation.value);
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.82 + (0.18 * eased), child: child),
        );
      },
    );
  }

  Future<void> _saveCompletionAndCelebrate(
    BuildContext context,
    int moveCount,
  ) async {
    final minimumMoves =
        _minimumMoves ?? await _minimumMovesFuture ?? moveCount;
    await markLevelAsCompleted(
      widget.level.name,
      moves: moveCount,
      elapsedSeconds: _stopwatch.elapsed.inSeconds,
      minimumMoves: minimumMoves,
    );
    if (!_shownWinSheet && mounted) {
      _shownWinSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
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

/// Merges the old `_GoalCard` + 3 separate `_StatPanel`s into a single HUD.
///
/// Why: the old layout gave "MOVES", "PAR" and "BEST" identical visual
/// weight, so a player had to read all three numbers and do the comparison
/// in their head every single move. This version keeps the goal line
/// compact (one row, doesn't eat vertical space) and turns moves-vs-par into
/// a colored progress bar so "am I doing well?" is answerable at a glance:
/// green while under par, amber right at par, red once over it.
class _HudCard extends StatelessWidget {
  const _HudCard({
    required this.moves,
    required this.par,
    required this.best,
  });

  final int moves;
  final int par;
  final int? best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final ratio = par == 0 ? 0.0 : (moves / par).clamp(0.0, 1.5);
    final Color barColor = moves > par
        ? colors.error
        : moves == par
            ? colors.tertiary
            : colors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Move the main block (O) to the exit →',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$moves',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: barColor,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ $par par',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.emoji_events_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                best?.toString() ?? '—',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'best',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (ratio / 1.5).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: colors.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _WinStatChip extends StatelessWidget {
  const _WinStatChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight star-burst played the instant a level is solved.
///
/// No confetti package is added to pubspec.yaml on purpose — this is plain
/// Flutter (AnimationController + CustomPainter), so it costs nothing extra
/// to build/ship. Call `burst()` to fire it; it auto-clears itself after
/// the animation ends so it doesn't sit on top of the board afterwards.
class _ConfettiBurst extends StatefulWidget {
  const _ConfettiBurst({Key? key}) : super(key: key);

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Particle {
  _Particle(Random random)
      : angle = random.nextDouble() * 2 * pi,
        speed = 120 + random.nextDouble() * 160,
        size = 5 + random.nextDouble() * 6,
        colorIndex = random.nextInt(_confettiColors.length),
        spin = (random.nextBool() ? 1 : -1) * (2 + random.nextDouble() * 4);

  final double angle;
  final double speed;
  final double size;
  final int colorIndex;
  final double spin;
}

const _confettiColors = [
  Color(0xFFFFC107),
  Color(0xFFFF5252),
  Color(0xFF4CAF50),
  Color(0xFF448AFF),
  Color(0xFFAB47BC),
];

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  List<_Particle> _particles = [];

  void burst() {
    final random = Random();
    setState(() {
      _particles = List.generate(28, (_) => _Particle(random));
    });
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = Offset(size.width / 2, size.height * 0.4);
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final t = progress;
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t + (140 * t * t); // gravity
      final position = center + Offset(dx, dy);
      final paint = Paint()
        ..color = _confettiColors[p.colorIndex].withOpacity(fade);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(p.spin * t * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
