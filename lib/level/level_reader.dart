import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

const String wallStr = '*';
const String empty = '.';
const String block = 'x';
const String mainBlock = 'm';
const String exit = 'e';
const String sharpWallStr = '~';
const String sharpAndRoundWallStr = '+';

typedef Tile = int;

class TileType {
  static const wall = 1;
  static const block = 2;
  static const empty = 4;
  static const main = 8;
  static const exit = 16;
  static const control = 32;
  static const sharpWall = 64;
}

const defaultMap = [
  '********e',
  '*MMM.x..e',
  '*..*..*.e',
  '*xxx.xxx*',
  '*..*....*',
  '*..x.x..*',
  '*********',
];

bool isTileType(Tile tile, Tile type) {
  return (tile & type) == type;
}

extension on int {
  int segmentToTileCount() {
    return 1 + this * 2;
  }

  int toTileCount() {
    return 1 + (this - 1) * 2;
  }
}

Future<List<LevelChapter>> readLevelsFromYaml() async {
  final chapters = <LevelChapter>[];
  final data = await rootBundle.loadString('assets/levels.yaml');
  final yamlData = loadYaml(data);

  for (YamlMap chapterData in yamlData) {
    final name = chapterData['name'].toString();
    final description = chapterData['description'].toString();
    final levelsData = chapterData['levels'];

    final levels = <LevelData>[];
    for (YamlMap levelData in levelsData) {
      final name = levelData['name']!.toString();
      final String? hint = levelData['hint'];
      final map = levelData['map']!.toString();
      levels.add(LevelData(
        name: name.toString(),
        hint: hint?.toString(),
        map: map,
      ));
    }
    chapters.add(LevelChapter(name, description, levels));
  }
  return chapters;
}

String stateToMapString(LevelState state) {
  return toMapString(
      width: state.width,
      height: state.height,
      walls: state.walls,
      sharpWalls: state.sharpWalls,
      blocks: state.blocks);
}

String specsToMapString(PuzzleSpecifications state) {
  return toMapString(
    width: state.width,
    height: state.height,
    walls: state.walls,
    sharpWalls: state.sharpWalls,
    blocks: state.blocks,
  );
}

String toMapString({
  required int width,
  required int height,
  required Iterable<Segment> walls,
  required Iterable<Segment> sharpWalls,
  required Iterable<PlacedBlock> blocks,
}) {
  final map = List<List<String>>.generate(height.toTileCount() + 2, (y) {
    return List.generate(width.toTileCount() + 2, (x) {
      if (x == 0 ||
          x == width.toTileCount() + 1 ||
          y == 0 ||
          y == height.toTileCount() + 1) {
        return 'e';
      }
      return '.';
    });
  });

  for (final wall in walls) {
    final wallTileWidth = wall.width.segmentToTileCount();
    final wallTileHeight = wall.height.segmentToTileCount();
    for (var dx = 0; dx < wallTileWidth; dx++) {
      for (var dy = 0; dy < wallTileHeight; dy++) {
        map[wall.start.y * 2 + dy][wall.start.x * 2 + dx] = '*';
      }
    }
  }

  for (final sharpWall in sharpWalls) {
    final wallTileWidth = sharpWall.width.segmentToTileCount();
    final wallTileHeight = sharpWall.height.segmentToTileCount();
    for (var dx = 0; dx < wallTileWidth; dx++) {
      for (var dy = 0; dy < wallTileHeight; dy++) {
        final x = sharpWall.start.x * 2 + dx;
        final y = sharpWall.start.y * 2 + dy;
        if (map[y][x] == sharpAndRoundWallStr || map[y][x] == wallStr) {
          map[y][x] = sharpAndRoundWallStr;
        } else {
          map[y][x] = sharpWallStr;
        }
      }
    }
  }

  for (final block in blocks) {
    final blockTileWidth = block.width.toTileCount();
    final blockTileHeight = block.height.toTileCount();
    var blockChar = block.isMain ? 'm' : 'x';
    if (block.hasControl) {
      blockChar = blockChar.toUpperCase();
    }

    for (var dx = 0; dx < blockTileWidth; dx++) {
      for (var dy = 0; dy < blockTileHeight; dy++) {
        map[block.top * 2 + 1 + dy][block.left * 2 + 1 + dx] = blockChar;
      }
    }
  }

  return map.map((row) {
    return row.join();
  }).join('\n');
}

LevelState parseLevel(String mapString) {
  return _parseLevelFromTiles(_parseTilesFromMap(mapString.split('\n')));
}

PuzzleSpecifications parsePuzzleSpecs(String mapString) {
  return _parsePuzzleFromTiles(_parseTilesFromMap(mapString.split('\n')));
}

List<List<Tile>> _parseTilesFromMap(Iterable<String> rawMap) {
  return rawMap.map((line) {
    return line.split('').map((char) {
      if (char == wallStr) {
        return TileType.wall;
      } else if (char == sharpWallStr) {
        return TileType.sharpWall;
      } else if (char == sharpAndRoundWallStr) {
        return TileType.wall | TileType.sharpWall;
      } else if (char == empty) {
        return TileType.empty;
      } else if (char == exit) {
        return TileType.exit;
      } else {
        var baseBlock = char.toLowerCase() == block
            ? TileType.block
            : TileType.block | TileType.main;
        if (char == char.toUpperCase()) {
          baseBlock = baseBlock | TileType.control;
        }
        return baseBlock;
      }
    }).toList();
  }).toList();
}

