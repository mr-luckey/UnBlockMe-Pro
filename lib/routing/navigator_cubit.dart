import 'package:blocked/routing/routing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigatorCubit extends Cubit<AppRoutePath> {
  NavigatorCubit(AppRoutePath initialPath)
      : shellTab = _tabForPath(initialPath),
        super(initialPath);

  /// Used by Hero widgets between map and level pages.
  String? latestLevelName;

  /// Persistent bottom-nav tab (0 Home, 1 Levels, 2 Settings).
  /// Opening a level does NOT change this — so Play won't flash the map.
  int shellTab;

  static int _tabForPath(AppRoutePath path) {
    if (path.isSettings) return 2;
    if (path is LevelRoutePath) return 1;
    return 0;
  }

  /// Tab shown in the shell. While a level is open, keep the previous tab
  /// underneath (covered by LevelPage) so Play never reveals Levels first.
  int effectiveShellTab([AppRoutePath? path]) {
    final p = path ?? state;
    if (p is LevelRoutePath && p.levelName != null) {
      return shellTab;
    }
    return _tabForPath(p);
  }

  void navigateToHome() {
    shellTab = 0;
    emit(const AppRoutePath.home());
  }

  void navigateToSettings() {
    shellTab = 2;
    emit(const AppRoutePath.settings());
  }

  void navigateToChapterSelection() {
    shellTab = 1;
    emit(const LevelRoutePath.chapterSelection());
  }

  /// Chapters UI removed — always show the adventure map.
  void navigateToLevelSelection(String chapterName) {
    navigateToChapterSelection();
  }

  /// Jump straight into gameplay. Does not switch the shell to Levels.
  void navigateToLevel(String chapterName, String levelName) {
    latestLevelName = levelName;
    emit(LevelRoutePath.level(chapterName: chapterName, levelName: levelName));
  }

  void navigateToPreviousPage() {
    if (state is LevelRoutePath) {
      final levelRoutePath = state as LevelRoutePath;
      if (levelRoutePath.levelName != null) {
        // Exit level → Levels map (standard puzzle-game flow).
        shellTab = 1;
        emit(const LevelRoutePath.chapterSelection());
      } else {
        shellTab = 0;
        emit(const AppRoutePath.home());
      }
    } else if (state.isSettings) {
      shellTab = 0;
      emit(const AppRoutePath.home());
    } else {
      shellTab = 0;
      emit(const AppRoutePath.home());
    }
  }
}
