import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:collection/collection.dart';

Future<List<MoveDirection>?> solve(PuzzleState initialState) async {
  final frontier = PriorityQueue<_PuzzleNode>();
  final visited = <int>{};
  final exits =
      _getExits(initialState.width, initialState.height, initialState.walls);
  frontier.add(_PuzzleNode(initialState, null, null, 0, h(initialState, exits),
      initialState.quickHash()));

  var count = 0;
  while (frontier.isNotEmpty) {
    count++;
    final current = frontier.removeFirst();
    final currentHashCode = current.stateHashCode;
    if (visited.contains(currentHashCode)) {
      continue;
    }
    if (count == 100) {
      /// A workaround to prevent the UI from stalling.
      await Future.delayed(Duration.zero);
      count = 0;
    }
    if (current.state.isCompleted) {
      return current.moves;
    }
    visited.add(currentHashCode);

    for (var moveDirection in MoveDirection.values) {
      final nextState =
          current.state.withMoveAttempt(MoveAttempt(moveDirection));
      final nextStateHash = nextState.quickHash();
      if (!visited.contains(nextStateHash)) {
        frontier.add(_PuzzleNode(nextState, current, moveDirection,
            current.moveCount + 1, h(nextState, exits), nextStateHash));
      }
    }
  }
  return null;
}

int h(PuzzleState state, List<Segment> exits) {
  final mainBlock = state.mainBlock;
  final controlledBlock = state.controlledBlock;
  final distanceToControlledBlock =
      getManhattanDistance(mainBlock.position, controlledBlock.position);
  final mainBlockMinDistanceToWall = exits
      .map((e) => getManhattanDistanceToWall(mainBlock.position, e))
      .reduce(min);
  return distanceToControlledBlock + mainBlockMinDistanceToWall;
}

int getManhattanDistanceToWall(Position blockPosition, Segment segment) {
  final segmentX = segment.start.x;
  final segmentY = segment.start.y;
  return getManhattanDistance(blockPosition, Position(segmentX, segmentY));
}

List<Segment> _getExits(
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

int getManhattanDistance(Position position1, Position position2) {
  return (position1.x - position2.x).abs() + (position1.y - position2.y).abs();
}

class _PuzzleNode extends Comparable<_PuzzleNode> {
  _PuzzleNode(
    this.state,
    this.parent,
    this.moveDirection,
    this.moveCount,
    this.hValue,
    this.stateHashCode,
  );

  final PuzzleState state;
  final _PuzzleNode? parent;
  final MoveDirection? moveDirection;
  final int moveCount;
  final int hValue;
  final int stateHashCode;

  List<MoveDirection> get moves =>
      (parent?.moves ?? []) + (moveDirection != null ? [moveDirection!] : []);
  bool get isGoal => state.isCompleted;

  @override
  int compareTo(_PuzzleNode other) {
    return (moveCount - other.moveCount) + (hValue - other.hValue);
  }
}

extension on PuzzleState {
  int quickHash() {
    return Object.hash(
      controlledBlock,
      Object.hashAllUnordered(blocks),
    );
  }
}
