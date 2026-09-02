import 'dart:async';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/storage/storage.dart';
import 'package:flutter/foundation.dart';

const _levelPrefix = 'progress.level.';
/// Set to false before release to restore level/chapter locks.
const bool unlockAllLevelsForTesting = false;

const _starsPrefix = 'progress.stars.';
const _bestSecondsPrefix = 'progress.bestSeconds.';
const _bestMovesPrefix = 'progress.bestMoves.';
const _totalStarsKey = 'progress.totalStars';
const _levelsSolvedKey = 'progress.levelsSolved';
const _currentStreakKey = 'progress.currentStreak';
const _bestStreakKey = 'progress.bestStreak';
const _lastPlayDateKey = 'progress.lastPlayDate';

/// Call during startup so the first level-complete write is not racing init.
Future<void> warmProgressPreferences() => initLocalStorage();

Future<T> _serializedProgressWrite<T>(Future<T> Function() action) =>
    serializedWrite(action);

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
}) {
  return _serializedProgressWrite(() async {
    final oldStars = getInt('$_starsPrefix$levelName') ?? 0;
    final newStars =
        calculateStars(moves: moves, minimumMoves: minimumMoves);
    final savedStars = newStars > oldStars ? newStars : oldStars;

    final wasCompleted = getBool('$_levelPrefix$levelName') ??
        getBool(levelName) ??
        false;
    await setBool('$_levelPrefix$levelName', true);
    await setInt('$_starsPrefix$levelName', savedStars);

    final bestMoves = getInt('$_bestMovesPrefix$levelName');
    if (bestMoves == null || moves < bestMoves) {
      await setInt('$_bestMovesPrefix$levelName', moves);
    }
    final bestSeconds = getInt('$_bestSecondsPrefix$levelName');
    if (bestSeconds == null || elapsedSeconds < bestSeconds) {
      await setInt('$_bestSecondsPrefix$levelName', elapsedSeconds);
    }

    if (!wasCompleted) {
      final solved = getInt(_levelsSolvedKey) ?? 0;
      await setInt(_levelsSolvedKey, solved + 1);
      await _updateStreak();
    }

    final totalStars = _recomputeTotalStars();
    await setInt(_totalStarsKey, totalStars);
    _hasProgressStreamController.add(true);
    _playerProgressStreamController.add(await getPlayerProgress());
    _mapProgressStreamController.add(null);
  });
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

Future<void> _updateStreak() async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayKey = _dateKey(today);
  final lastDateRaw = getString(_lastPlayDateKey);
  final currentStreak = getInt(_currentStreakKey) ?? 0;

  int nextStreak;
  if (lastDateRaw == todayKey) {
    nextStreak = currentStreak == 0 ? 1 : currentStreak;
  } else if (lastDateRaw == null) {
    nextStreak = 1;
  } else {
    try {
      final parts = lastDateRaw.split('-');
      if (parts.length != 3) {
        nextStreak = 1;
      } else {
        final lastDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final difference = today.difference(lastDate).inDays;
        nextStreak = difference == 1 ? currentStreak + 1 : 1;
      }
    } catch (_) {
      nextStreak = 1;
    }
  }

  final bestStreak = getInt(_bestStreakKey) ?? 0;
  await setInt(_currentStreakKey, nextStreak);
  await setInt(
    _bestStreakKey,
    nextStreak > bestStreak ? nextStreak : bestStreak,
  );
  await setString(_lastPlayDateKey, todayKey);
}

