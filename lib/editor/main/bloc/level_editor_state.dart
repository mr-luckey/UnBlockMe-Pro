part of 'level_editor_bloc.dart';

class LevelEditorState {
  LevelEditorState.fromPuzzleSpecifications(PuzzleSpecifications specs)
      : this.initial([
          ...specs.blocks.map((block) => EditorBlock.initial(block)),
          ..._withoutOuterWalls(specs.width, specs.height, specs.walls).map(
              (wall) => EditorSegment.initial(wall, type: SegmentType.wall)),
          ...specs.sharpWalls.map(
              (wall) => EditorSegment.initial(wall, type: SegmentType.sharp)),
          EditorFloor.initial(specs.width, specs.height),
        ]);
  const LevelEditorState.initial(this.objects)
      : selectedObject = null,
        generatedPuzzle = null,
        snackbarMessage = null,
        selectedTool = EditorTool.move,
        isGridVisible = true;
  const LevelEditorState(
    this.objects, {
    required this.selectedObject,
    required this.generatedPuzzle,
    required this.snackbarMessage,
    required this.selectedTool,
    required this.isGridVisible,
  });

  static const EditorObject _invalidObject = _InvalidEditorObject();
  static const LevelState _invalidPuzzleState = _InvalidPuzzleState();

  final List<EditorObject> objects;
  final EditorObject? selectedObject;
  final LevelState? generatedPuzzle;
  final SnackbarMessage? snackbarMessage;
  final EditorTool selectedTool;
  final bool isGridVisible;

  bool get isTesting => generatedPuzzle != null;

  EditorFloor get floor => objects.whereType<EditorFloor>().first;

  Iterable<EditorSegment> get segments => objects.whereType<EditorSegment>();

  Iterable<EditorSegment> get walls =>
      segments.where((segment) => segment.type == SegmentType.wall);

  Iterable<EditorSegment> get sharpWalls =>
      segments.where((segment) => segment.type == SegmentType.sharp);

  Iterable<EditorBlock> get blocks => objects.whereType<EditorBlock>();

  Iterable<EditorSegment> get exits =>
      segments.where((segment) => isExit(segment));

  EditorBlock? get mainBlock => objects
      .whereType<EditorBlock>()
      .where((block) => block.isMain)
      .firstOrNull;

  EditorBlock? get initialBlock => objects
      .whereType<EditorBlock>()
      .where((block) => block.hasControl)
      .firstOrNull;

  static bool hasBlockIntersection(
      int width, int height, Iterable<PlacedBlock> blocks) {
    final visited = List.generate(height, (i) => List.filled(width, false));
    for (var block in blocks) {
      for (var y = block.top; y <= block.bottom; y++) {
        for (var x = block.left; x <= block.right; x++) {
          if (visited[y][x]) return true;
          visited[y][x] = true;
        }
      }
    }
    return false;
  }

  bool segmentFits(Segment segment) {
    return segment.start.x >= 0 &&
        segment.start.x <= floor.width &&
        segment.start.y >= 0 &&
        segment.start.y <= floor.height &&
        segment.end.x >= 0 &&
        segment.end.x <= floor.width &&
        segment.end.y >= 0 &&
        segment.end.y <= floor.height;
  }

  bool blockFits(PlacedBlock block) {
    return block.left >= 0 &&
        block.right < floor.width &&
        block.top >= 0 &&
        block.bottom < floor.height;
  }

  String? getMapString() {
    final blocks = getGeneratedBlocks().where((block) => blockFits(block));
    final walls = getGeneratedWalls().where((wall) => segmentFits(wall));
    final sharpWalls =
        getGeneratedSharpWalls().where((wall) => segmentFits(wall));

    if (hasBlockIntersection(floor.width, floor.height, blocks)) {
      return null;
    }

    return toMapString(
      width: floor.width,
      height: floor.height,
      walls: walls,
      sharpWalls: sharpWalls,
      blocks: blocks,
    );
  }

