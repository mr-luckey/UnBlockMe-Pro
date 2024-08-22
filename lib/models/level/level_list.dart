import 'package:blocked/models/models.dart';
import 'package:collection/collection.dart';

class LevelList {
  LevelList(this.levels);

  final List<LevelData> levels;

  LevelData? getLevelWithId(String id) {
    return levels.where((level) => level.name == id).firstOrNull;
  }

  LevelData? getLevelAfterId(String id) {
    return levels.skipWhile((level) => level.name != id).skip(1).firstOrNull;
  }
}
