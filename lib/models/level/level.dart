import 'package:blocked/level/level.dart';

export 'level_chapter.dart';
export 'level_data.dart';
export 'level_list.dart';

class Level {
  const Level(this.name, {this.hint, required this.initialState});

  final String name;
  final String? hint;
  final LevelState initialState;
}
