import 'dart:async';

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
                        const SizedBox(height: 8),
                        const _GoalCard(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _StatPanel(
                                label: 'MOVES',
                                value: '${state.moves}',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatPanel(label: 'PAR', value: '$par'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatPanel(
                                label: 'BEST',
                                value: _minimumMoves?.toString() ?? '-',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Center(
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
                                  final toHero = toHeroContext.widget as Hero;
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.42),
                  blurRadius: 34,
                  offset: Offset(0, 14),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.star_rounded,
                        size: 42,
                        color: index < stars
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outline.withValues(alpha: 0.35),
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
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.40),
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

class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Goal: Move the main block (O) to the exit →',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
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

class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
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
