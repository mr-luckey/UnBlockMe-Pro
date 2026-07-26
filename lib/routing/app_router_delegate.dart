import 'package:blocked/background/background.dart';
import 'package:blocked/editor/editor.dart';
import 'package:blocked/home_page.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../ADs/ad_manager.dart';

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

  Future<bool> _isChapterUnlocked(int chapterIndex) async {
    if (unlockAllLevelsForTesting || chapterIndex <= 0) {
      return true;
    }
    final previous = chapters[chapterIndex - 1];
    for (final level in previous.levels) {
      final stars = await getLevelStars(level.name);
      if (stars < 3) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showNextPackLockedDialog(
    BuildContext context,
    int chapterIndex,
  ) async {
    if (chapterIndex <= 0) {
      return;
    }
    final previous = chapters[chapterIndex - 1];
    var totalStars = 0;
    for (final level in previous.levels) {
      totalStars += await getLevelStars(level.name);
    }
    final requiredStars = previous.levels.length * 3;
    final remaining = (requiredStars - totalStars).clamp(0, requiredStars);
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Next Pack Locked'),
          content: Text(
            'Complete previous pack stars first.\n'
            'Required stars: $requiredStars★\n'
            'Current stars: $totalStars★\n'
            'Need $remaining more star${remaining == 1 ? '' : 's'}.',
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
                                () async {
                                  final currentChapterIndex = chapters.indexWhere(
                                    (c) => c.name == path.chapterName!,
                                  );
                                  final nextChapterIndex =
                                      currentChapterIndex + 1;
                                  if (nextChapterIndex >= chapters.length) {
                                    navigatorCubit.navigateToLevelSelection(
                                        path.chapterName!);
                                    return;
                                  }

                                  final unlocked =
                                      await _isChapterUnlocked(nextChapterIndex);
                                  if (!unlocked) {
                                    await _showNextPackLockedDialog(
                                      context,
                                      nextChapterIndex,
                                    );
                                    return;
                                  }

                                  final nextChapter = chapters[nextChapterIndex];
                                  navigatorCubit.navigateToLevel(
                                    nextChapter.name,
                                    nextChapter.levels.first.name,
                                  );
                                }();
                              }
                            },
                          ),
                          bottomNavigationBar: const SizedBox.shrink(),

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
