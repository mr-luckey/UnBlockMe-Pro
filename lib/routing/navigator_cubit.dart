import 'package:blocked/editor/editor.dart';
import 'package:blocked/routing/routing.dart';
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
    // Chapters removed — adventure map is the level browser.
    emit(const LevelRoutePath.chapterSelection());
  }

  void navigateToLevel(String chapterName, String levelName) {
    emit(LevelRoutePath.level(chapterName: chapterName, levelName: levelName));
    latestLevelName = levelName;
  }

  void navigateToEditor() {
    navigateToEditorWithMapString(kDefaultMapString);
  }

  void navigateToEditorWithMapString(String mapString) {
    emit(EditorRoutePath.editor(mapString));
  }

  void navigateToGeneratedLevel(String mapString) {
    emit(EditorRoutePath.generatedLevel(mapString));
  }

  void navigateToPreviousPage() {
    if (state is LevelRoutePath) {
      final levelRoutePath = state as LevelRoutePath;
      if (levelRoutePath.levelName != null) {
        emit(const LevelRoutePath.chapterSelection());
      } else {
        emit(const AppRoutePath.home());
      }
    } else if (state is EditorRoutePath) {
      final editorRoutePath = state as EditorRoutePath;
      if (editorRoutePath.isInPreview) {
        emit(EditorRoutePath.editor(editorRoutePath.mapString));
      } else {
        emit(const AppRoutePath.home());
      }
    } else {
      emit(const AppRoutePath.home());
    }
  }
}
