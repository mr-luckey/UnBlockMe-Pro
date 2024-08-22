import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../ADs/ad_manager.dart';

class LevelSelectionPage extends StatelessWidget {
  LevelSelectionPage(this.chapter, {Key? key})
      : levels = chapter.levels.map((data) => data.toLevel()).toList(),
        super(key: key) {
    adManager.addAds(true, true, true);
  }

  final LevelChapter chapter;
  final adManager = AdManager();
  final List<Level> levels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        // alignment: Alignment.center,
        child: AdWidget(ad: adManager.getBannerAd()!),
        width: adManager.getBannerAd()?.size.width.toDouble(),
        height: adManager.getBannerAd()?.size.height.toDouble(),
      ),

      ///integration herte
      body: Stack(
        children: [
          const RotatingPuzzleBackground(),
          CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
              ),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${chapter.name} - ${chapter.description}',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 32),
                    Text('levels',
                        style: Theme.of(context).textTheme.displaySmall),
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
                          return LabeledPuzzleButton(
                            onPressed: () {
                              context
                                  .read<NavigatorCubit>()
                                  .navigateToLevel(chapter.name, level.name);
                            },
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
                              level.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
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