  bool isExit(EditorSegment segment) {
    final dx = -floor.left;
    final dy = -floor.top;
    final translatedSegment = segment.toSegment().translate(dx, dy);
    return _isSegmentOuterWall(floor.width, floor.height, translatedSegment);
  }

  static bool _isSegmentOuterWall(int width, int height, Segment segment) {
    if (segment.isVertical) {
      final isXValid = segment.start.x == 0 || segment.start.x == width;
      final isYValid = segment.start.y >= 0 && segment.end.y <= height;
      return isXValid && isYValid;
    } else {
      final isXValid = segment.start.x >= 0 && segment.end.x <= width;
      final isYValid = segment.start.y == 0 || segment.start.y == height;
      return isXValid && isYValid;
    }
  }

  static List<Segment> _withoutOuterWalls(
      int width, int height, Iterable<Segment> segments) {
    final outerWalls =
        segments.where((s) => _isSegmentOuterWall(width, height, s));

    final exits = _generateOuterWallsWithout(width, height, outerWalls);

    final innerWalls =
        segments.whereNot((s) => outerWalls.contains(s)).toList();
    return innerWalls + exits;
  }

  LevelEditorState copyWith({
    List<EditorObject>? objects,
    EditorObject? selectedObject = _invalidObject,
    LevelState? generatedPuzzle = _invalidPuzzleState,
    SnackbarMessage? snackbarMessage,
    EditorTool? selectedTool,
    bool? isGridVisible,
  }) {
    return LevelEditorState(
      objects ?? this.objects,
      selectedObject: selectedObject != _invalidObject
          ? selectedObject
          : this.selectedObject,
      generatedPuzzle: generatedPuzzle != _invalidPuzzleState
          ? generatedPuzzle
          : this.generatedPuzzle,
      selectedTool: selectedTool ?? this.selectedTool,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
      isGridVisible: isGridVisible ?? this.isGridVisible,
    );
  }

  LevelEditorState withGeneratedPuzzle() {
    try {
      return copyWith(
        generatedPuzzle: _generatePuzzleFromEditorObjects(),
      );
    } on EditorException catch (e) {
      return copyWith(snackbarMessage: SnackbarMessage.error(e.message));
    }
  }

  LevelEditorState withoutGeneratedPuzzle() {
    return copyWith(generatedPuzzle: null);
  }

  LevelEditorState withSelectedObject(EditorObject? object) {
    return copyWith(
      selectedObject: object,
    );
  }

  LevelEditorState withUpdatedObjectPosition(
      EditorObject object, Size size, Offset offset) {
    assert(objects.contains(object),
        'Editor object is not in list of known editor objects');

    return withUpdatedObject(
        object, object.copyWith(size: size, offset: offset));
  }

  LevelEditorState withUpdatedObject(
      EditorObject object, EditorObject newObject) {
    final wasSelected = selectedObject == object;
    assert(objects.contains(object),
        'Editor object is not in list of known editor objects');
    assert(object.key == newObject.key,
        'New editor object does not have the same key as the old object');

    final newObjects = [
      ...objects,
    ];

    newObjects[newObjects.indexOf(object)] = newObject;

    return copyWith(
        objects: newObjects,
        selectedObject: wasSelected ? newObject : selectedObject,
        generatedPuzzle: null);
  }

  LevelEditorState withMainBlock(EditorBlock block) {
    assert(objects.contains(block),
        'Editor block is not in list of known editor objects');

    // Set main to false for current main block
    final state = mainBlock != null
        ? withUpdatedObject(mainBlock!, mainBlock!.copyWith(isMain: false))
        : this;

    // Set main to true
    final newBlock = block.copyWith(
      isMain: true,
    );
    return state.withUpdatedObject(block, newBlock);
  }

