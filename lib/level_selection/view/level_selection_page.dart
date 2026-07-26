import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blocked/widgets/app_bottom_nav.dart';
import '../../ADs/ad_manager.dart';

/// Redesigned level-select screen.
///
/// What changed vs the old version:
/// - Header is now a real "hero" block (gradient card + circular progress)
///   instead of plain stacked Text widgets -> gives the screen a focal point.
/// - Locked dialog replaced with a friendlier bottom sheet that visualizes
///   stars-needed instead of a wall of text in an AlertDialog.
/// - Cards now pass typed `stars` / `metaText` into the redesigned
///   LabeledPuzzleButton (see puzzle_button.dart) instead of building ad-hoc
///   trailing/meta widgets inline here.
class LevelSelectionPage extends StatelessWidget {
  LevelSelectionPage(this.chapter, {Key? key})
      : levels = chapter.levels.map((data) => data.toLevel()).toList(),
        super(key: key) {
    adManager.addAds(true, true, false);
  }

  final LevelChapter chapter;
  final adManager = AdManager();
  final List<Level> levels;

  Future<int> _completedCount() async {
    final results =
        await Future.wait(levels.map((l) => isLevelCompleted(l.name)));
    return results.where((e) => e).length;
  }

  Future<void> _showLevelLockedSheet(
    BuildContext context, {
    required int index,
  }) async {
    if (index <= 0) return;
    final previousLevel = levels[index - 1];
    final currentStars = (await getLevelStars(previousLevel.name)).clamp(0, 3);
    const requiredStars = 2;
    final missingStars = (requiredStars - currentStars).clamp(0, requiredStars);
    if (!context.mounted) return;

    final theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_rounded,
                        color: theme.colorScheme.tertiary, size: 28),
                    const SizedBox(width: 10),
                    Text('Level locked', style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Earn $requiredStars★ on "${previousLevel.name}" to unlock this level.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(requiredStars, (i) {
                    final filled = i < currentStars;
                    return Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 32,
                      color: filled
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.outline,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  missingStars == 0
                      ? 'Almost there — replay it to lock the unlock in.'
                      : 'Need $missingStars more star${missingStars == 1 ? '' : 's'}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Got it'),
                  ),
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
    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppBottomNav(current: AppBottomTab.levels),
        ],
      ),
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
                  child: FutureBuilder<int>(
                    future: _completedCount(),
                    builder: (context, snapshot) {
                      final completed = snapshot.data ?? 0;
                      final progress =
                          levels.isEmpty ? 0.0 : completed / levels.length;
                      return _ChapterHeroCard(
                        title: chapter.name,
                        description: chapter.description,
                        completed: completed,
                        total: levels.length,
                        progress: progress,
                      );
                    },
                  ),
                ),
              ),
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
                          final previousStarsFuture =
                              unlockAllLevelsForTesting || index == 0
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
                              return FutureBuilder<List<Object?>>(
                                future: Future.wait([
                                  starsFuture,
                                  bestMovesFuture,
                                  bestSecondsFuture,
                                ]),
                                builder: (context, metaSnapshot) {
                                  final stars =
                                      (metaSnapshot.data?[0] as int?) ?? 0;
                                  final bestMoves =
                                      metaSnapshot.data?[1] as int?;
                                  final bestSeconds =
                                      metaSnapshot.data?[2] as int?;

                                  final String? metaText = isLocked
                                      ? null
                                      : (bestMoves == null ||
                                              bestSeconds == null)
                                          ? 'Not solved yet'
                                          : '$bestMoves moves · ${bestSeconds}s';

                                  return LabeledPuzzleButton(
                                    onPressed: () {
                                      context
                                          .read<NavigatorCubit>()
                                          .navigateToLevel(
                                              chapter.name, level.name);
                                    },
                                    onLockedPressed: () async {
                                      await _showLevelLockedSheet(
                                        context,
                                        index: index,
                                      );
                                    },
                                    isLocked: isLocked,
                                    isCompleted: snapshot.data ?? false,
                                    stars: stars,
                                    metaText: metaText,
                                    puzzle: Hero(
                                      tag: context
                                          .select((NavigatorCubit cubit) {
                                        final latestLevelName =
                                            cubit.latestLevelName;
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
                                    ),
                                  );
                                },
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
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapterHeroCard extends StatelessWidget {
  const _ChapterHeroCard({
    required this.title,
    required this.description,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String title;
  final String description;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.18),
            colors.tertiary.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: colors.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.displaySmall),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '$completed of $total levels cleared',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: colors.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
