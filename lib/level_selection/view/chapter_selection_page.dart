import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../ADs/ad_manager.dart';

class ChapterSelectionPage extends StatelessWidget {
  ChapterSelectionPage(this.chapters, {Key? key}) : super(key: key) {
    adManager.addAds(true, true, true);
  }

  final List<LevelChapter> chapters;
  final adManager = AdManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        // alignment: Alignment.center,
        child: AdWidget(ad: adManager.getBannerAd()!),
        width: adManager.getBannerAd()?.size.width.toDouble(),
        height: adManager.getBannerAd()?.size.height.toDouble(),
      ),

      ///integration here
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
                    Hero(
                      tag: 'app_title',
                      child: Text('Blocked',
                          style: Theme.of(context).textTheme.displayMedium),
                    ),
                    const SizedBox(height: 32),
                    Text('chapters',
                        style: Theme.of(context).textTheme.displaySmall),
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
                      return LabeledPuzzleButton(
                        label: Text(
                          chapter.name,
                          style: Theme.of(context).textTheme.titleLarge,
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
