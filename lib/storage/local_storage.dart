import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _boxName = 'app_data';
const _migrationFlag = '__migrated_from_shared_preferences_v1';

Box? _box;
Future<void>? _initFuture;
Future<void>? _writeChain;

/// Opens the Hive box and migrates legacy SharedPreferences data once.
Future<void> initLocalStorage() {
  return _initFuture ??= _doInit();
}

Future<void> _doInit() async {
  await Hive.initFlutter();
  _box = await Hive.openBox(_boxName);
  await _migrateFromSharedPreferencesIfNeeded();
}

Future<void> _migrateFromSharedPreferencesIfNeeded() async {
  final box = _box!;
  if (box.get(_migrationFlag) == true) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      final value = _readPrefValue(prefs, key);
      if (value != null && !box.containsKey(key)) {
        await box.put(key, value);
      }
    }
    if (kDebugMode) {
      debugPrint('[LocalStorage] migrated ${prefs.getKeys().length} keys from SharedPreferences');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[LocalStorage] SharedPreferences migration skipped: $e');
    }
  }

  await box.put(_migrationFlag, true);
}

Object? _readPrefValue(SharedPreferences prefs, String key) {
  final value = prefs.get(key);
  return value;
}

Box _requireBox() {
  final box = _box;
  if (box == null || !box.isOpen) {
    throw StateError('LocalStorage not initialized — call initLocalStorage() first');
  }
  return box;
}

/// Serialized writes — avoids overlapping disk flushes during level complete.
Future<T> serializedWrite<T>(Future<T> Function() action) {
  final previous = _writeChain ?? Future<void>.value();
  final result = previous.then((_) => action());
  _writeChain = result.then((_) {}, onError: (_) {});
  return result;
}

bool? getBool(String key) => _requireBox().get(key) as bool?;

int? getInt(String key) => _requireBox().get(key) as int?;

double? getDouble(String key) => _requireBox().get(key) as double?;

String? getString(String key) => _requireBox().get(key) as String?;

List<String>? getStringList(String key) {
  final value = _requireBox().get(key);
  if (value is List) {
    return value.cast<String>();
  }
  return null;
}

Future<void> setBool(String key, bool value) => _requireBox().put(key, value);

Future<void> setInt(String key, int value) => _requireBox().put(key, value);

Future<void> setDouble(String key, double value) => _requireBox().put(key, value);

Future<void> setString(String key, String value) => _requireBox().put(key, value);

Future<void> setStringList(String key, List<String> value) =>
    _requireBox().put(key, value);

Future<void> remove(String key) => _requireBox().delete(key);

Iterable<String> get allKeys =>
    _requireBox().keys.whereType<String>().where((k) => k != _migrationFlag);

bool containsKey(String key) => _requireBox().containsKey(key);
