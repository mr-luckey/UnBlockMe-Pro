import 'package:blocked/background/background.dart';
import 'package:blocked/editor/editor.dart';
import 'package:blocked/home_page.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ADs/ad_manager.dart';

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  AppRouterDelegate({
    required this.chapters,
    required GlobalKey<NavigatorState> navigatorKey,
    required this.navigatorCubit,
  })  : _navigatorKey = navigatorKey,
        isLoaded = false {
    adManager.addAds(true, true, true);
  }

  final GlobalKey<NavigatorState> _navigatorKey;
  final List<LevelChapter> chapters;
  final adManager = AdManager();

  final NavigatorCubit navigatorCubit;

  bool isLoaded;

  @override
  Widget build(BuildContext context) {
    return BoardColor(
      data: BoardColorData.fromColorScheme(Theme.of(context).colorScheme),
      child: BackgroundPuzzleController(
        child: BlocConsumer<NavigatorCubit, AppRoutePath>(
          bloc: navigatorCubit,
          listenWhen: (previous, current) => true,
          listener: (context, state) {
            notifyListeners();
          },
          builder: (context, state) {
            final path = state;
            final levels = (path is LevelRoutePath && path.chapterName != null)
                ? chapters.firstWhere((c) => c.name == path.chapterName!).levels
                : null;
            final levelList = levels != null ? LevelList(levels) : null;
            return BlocProvider(
              create: (context) => navigatorCubit,
              child: Navigator(
                key: _navigatorKey,
                pages: [
                  const MaterialPage(child: HomePage()),
                  if (path.isSettings)
                    const MaterialPage(
                        child: ScaffoldMessenger(child: SettingsPage())),
                  if (path is LevelRoutePath)
                    MaterialPage(child: ChapterSelectionPage(chapters)),
                  if (path is LevelRoutePath && path.chapterName != null)
                    MaterialPage(
                      child: LevelSelectionPage(chapters.firstWhere(
                        (c) => c.name == path.chapterName,
                      )),
                    ),
                  if (path is EditorRoutePath) ...{
                    const MaterialPage(child: LevelEditorPage()),
                    if (path.isInPreview)
                      MaterialPage(
                        key: ValueKey(path.location),
                        child: GeneratedLevelPage(
                            Uri.decodeComponent(path.mapString)),
                      ),
                  },
                  if (path is LevelRoutePath &&
                      path.chapterName != null &&
                      path.levelName != null &&
                      levelList != null) ...{
                    MaterialPage(
                      key: ValueKey(path.location),
                      child: ScaffoldMessenger(
                        child: Scaffold(
                          body: LevelPage(
                            levelList
                                .getLevelWithId(path.levelName!)!
                                .toLevel(),
                            boardControls: BoardControls(),
                            key: Key(levelList
                                .getLevelWithId(path.levelName!)!
                                .name),
                            onExit: () => navigatorCubit
                                .navigateToLevelSelection(path.chapterName!),
                            onNext: () {
                              final nextLevelName = levelList
                                  .getLevelAfterId(path.levelName!)
                                  ?.name;
                              if (nextLevelName != null) {
                                navigatorCubit.navigateToLevel(
                                    path.chapterName!, nextLevelName);
                              } else {
                                final nextChapter = chapters
                                    .skipWhile(
                                        (c) => c.name != path.chapterName!)
                                    .skip(1)
                                    .firstOrNull;
                                if (nextChapter != null) {
                                  navigatorCubit.navigateToLevel(
                                      nextChapter.name,
                                      nextChapter.levels.first.name);
                                } else {
                                  navigatorCubit.navigateToLevelSelection(
                                      path.chapterName!);
                                }
                              }
                            },
                          ),
                          bottomNavigationBar: adManager.getBannerAd() == null
                              ? Container(
                                  // alignment: Alignment.center,
                                  child: AdWidget(ad: adManager.getBannerAd()!),
                                  width: adManager
                                      .getBannerAd()
                                      ?.size
                                      .width
                                      .toDouble(),
                                  height: adManager
                                      .getBannerAd()
                                      ?.size
                                      .height
                                      .toDouble(),
                                )
                              : SizedBox.shrink(),

                          ///integrastion herer
                        ),
                      ),
                    ),
                  }
                ],
                onPopPage: (route, result) {
                  if (!route.didPop(result)) {
                    return false;
                  }
                  navigatorCubit.navigateToPreviousPage();
                  return true;
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Future<void> setInitialRoutePath(AppRoutePath configuration) {
    setNewRoutePath(configuration);
    isLoaded = true;
    return SynchronousFuture(null);
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) {
    if (configuration is EditorRoutePath) {
      if (configuration.isInPreview) {
        navigatorCubit.navigateToGeneratedLevel(configuration.mapString);
      } else {
        if (configuration.mapString.isEmpty) {
          navigatorCubit.navigateToEditor();
        } else {
          navigatorCubit.navigateToEditorWithMapString(configuration.mapString);
        }
      }
    } else if (configuration is LevelRoutePath) {
      if (configuration.levelName != null) {
        navigatorCubit.navigateToLevel(
            configuration.chapterName!, configuration.levelName!);
      } else if (configuration.chapterName != null) {
        navigatorCubit.navigateToLevelSelection(configuration.chapterName!);
      } else {
        navigatorCubit.navigateToChapterSelection();
      }
    } else {
      if (configuration.isSettings) {
        navigatorCubit.navigateToSettings();
      } else {
        navigatorCubit.navigateToHome();
      }
    }

    return SynchronousFuture(null);
  }

  @override
  AppRoutePath? get currentConfiguration => navigatorCubit.state;

  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;
}
