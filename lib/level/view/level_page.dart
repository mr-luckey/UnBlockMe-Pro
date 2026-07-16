import 'dart:async';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/solver/solver.dart';
import 'package:blocked/solver/puzzle_solver.dart';
import 'package:flutter/material.dart';
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
                    if (state.isCompleted && !_savedCompletion) {
                      _savedCompletion = true;
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isPerfect = stars == 3;
        return Dialog(
          backgroundColor: theme.colorScheme.surface.withOpacity(0),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.42),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    widget.level.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stars pop in one-by-one instead of appearing all at once.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
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
                          size: 42,
                          color: index < stars
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.outline.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isPerfect ? 'Excellent!' : 'Completed!',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: isPerfect
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.40),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ResultRow(
                        label: 'Time',
                        value: _formatDuration(_stopwatch.elapsed),
                      ),
                      const Divider(height: 16),
                      _ResultRow(label: 'Moves', value: '$moveCount'),
                      const Divider(height: 16),
                      _ResultRow(
                        label: 'Stars Earned',
                        value: '+${stars * 10} ⭐',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<LevelNavigation>().onExit();
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: const Text('Levels'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<LevelNavigation>().onNext();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next'),
                  ),
                ),
              ],
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