String _dateKey(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

int _recomputeTotalStars() {
  var sum = 0;
  for (final key in allKeys) {
    if (key.startsWith(_starsPrefix)) {
      sum += getInt(key) ?? 0;
    }
  }
  return sum;
}

Future<PlayerProgress> getPlayerProgress() async {
  return PlayerProgress(
    totalStars: getInt(_totalStarsKey) ?? 0,
    levelsSolved: getInt(_levelsSolvedKey) ?? 0,
    currentStreak: getInt(_currentStreakKey) ?? 0,
    bestStreak: getInt(_bestStreakKey) ?? 0,
  );
}

Future<int> getLevelStars(String levelName) async {
  return getInt('$_starsPrefix$levelName') ?? 0;
}

/// One Hive round-trip for the whole map (not N awaits).
Future<MapLevelProgress> loadMapLevelProgress(List<String> levelNames) async {
  final stars = <String, int>{};
  var currentIndex = 0;
  for (var i = 0; i < levelNames.length; i++) {
    final name = levelNames[i];
    final s = getInt('$_starsPrefix$name') ?? 0;
    final completed = getBool('$_levelPrefix$name') ??
        getBool(name) ??
        false;
    stars[name] = s;
    // Advance cursor for completed levels (stars OR completion flag).
    if (s > 0 || completed) currentIndex = i + 1;
  }
  if (levelNames.isEmpty) {
    currentIndex = 0;
  } else if (currentIndex >= levelNames.length) {
    currentIndex = levelNames.length - 1;
  }

  final unlocked = List<bool>.generate(levelNames.length, (i) {
    if (unlockAllLevelsForTesting || i == 0) return true;
    final prev = levelNames[i - 1];
    final prevDone = (stars[prev] ?? 0) >= 2 ||
        (getBool('$_levelPrefix$prev') ?? false);
    return prevDone;
  });

  return MapLevelProgress(
    stars: stars,
    unlocked: unlocked,
    currentIndex: currentIndex,
  );
}

@immutable
class MapLevelProgress {
  const MapLevelProgress({
    required this.stars,
    required this.unlocked,
    required this.currentIndex,
  });

  final Map<String, int> stars;
  final List<bool> unlocked;
  final int currentIndex;
}

Future<int> getTotalStars() async {
  return getInt(_totalStarsKey) ?? 0;
}

Future<int?> getBestMoves(String levelName) async {
  return getInt('$_bestMovesPrefix$levelName');
}

Future<int?> getBestSeconds(String levelName) async {
  return getInt('$_bestSecondsPrefix$levelName');
}

Future<void> rebuildProgressStats() async {
  final stars = _recomputeTotalStars();
  await setInt(_totalStarsKey, stars);
  _playerProgressStreamController.add(await getPlayerProgress());
  _mapProgressStreamController.add(null);
}

Future<bool> isLevelCompleted(String levelName) async {
  return getBool('$_levelPrefix$levelName') ??
      getBool(levelName) ??
      false;
}

Future<void> clearData() async {
  _hasProgressStreamController.add(false);

  for (final key in allKeys.toList()) {
    if (key != AdaptiveTheme.prefKey) {
      await remove(key);
    }
  }
  _playerProgressStreamController.add(await getPlayerProgress());
  _mapProgressStreamController.add(null);
}

Future<List<String>> getFirstUncompletedLevel([
  List<LevelChapter>? knownChapters,
]) async {
  // Prefer in-memory chapters — never re-parse YAML on Play tap.
  final chapters = knownChapters ?? await readLevelsFromYaml();
  if (chapters.isEmpty) {
    return ['', ''];
  }

  bool completed(String name) =>
      getBool('$_levelPrefix$name') ?? getBool(name) ?? false;
  int stars(String name) => getInt('$_starsPrefix$name') ?? 0;

  for (var i = 0; i < chapters.length; i++) {
    final chapter = chapters[i];

    for (final level in chapter.levels) {
      if (!completed(level.name)) {
        return [chapter.name, level.name];
      }
    }

    if (i < chapters.length - 1) {
      final nextUnlocked = unlockAllLevelsForTesting ||
          chapter.levels.every((l) => stars(l.name) >= 3);
      if (!nextUnlocked) {
        for (final level in chapter.levels) {
          if (stars(level.name) < 3) {
            return [chapter.name, level.name];
          }
        }
      }
    }
  }
  return [chapters.last.name, chapters.last.levels.last.name];
}

Future<bool> hasProgress() async {
  for (final key in allKeys) {
    if (key.startsWith(_levelPrefix) && (getBool(key) ?? false)) {
      return true;
    }
    if (!key.startsWith('progress.') &&
        key != AdaptiveTheme.prefKey &&
        (getBool(key) ?? false)) {
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

/// Fires when any per-level map data (stars / unlocks) changes.
Stream<void> mapProgressStream() => _mapProgressStreamController.stream;

StreamController<void> _mapProgressStreamController =
    StreamController<void>.broadcast();
