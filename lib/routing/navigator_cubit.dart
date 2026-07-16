import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigatorCubit extends Cubit<AppRoutePath> {
  NavigatorCubit(AppRoutePath initialPath) : super(initialPath);

  /// The id of the latest level that was visited.
  /// Used by the [Hero] widgets in level selection and level pages to
  /// determine which puzzle widgets to animate to.
  String? latestLevelName;

  void navigateToHome() {
    emit(const AppRoutePath.home());
  }

  void navigateToSettings() {
    emit(const AppRoutePath.settings());
  }

  void navigateToChapterSelection() {
    emit(const LevelRoutePath.chapterSelection());
  }

  void navigateToLevelSelection(String chapterName) {
    emit(LevelRoutePath.levelSelection(chapterName: chapterName));
  }

  void navigateToLevel(String chapterName, String levelName) {
    emit(LevelRoutePath.level(chapterName: chapterName, levelName: levelName));
    latestLevelName = levelName;
  }

  void navigateToPreviousPage() {
    if (state is LevelRoutePath) {
      final levelRoutePath = state as LevelRoutePath;
      if (levelRoutePath.chapterName != null &&
          levelRoutePath.levelName != null) {
        // Currently in level page.
        emit(LevelRoutePath.levelSelection(
            chapterName: levelRoutePath.chapterName));
      } else if (levelRoutePath.chapterName != null) {
        // In level selection page.
        emit(const LevelRoutePath.chapterSelection());
      } else {
        emit(const AppRoutePath.home());
      }
    } else {
      emit(const AppRoutePath.home());
    }
  }
}
