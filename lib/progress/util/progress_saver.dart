import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _levelPrefix = 'progress.level.';
/// Set to false before release to restore level/chapter locks.
const bool unlockAllLevelsForTesting = true;

const _starsPrefix = 'progress.stars.';
const _bestSecondsPrefix = 'progress.bestSeconds.';
const _bestMovesPrefix = 'progress.bestMoves.';
const _totalStarsKey = 'progress.totalStars';
const _levelsSolvedKey = 'progress.levelsSolved';
const _currentStreakKey = 'progress.currentStreak';
const _bestStreakKey = 'progress.bestStreak';
const _lastPlayDateKey = 'progress.lastPlayDate';

@immutable
class PlayerProgress {
  const PlayerProgress({
    required this.totalStars,
    required this.levelsSolved,
    required this.currentStreak,
    required this.bestStreak,
  });

  final int totalStars;
  final int levelsSolved;
  final int currentStreak;
  final int bestStreak;
}

Future<void> markLevelAsCompleted(
  String levelName, {
  required int moves,
  required int elapsedSeconds,
  required int minimumMoves,
}) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final oldStars = sharedPreferences.getInt('$_starsPrefix$levelName') ?? 0;
  final newStars =
      calculateStars(moves: moves, minimumMoves: minimumMoves);
  final savedStars = newStars > oldStars ? newStars : oldStars;

  final wasCompleted = await isLevelCompleted(levelName);
  await sharedPreferences.setBool('$_levelPrefix$levelName', true);
  await sharedPreferences.setInt('$_starsPrefix$levelName', savedStars);

  final bestMoves = sharedPreferences.getInt('$_bestMovesPrefix$levelName');
  if (bestMoves == null || moves < bestMoves) {
    await sharedPreferences.setInt('$_bestMovesPrefix$levelName', moves);
  }
  final bestSeconds = sharedPreferences.getInt('$_bestSecondsPrefix$levelName');
  if (bestSeconds == null || elapsedSeconds < bestSeconds) {
    await sharedPreferences.setInt('$_bestSecondsPrefix$levelName', elapsedSeconds);
  }

  if (!wasCompleted) {
    final solved = sharedPreferences.getInt(_levelsSolvedKey) ?? 0;
    await sharedPreferences.setInt(_levelsSolvedKey, solved + 1);
    await _updateStreak(sharedPreferences);
  }

  final totalStars = await _recomputeTotalStars(sharedPreferences);
  await sharedPreferences.setInt(_totalStarsKey, totalStars);
  _hasProgressStreamController.add(true);
  _playerProgressStreamController.add(await getPlayerProgress());
}

int calculateStars({
  required int moves,
  required int minimumMoves,
}) {
  if (moves <= minimumMoves) {
    return 3;
  }
  if (moves <= minimumMoves + 2) {
    return 2;
  }
  return 1;
}

Future<void> _updateStreak(SharedPreferences preferences) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayKey = _dateKey(today);
  final lastDateRaw = preferences.getString(_lastPlayDateKey);
  final currentStreak = preferences.getInt(_currentStreakKey) ?? 0;

  int nextStreak;
  if (lastDateRaw == todayKey) {
    nextStreak = currentStreak == 0 ? 1 : currentStreak;
  } else if (lastDateRaw == null) {
    nextStreak = 1;
  } else {
    final parts = lastDateRaw.split('-');
    final lastDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final difference = today.difference(lastDate).inDays;
    nextStreak = difference == 1 ? currentStreak + 1 : 1;
  }

  final bestStreak = preferences.getInt(_bestStreakKey) ?? 0;
  await preferences.setInt(_currentStreakKey, nextStreak);
  await preferences.setInt(
    _bestStreakKey,
    nextStreak > bestStreak ? nextStreak : bestStreak,
  );
  await preferences.setString(_lastPlayDateKey, todayKey);
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

