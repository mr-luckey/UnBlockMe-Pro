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

/// Redesigned pack-selection screen.
///
/// What changed vs the old version:
/// - Plain stacked "BLOCKED" / "Choose a pack" text replaced with a gradient
///   hero banner (same visual language as the level-select header) so the
///   two screens now feel like one app instead of two different ones.
/// - Overall completion across ALL packs is now shown as a ring, giving the
///   player a sense of total progress before they even pick a pack.
class ChapterSelectionPage extends StatelessWidget {
  ChapterSelectionPage(this.chapters, {Key? key}) : super(key: key) {
    adManager.addAds(true, true, false);
  }

  final List<LevelChapter> chapters;
  final adManager = AdManager();

  Future<bool> _isChapterUnlocked(int index) async {
    if (unlockAllLevelsForTesting || index == 0) {
      return true;
    }
    final previous = chapters[index - 1];
    for (final level in previous.levels) {
      final stars = await getLevelStars(level.name);
      if (stars < 3) {
        return false;
      }
    }
    return true;
  }

  Future<double> _overallProgress() async {
    final allLevels = chapters.expand((c) => c.levels).toList();
    if (allLevels.isEmpty) return 0.0;
    final results = await Future.wait(
      allLevels.map((l) => isLevelCompleted(l.name)),
    );
    final completed = results.where((e) => e).length;
    return completed / allLevels.length;
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

      ///integration here
      body: Stack(
        children: [
          const RotatingPuzzleBackground(),
          CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text('Packs'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<double>(
                    future: _overallProgress(),
                    builder: (context, snapshot) {
                      return _PacksHeroCard(progress: snapshot.data ?? 0.0);
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 256,
                    childAspectRatio: 1,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chapter = chapters[index];
                      return FutureBuilder<bool>(
                        future: _isChapterUnlocked(index),
                        initialData: index == 0,
                        builder: (context, snapshot) {
                          final unlocked = snapshot.data ?? false;
                          return LabeledPuzzleButton(
                            isLocked: !unlocked,
                            label: Text(
                              chapter.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            metaText: unlocked
                                ? 'Unlocked'
                                : 'Complete previous pack with 3★',
                            puzzle: Hero(
                              tag: chapter.levels.first.name,
                              child: BlocProvider(
                                create: (context) => LevelBloc(chapter
                                    .levels.first
                                    .toLevel()
                                    .initialState),
                                child: const StaticPuzzle(),
                              ),
                            ),
                            onPressed: () {
                              context
                                  .read<NavigatorCubit>()
                                  .navigateToLevelSelection(chapter.name);
                            },
                          );
                        },
                      );
                    },
                    childCount: chapters.length,
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

class _PacksHeroCard extends StatelessWidget {
  const _PacksHeroCard({required this.progress});

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
                Hero(
                  tag: 'app_title',
                  child: Text('BLOCKED', style: theme.textTheme.displayMedium),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a pack',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${(progress * 100).round()}% of all levels cleared',
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor: colors.outline.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                ),
                Icon(Icons.extension_rounded, color: colors.primary, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
