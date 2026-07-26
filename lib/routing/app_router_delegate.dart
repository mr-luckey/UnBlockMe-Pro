import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/background/background.dart';
import 'package:blocked/editor/editor.dart';
import 'package:blocked/home_page.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  AppRouterDelegate({
    required this.chapters,
    required GlobalKey<NavigatorState> navigatorKey,
    required this.navigatorCubit,
  })  : _navigatorKey = navigatorKey,
        isLoaded = false {
    adManager.addAds(true, true, false);
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
                    MaterialPage(child: LevelMapPage(chapters)),
                  if (path is EditorRoutePath) ...[
                    const MaterialPage(child: LevelEditorPage()),
                    if (path.isInPreview)
                      MaterialPage(
                        key: ValueKey(path.location),
                        child: GeneratedLevelPage(path.mapString),
                      ),
                  ],
                  if (path is LevelRoutePath &&
                      path.chapterName != null &&
                      path.levelName != null)
                    MaterialPage(
                      key: ValueKey(path.location),
                      child: ScaffoldMessenger(
                        child: Scaffold(
                          body: Builder(
                            builder: (context) {
                              final allLevels =
                                  chapters.expand((c) => c.levels).toList();
                              final flat = LevelList(allLevels);
                              final levelData =
                                  flat.getLevelWithId(path.levelName!);
                              if (levelData == null) {
                                return const Center(
                                    child: Text('Level not found'));
                              }
                              final packName = chapters.first.name;
                              return LevelPage(
                                levelData.toLevel(),
                                boardControls: const BoardControls(),
                                key: Key(levelData.name),
                                onExit: () => navigatorCubit
                                    .navigateToChapterSelection(),
                                onNext: () {
                                  final next =
                                      flat.getLevelAfterId(path.levelName!);
                                  if (next != null) {
                                    navigatorCubit.navigateToLevel(
                                      packName,
                                      next.name,
                                    );
                                  } else {
                                    navigatorCubit
                                        .navigateToChapterSelection();
                                  }
                                },
                              );
                            },
                          ),
                          bottomNavigationBar: const SizedBox.shrink(),
                        ),
                      ),
                    ),
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
      } else if (configuration.mapString.isEmpty) {
        navigatorCubit.navigateToEditor();
      } else {
        navigatorCubit.navigateToEditorWithMapString(configuration.mapString);
      }
    } else if (configuration is LevelRoutePath) {
      if (configuration.levelName != null &&
          configuration.chapterName != null) {
        navigatorCubit.navigateToLevel(
            configuration.chapterName!, configuration.levelName!);
      } else {
        navigatorCubit.navigateToChapterSelection();
      }
    } else if (configuration.isSettings) {
      navigatorCubit.navigateToSettings();
    } else {
      navigatorCubit.navigateToHome();
    }

    return SynchronousFuture(null);
  }

  @override
  AppRoutePath? get currentConfiguration => navigatorCubit.state;

  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;
}
