class AppRoutePath {
  const AppRoutePath(this.location);
  const AppRoutePath.home() : this('/');
  const AppRoutePath.settings() : this('/settings');

  final String location;

  bool get isHome => location == '/';
  bool get isSettings => location == '/settings';
}

class LevelRoutePath extends AppRoutePath {
  const LevelRoutePath.chapterSelection()
      : chapterName = null,
        levelName = null,
        super('/levels');
  const LevelRoutePath.levelSelection({required this.chapterName})
      : levelName = null,
        super('/levels/$chapterName');
  const LevelRoutePath.level(
      {required this.chapterName, required this.levelName})
      : super('/levels/$chapterName/$levelName');

  final String? chapterName;
  final String? levelName;

  bool get isChapterSelection => chapterName == null;
  bool get isLevelSelection => chapterName != null && levelName == null;
  bool get isLevel => chapterName != null && levelName != null;
}
