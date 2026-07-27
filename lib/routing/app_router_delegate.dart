import 'package:blocked/background/background.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/widgets/main_shell.dart';
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
        flatLevels = [
          for (final c in chapters)
            for (final l in c.levels) _Flat(c.name, l)
        ],
        isLoaded = false;

  final GlobalKey<NavigatorState> _navigatorKey;
  final List<LevelChapter> chapters;
  final List<_Flat> flatLevels;
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
            final levelPath = path is LevelRoutePath ? path : null;
            final inLevel = levelPath?.levelName != null &&
                levelPath?.chapterName != null;

            return BlocProvider.value(
              value: navigatorCubit,
              child: Navigator(
                key: _navigatorKey,
                pages: [
                  // Single persistent shell — tab switches are IndexedStack only.
                  MaterialPage(
                    key: const ValueKey('main-shell'),
                    child: MainShell(chapters: chapters),
                  ),

                  if (inLevel)
                    MaterialPage(
                      key: ValueKey(levelPath!.location),
                      child: ScaffoldMessenger(
                        child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: LevelPage(
                            chapters
                                .expand((c) => c.levels)
                                .firstWhere(
                                    (l) => l.name == levelPath.levelName!)
                                .toLevel(),
                            boardControls: const BoardControls(),
                            key: Key(levelPath.levelName!),
                            levelNumber: () {
                              final i = flatLevels.indexWhere(
                                  (f) => f.level.name == levelPath.levelName!);
                              return i < 0 ? 1 : i + 1;
                            }(),
                            onExit: () =>
                                navigatorCubit.navigateToChapterSelection(),
                            onNext: () => _goNext(levelPath.levelName!),
                          ),
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

  void _goNext(String levelName) {
    final idx = flatLevels.indexWhere((f) => f.level.name == levelName);
    if (idx < 0 || idx >= flatLevels.length - 1) {
      navigatorCubit.navigateToChapterSelection();
      return;
    }
    final next = flatLevels[idx + 1];
    navigatorCubit.navigateToLevel(next.chapter, next.level.name);
  }

  @override
  Future<void> setInitialRoutePath(AppRoutePath configuration) {
    setNewRoutePath(configuration);
    isLoaded = true;
    return SynchronousFuture(null);
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) {
    if (configuration is LevelRoutePath) {
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

class _Flat {
  _Flat(this.chapter, this.level);
  final String chapter;
  final LevelData level;
}
