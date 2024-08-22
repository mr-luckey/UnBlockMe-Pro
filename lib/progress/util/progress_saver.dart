import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:blocked/level/level.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> markLevelAsCompleted(String levelName) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.setBool(levelName, true);
  _hasProgressStreamController.add(true);
}

Future<bool> isLevelCompleted(String levelName) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getBool(levelName) ?? false;
}

Future<void> clearData() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  _hasProgressStreamController.add(false);

  for (final key in sharedPreferences.getKeys()) {
    if (key != AdaptiveTheme.prefKey) {
      await sharedPreferences.remove(key);
    }
  }
}

Future<List<String>> getFirstUncompletedLevel() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final keys = sharedPreferences.getKeys();
  final chapters = await readLevelsFromYaml();
  for (final chapter in chapters) {
    for (final level in chapter.levels) {
      if (!keys.contains(level.name)) {
        return [chapter.name, level.name];
      }
    }
  }
  return [chapters.last.name, chapters.last.levels.last.name];
}

Future<bool> hasProgress() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final keys = sharedPreferences.getKeys();
  keys.remove(AdaptiveTheme.prefKey);
  return keys.isNotEmpty;
}

StreamController<bool> _hasProgressStreamController =
    StreamController.broadcast(onListen: () async {
  _hasProgressStreamController.add(await hasProgress());
});

Stream<bool> hasProgressStream() => _hasProgressStreamController.stream;