  LevelEditorState withControlBlock(EditorBlock block) {
    assert(objects.contains(block),
        'Editor block is not in list of known editor objects');

    // Set control to false for current initial block
    final state = initialBlock != null
        ? withUpdatedObject(
            initialBlock!, initialBlock!.copyWith(hasControl: false))
        : this;

    // Set control to true
    final newBlock = block.copyWith(
      hasControl: true,
    );
    return state.withUpdatedObject(block, newBlock);
  }

  LevelEditorState withSegmentWithType(
      EditorSegment editorSegment, SegmentType type) {
    assert(objects.contains(editorSegment),
        'Editor segment is not in list of known editor objects');

    final newSegment = editorSegment.copyWith(
      type: type,
    );
    return withUpdatedObject(editorSegment, newSegment);
  }

  List<PlacedBlock> getGeneratedBlocks() {
    final dx = -floor.left;
    final dy = -floor.top;
    return blocks.map((block) => block.toBlock().translate(dx, dy)).toList();
  }

  List<Segment> getGeneratedWalls() {
    final dx = -floor.left;
    final dy = -floor.top;

    final exitSegments = exits.map((e) => e.toSegment().translate(dx, dy));

    final outerWalls =
        _generateOuterWallsWithout(floor.width, floor.height, exitSegments);

    final innerWalls = walls
        .whereNot((wall) => isExit(wall))
        .map((wall) => wall.toSegment().translate(dx, dy))
        .toList();

    return outerWalls + innerWalls;
  }

  List<Segment> getGeneratedSharpWalls() {
    final dx = -floor.left;
    final dy = -floor.top;

    final sharpWalls = this
        .sharpWalls
        .whereNot((wall) => isExit(wall))
        .map((wall) => wall.toSegment().translate(dx, dy))
        .toList();

    return sharpWalls;
  }

  static List<Segment> _generateOuterWallsWithout(
      int mapWidth, int mapHeight, Iterable<Segment> wallsToSubtract) {
    final outerWalls = [
      Segment.horizontal(y: 0, start: 0, end: mapWidth),
      Segment.horizontal(y: mapHeight, start: 0, end: mapWidth),
      Segment.vertical(x: 0, start: 0, end: mapHeight),
      Segment.vertical(x: mapWidth, start: 0, end: mapHeight),
    ];

    return outerWalls
        .map((wall) => wall.subtractAll(wallsToSubtract))
        .flattened
        .toList();
  }

  LevelState _generatePuzzleFromEditorObjects() {
    final dx = -floor.left;
    final dy = -floor.top;

    final generatedBlocks =
        getGeneratedBlocks().where((block) => blockFits(block)).toList();
    final generatedInitialBlock = initialBlock?.toBlock().translate(dx, dy);

    if (hasBlockIntersection(floor.width, floor.height, generatedBlocks)) {
      throw const EditorException('Overlapping blocks found');
    } else if (generatedInitialBlock == null) {
      throw const EditorException('No initial block found');
    } else if (!blockFits(generatedInitialBlock)) {
      throw const EditorException('Initial block does not fit in puzzle');
    } else if (mainBlock == null) {
      throw const EditorException('No main block found');
    } else if (exits.isEmpty) {
      throw const EditorException('Puzzle has no exits');
    }
    final generatedWalls =
        getGeneratedWalls().where((wall) => segmentFits(wall)).toList();
    final generatedSharpWalls =
        getGeneratedSharpWalls().where((wall) => segmentFits(wall)).toList();

    final state = LevelState.initial(
      PuzzleState.initial(
        floor.width,
        floor.height,
        blocks: generatedBlocks,
        walls: generatedWalls,
        sharpWalls: generatedSharpWalls,
      ),
    );
    return state;
  }
}

enum SnackbarMessageType {
  error,
  info,
}

class SnackbarMessage {
  const SnackbarMessage._(this.message, this.type);
  const SnackbarMessage.error(String message)
      : this._(message, SnackbarMessageType.error);
  const SnackbarMessage.info(String message)
      : this._(message, SnackbarMessageType.info);

  final String message;
  final SnackbarMessageType type;
}
