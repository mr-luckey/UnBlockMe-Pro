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

class ChapterSelectionPage extends StatelessWidget {
  ChapterSelectionPage(this.chapters, {Key? key}) : super(key: key);

  final List<LevelChapter> chapters;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'app_title',
                      child: Text('BLOCKED',
                          style: Theme.of(context).textTheme.displayMedium),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose a pack',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              )),
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
                            meta: Text(
                              unlocked
                                  ? 'Unlocked'
                                  : 'Complete previous pack with 3★',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            puzzle: Hero(
                              tag: chapter.levels.first.name,
                              child: BlocProvider(
                                create: (context) => LevelBloc(
                                    chapter.levels.first.toLevel().initialState),
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
            ],
          ),
        ],
      ),
    );
  }
}
