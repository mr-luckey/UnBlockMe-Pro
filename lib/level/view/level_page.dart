import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/solver/solver.dart';
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
  Widget build(BuildContext context) {
    final isVerticalLayout =
        MediaQuery.of(context).size.width < MediaQuery.of(context).size.height;

    return BlocProvider(
      create: (context) => LevelBloc(level.initialState),
      child: BlocProvider(
        create: (context) => PuzzleSolverBloc(context.read<LevelBloc>()),
        child: Builder(builder: (context) {
          return Provider(
            create: (context) => LevelNavigation(
              onExit: onExit,
              onNext: () {
                if (context.read<LevelBloc>().state.isCompleted) {
                  onNext();
                }
              },
            ),
            child: LevelShortcutListener(
              levelBloc: context.read<LevelBloc>(),
              child: BlocConsumer<LevelBloc, LevelState>(
                listenWhen: (previous, current) =>
                    previous.isCompleted != current.isCompleted,
                listener: (context, state) {
                  if (state.isCompleted &&
                      !context
                          .read<PuzzleSolverBloc>()
                          .state
                          .hasSolutionResult) {
                    markLevelAsCompleted(level.name);
                  }
                },
                buildWhen: (previous, current) {
                  return previous.isCompleted != current.isCompleted;
                },
                builder: (context, state) {
                  final levelName = level.name;
                  final levelHint = level.hint;

                  final column = Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isVerticalLayout
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackButton(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          levelName,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      if (levelHint != null) ...{
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(levelHint,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                      },
                      const SizedBox(height: 32),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                      ),
                      const SizedBox(height: 32),
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
                        child: boardControls,
                      ),
                    ],
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 8.0),
                    child: isVerticalLayout
                        ? column
                        : Center(
                            child: IntrinsicHeight(
                              child: IntrinsicWidth(
                                child: column,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}
