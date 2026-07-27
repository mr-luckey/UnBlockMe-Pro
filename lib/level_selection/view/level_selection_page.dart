import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LevelSelectionPage extends StatelessWidget {
  LevelSelectionPage(this.chapter, {Key? key})
      : levels = chapter.levels.map((data) => data.toLevel()).toList(),
        super(key: key);

  final LevelChapter chapter;
  final List<Level> levels;

  Future<int> _completedCount() async {
    final results = await Future.wait(levels.map((l) => isLevelCompleted(l.name)));
    return results.where((e) => e).length;
  }

  Future<void> _showLevelLockedDialog(
    BuildContext context, {
    required int index,
  }) async {
    if (index <= 0) {
      return;
    }
    final previousLevel = levels[index - 1];
    final currentStars = await getLevelStars(previousLevel.name);
    const requiredStars = 2;
    final missingStars = (requiredStars - currentStars).clamp(0, requiredStars);
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Level Locked'),
          content: Text(
            'Complete the previous level to unlock this level.\n'
            'Required stars: $requiredStars★\n'
            'Current stars on ${previousLevel.name}: ${currentStars.clamp(0, 3)}★\n'
            'Need ${missingStars} more star${missingStars == 1 ? '' : 's'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomNav(current: AppBottomTab.levels),
        ],
      ),

      ///integration herte
      body: Stack(
        children: [
          const RotatingPuzzleBackground(),
          CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text('Levels'),
              ),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.name,
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 10),
                    Text(
                      chapter.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<int>(
                      future: _completedCount(),
                      builder: (context, snapshot) {
                        final completed = snapshot.data ?? 0;
                        final progress =
                            levels.isEmpty ? 0.0 : completed / levels.length;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completed of ${levels.length} completed',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              )),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final level = levels[index];
                      final initialLevelState = level.initialState;
                      return FutureBuilder<bool>(
                        initialData: false,
                        future: isLevelCompleted(level.name),
                        builder: (context, snapshot) {
                          final starsFuture = getLevelStars(level.name);
                          final bestMovesFuture = getBestMoves(level.name);
                          final bestSecondsFuture = getBestSeconds(level.name);
                          final previousStarsFuture = unlockAllLevelsForTesting ||
                                  index == 0
                              ? Future.value(true)
                              : getLevelStars(levels[index - 1].name)
                                  .then((stars) => stars >= 2);
                          return FutureBuilder<bool>(
                            future: previousStarsFuture,
                            initialData: true,
                            builder: (context, prevSnapshot) {
                              final isLocked = unlockAllLevelsForTesting
                                  ? false
                                  : !(prevSnapshot.data ?? false);
                              return LabeledPuzzleButton(
                                onPressed: () {
                                  context
                                      .read<NavigatorCubit>()
                                      .navigateToLevel(chapter.name, level.name);
                                },
                                onLockedPressed: () async {
                                  await _showLevelLockedDialog(
                                    context,
                                    index: index,
                                  );
                                },
                                isLocked: isLocked,
                                isCompleted: snapshot.data ?? false,
                                puzzle: Hero(
                                  tag: context.select((NavigatorCubit cubit) {
                                    final latestLevelName = cubit.latestLevelName;
                                    return latestLevelName == level.name
                                        ? 'puzzle'
                                        : level.name;
                                  }),
                                  child: BlocProvider(
                                    create: (context) =>
                                        LevelBloc(initialLevelState),
                                    child: const StaticPuzzle(),
                                  ),
                                ),
                                label: Text(
                                  level.name.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                trailing: FutureBuilder<int>(
                                  future: starsFuture,
                                  builder: (context, starSnapshot) {
                                    final stars = starSnapshot.data ?? 0;
                                    if (stars == 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      '⭐' * stars,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    );
                                  },
                                ),
                                meta: FutureBuilder<List<int?>>(
                                  future:
                                      Future.wait([bestMovesFuture, bestSecondsFuture]),
                                  builder: (context, metaSnapshot) {
                                    final bestMoves = metaSnapshot.data?[0];
                                    final bestSeconds = metaSnapshot.data?[1];
                                    if (isLocked) {
                                      return Text(
                                        'Locked',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      );
                                    }
                                    if (bestMoves == null || bestSeconds == null) {
                                      return Text(
                                        'Not solved yet',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      );
                                    }
                                    return Text(
                                      '$bestMoves moves · ${bestSeconds}s',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    childCount: levels.length,
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
