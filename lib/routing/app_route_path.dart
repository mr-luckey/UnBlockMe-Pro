import 'dart:convert';

import 'package:archive/archive.dart';

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

class EditorRoutePath extends AppRoutePath {
  EditorRoutePath.editor(this.mapString)
      : isInPreview = false,
        super('/editor/${encodeMapString(mapString)}');
  EditorRoutePath.generatedLevel(this.mapString)
      : isInPreview = true,
        super('/editor/generated/${encodeMapString(mapString)}');

  final bool isInPreview;
  final String mapString;
}

String encodeMapString(String mapString) {
  final zlibEncoded = const ZLibEncoder().encode(utf8.encode(mapString));
  return Uri.encodeComponent(base64.encode(zlibEncoded));
}

String decodeMapString(String encodedMapString) {
  final zlibEncoded = base64.decode(Uri.decodeComponent(encodedMapString));
  return utf8.decode(const ZLibDecoder().decodeBytes(zlibEncoded));
}