Future<int> _recomputeTotalStars(SharedPreferences sharedPreferences) async {
  var sum = 0;
  for (final key in sharedPreferences.getKeys()) {
    if (key.startsWith(_starsPrefix)) {
      sum += sharedPreferences.getInt(key) ?? 0;
    }
  }
  return sum;
}

Future<PlayerProgress> getPlayerProgress() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return PlayerProgress(
    totalStars: sharedPreferences.getInt(_totalStarsKey) ?? 0,
    levelsSolved: sharedPreferences.getInt(_levelsSolvedKey) ?? 0,
    currentStreak: sharedPreferences.getInt(_currentStreakKey) ?? 0,
    bestStreak: sharedPreferences.getInt(_bestStreakKey) ?? 0,
  );
}

Future<int> getLevelStars(String levelName) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getInt('$_starsPrefix$levelName') ?? 0;
}

Future<int> getTotalStars() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getInt(_totalStarsKey) ?? 0;
}

Future<int?> getBestMoves(String levelName) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getInt('$_bestMovesPrefix$levelName');
}

Future<int?> getBestSeconds(String levelName) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getInt('$_bestSecondsPrefix$levelName');
}

Future<void> rebuildProgressStats() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final stars = await _recomputeTotalStars(sharedPreferences);
  await sharedPreferences.setInt(_totalStarsKey, stars);
  _playerProgressStreamController.add(await getPlayerProgress());
}

Future<bool> isLevelCompleted(String levelName) async {
  final sharedPreferences = await SharedPreferences.getInstance();
  return sharedPreferences.getBool('$_levelPrefix$levelName') ??
      sharedPreferences.getBool(levelName) ??
      false;
}

Future<void> clearData() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  _hasProgressStreamController.add(false);

  for (final key in sharedPreferences.getKeys()) {
    if (key != AdaptiveTheme.prefKey) {
      await sharedPreferences.remove(key);
    }
  }
  _playerProgressStreamController.add(await getPlayerProgress());
}

Future<List<String>> getFirstUncompletedLevel() async {
  final chapters = await readLevelsFromYaml();
  for (var i = 0; i < chapters.length; i++) {
    final chapter = chapters[i];

    // Find first unsolved level in the current chapter.
    for (final level in chapter.levels) {
      if (!await isLevelCompleted(level.name)) {
        return [chapter.name, level.name];
      }
    }

    // If this chapter is fully solved but not max-starred, keep the user here
    // until they earn enough stars to unlock the next pack.
    if (i < chapters.length - 1) {
      final nextChapterUnlocked = await _isNextChapterUnlocked(chapter);
      if (!nextChapterUnlocked) {
        for (final level in chapter.levels) {
          final stars = await getLevelStars(level.name);
          if (stars < 3) {
            return [chapter.name, level.name];
          }
        }
      }
    }
  }
  return [chapters.last.name, chapters.last.levels.last.name];
}

Future<bool> _isNextChapterUnlocked(LevelChapter chapter) async {
  if (unlockAllLevelsForTesting) {
    return true;
  }
  for (final level in chapter.levels) {
    final stars = await getLevelStars(level.name);
    if (stars < 3) {
      return false;
    }
  }
  return true;
}

Future<bool> hasProgress() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  for (final key in sharedPreferences.getKeys()) {
    if (key.startsWith(_levelPrefix) && (sharedPreferences.getBool(key) ?? false)) {
      return true;
    }
    if (!key.startsWith('progress.') &&
        key != AdaptiveTheme.prefKey &&
        (sharedPreferences.getBool(key) ?? false)) {
      return true;
    }
  }
  return false;
}

StreamController<bool> _hasProgressStreamController =
    StreamController.broadcast(onListen: () async {
  _hasProgressStreamController.add(await hasProgress());
});

Stream<bool> hasProgressStream() => _hasProgressStreamController.stream;

StreamController<PlayerProgress> _playerProgressStreamController =
    StreamController.broadcast(onListen: () async {
  _playerProgressStreamController.add(await getPlayerProgress());
});

Stream<PlayerProgress> playerProgressStream() =>
    _playerProgressStreamController.stream;