List<Segment> _getSegmentsOfType(List<List<Tile>> map, Tile type) {
  final segments = <Segment>[];
  final width = map[0].length;
  final height = map.length;

  bool isWall(int x, int y) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return isTileType(map[y][x], type);
    } else {
      return false;
    }
  }

  // Get horizontal walls
  for (var row = 0; row < height; row++) {
    final starts = Iterable.generate(width,
            (col) => isWall(col, row) && !isWall(col - 1, row) ? col : -1)
        .where((index) => index != -1)
        .toList();
    final ends = Iterable.generate(width,
            (col) => isWall(col, row) && !isWall(col + 1, row) ? col : -1)
        .where((index) => index != -1)
        .toList();

    assert(
        starts.length == ends.length, 'Wall segments are not closed properly');

    for (var i = 0; i < starts.length; i++) {
      // Only add isolated walls
      if (starts[i] == ends[i]) {
        final x = starts[i];
        if (!isWall(x, row - 1) && !isWall(x, row + 1)) {
          segments.add(Segment.point(x: x ~/ 2, y: row ~/ 2));
        }
      } else {
        segments.add(Segment.horizontal(
            y: row ~/ 2, start: starts[i] ~/ 2, end: ends[i] ~/ 2));
      }
    }
  }

  // Get vertical walls
  for (var col = 0; col < width; col++) {
    final starts = Iterable.generate(height,
            (row) => isWall(col, row) && !isWall(col, row - 1) ? row : -1)
        .where((index) => index != -1)
        .toList();
    final ends = Iterable.generate(height,
            (row) => isWall(col, row) && !isWall(col, row + 1) ? row : -1)
        .where((index) => index != -1)
        .toList();

    assert(
        starts.length == ends.length, 'Wall segments are not closed properly');

    for (var i = 0; i < starts.length; i++) {
      // Don't add isolated walls again
      if (starts[i] != ends[i]) {
        segments.add(Segment.vertical(
            x: col ~/ 2, start: starts[i] ~/ 2, end: ends[i] ~/ 2));
      }
    }
  }

  return segments;
}

PuzzleSpecifications _parsePuzzleFromTiles(List<List<Tile>> map) {
  final width = map[0].length;
  final height = map.length;

  assert(width % 2 == 1 && height % 2 == 1, 'Map must be odd-sized');

  final walls = _getSegmentsOfType(map, TileType.wall);
  final sharpWalls = _getSegmentsOfType(map, TileType.sharpWall);
  final parsedBlocks = getBlocks(map);

  return PuzzleSpecifications(
    width: width ~/ 2,
    height: height ~/ 2,
    walls: walls,
    sharpWalls: sharpWalls,
    blocks: parsedBlocks,
  );
}

LevelState _parseLevelFromTiles(List<List<Tile>> map) {
  final spec = _parsePuzzleFromTiles(map);
  return LevelState.initial(
    PuzzleState.initial(
      spec.width,
      spec.height,
      blocks: spec.blocks,
      walls: spec.walls,
      sharpWalls: spec.sharpWalls,
    ),
  );
}

List<PlacedBlock> getBlocks(List<List<int>> map) {
  final blocks = <PlacedBlock>[];

  final blockTopLefts = <Position>[];
  final blockBottomRights = <Position>[];

  final width = map[0].length;
  final height = map.length;

  bool isBlock(int x, int y) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      return isTileType(map[y][x], TileType.block);
    } else {
      return false;
    }
  }

  for (var row = 0; row < height; row++) {
    for (var col = 0; col < width; col++) {
      final isAboveBlock = isBlock(col, row - 1);
      final isLeftBlock = isBlock(col - 1, row);
      final isCurrentBlock = isBlock(col, row);

      if (isCurrentBlock && !isAboveBlock && !isLeftBlock) {
        blockTopLefts.add(Position(col, row));
      }
    }
  }

  for (var blockTopLeft in blockTopLefts) {
    // Go as right as possible
    var right = blockTopLeft.x;
    var bottom = blockTopLeft.y;
    while (isBlock(right + 1, bottom)) {
      right++;
    }

    while (isBlock(right, bottom + 1)) {
      bottom++;
    }
    blockBottomRights.add(Position(right, bottom));
  }

  assert(blockTopLefts.length == blockBottomRights.length,
      'Blocks are not placed properly');

  for (var i = 0; i < blockTopLefts.length; i++) {
    final position = blockTopLefts[i];
    final actualPosition = Position(position.x ~/ 2, position.y ~/ 2);
    final isMain = isTileType(map[position.y][position.x], TileType.main);
    final isControlled =
        isTileType(map[position.y][position.x], TileType.control);
    final blockWidth = blockBottomRights[i].x - position.x + 1;
    final blockHeight = blockBottomRights[i].y - position.y + 1;

    blocks.add(PlacedBlock(
      blockWidth ~/ 2 + 1,
      blockHeight ~/ 2 + 1,
      actualPosition,
      isMain: isMain,
      hasControl: isControlled,
    ));
  }

  return blocks;
}
