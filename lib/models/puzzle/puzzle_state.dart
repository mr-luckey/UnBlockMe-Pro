import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:equatable/equatable.dart';

class PuzzleState extends Equatable {
  PuzzleState.initial(
    this.width,
    this.height, {
    required this.blocks,
    required this.walls,
    required this.sharpWalls,
  })  : assert(blocks.where((block) => block.isMain).length == 1,
            'Puzzle requires exactly one main block.'),
        assert(blocks.any((block) => block.hasControl),
            'Puzzle requires at least one controlled block.'),
        assert(
            blocks.every((block) =>
                block.top >= 0 &&
                block.left >= 0 &&
                block.bottom < height &&
                block.right < width),
            'Blocks must be placed within the puzzle.');

  const PuzzleState(
    this.width,
    this.height, {
    required this.blocks,
    required this.walls,
    required this.sharpWalls,
  });

  final int width;
  final int height;
  final List<PlacedBlock> blocks;
  final List<Segment> walls;
  final List<Segment> sharpWalls;

  PlacedBlock get mainBlock => blocks.firstWhere((block) => block.isMain);

  // TODO: Allow for multiple controlled blocks
  PlacedBlock get controlledBlock =>
      blocks.firstWhere((block) => block.hasControl);
  bool get isCompleted => !_canFit(mainBlock);

  PuzzleState withMoveAttempt(MoveAttempt move) {
    final movedBlock = controlledBlock;
    final newPosition = movedBlock.position.shifted(move.direction);
    final newBlock = movedBlock.withPosition(newPosition);
    if (hasWallInDirection(movedBlock, move.direction)) {
      return this;
    }

    final blocksAhead = getBlocksAhead(movedBlock, move.direction);

    if (willBeCutInDirection(movedBlock, move.direction)) {
      if (blocksAhead.isEmpty) {
        // Cut the block
        final cutBlocks = cutBlockInDirection(movedBlock, move.direction);
        final newControlledBlock = cutBlocks[0].copyWith(hasControl: true);
        return PuzzleState(
          width,
          height,
          blocks: blocks
              .map((block) => block == movedBlock
                  ? newControlledBlock
                  : block.copyWith(hasControl: false))
              .toList()
            ..addAll(cutBlocks.skip(1)),
          walls: walls,
          sharpWalls: sharpWalls,
        );
      } else {
        return this;
      }
    }

    if (blocksAhead.isNotEmpty) {
      if (blocksAhead.length == 1) {
        final newControlledBlock = blocksAhead.first;
        return _withControlledBlock(newControlledBlock);
      } else {
        return this;
      }
    }

    if (!_canFit(newBlock) && !newBlock.isMain) {
      return this;
    }

    return _withMovedBlock(movedBlock, move.direction);
  }

  PuzzleState? getIntermediateStateWithMoveAttempt(MoveAttempt move) {
    final movedBlock = controlledBlock;
    if (hasWallInDirection(movedBlock, move.direction)) {
      return null;
    }

    final blocksAhead = getBlocksAhead(movedBlock, move.direction);

    if (willBeCutInDirection(movedBlock, move.direction)) {
      if (blocksAhead.isEmpty) {
        // Cut the block
        final cutBlocks = cutBlockInDirection(movedBlock, move.direction)
            .map((b) =>
                b.shifted(move.direction.opposite).copyWith(hasControl: true))
            .toList();
        return PuzzleState(
          width,
          height,
          blocks: blocks
              .map((block) => block == movedBlock ? cutBlocks[0] : block)
              .toList()
            ..addAll(cutBlocks.skip(1)),
          walls: walls,
          sharpWalls: sharpWalls,
        );
      }
    }
    return null;
  }

  PuzzleState _withControlledBlock(PlacedBlock newControlledBlock) {
    final newBlockWithControl = newControlledBlock.copyWith(hasControl: true);
    final newBlocks = blocks
        .map((block) => block == newControlledBlock
            ? newBlockWithControl
            : block.copyWith(hasControl: false))
        .toList();
    return PuzzleState(
      width,
      height,
      blocks: newBlocks,
      walls: walls,
      sharpWalls: sharpWalls,
    );
  }

  PuzzleState _withMovedBlock(PlacedBlock movedBlock, MoveDirection direction) {
    final newPosition = movedBlock.position.shifted(direction);
    final newBlock = movedBlock.withPosition(newPosition);
    return PuzzleState(
      width,
      height,
      blocks: blocks.map((b) {
        return b == movedBlock ? newBlock : b;
      }).toList(),
      walls: walls,
      sharpWalls: sharpWalls,
    );
  }

  Iterable<PlacedBlock> getBlocksAhead(
      PlacedBlock block, MoveDirection direction) {
    switch (direction) {
      case MoveDirection.up:
        return _getBlocksTop(block);
      case MoveDirection.down:
        return _getBlocksBottom(block);
      case MoveDirection.left:
        return _getBlocksLeft(block);
      case MoveDirection.right:
        return _getBlocksRight(block);
    }
  }

  Iterable<PlacedBlock> _getBlocksTop(PlacedBlock block) {
    return blocks
        .where((b) => b != block)
        .where((b) => b.bottom == block.top - 1)
        .where((b) =>
            _isRangeIntersecting(block.left, block.right, b.left, b.right));
  }

  Iterable<PlacedBlock> _getBlocksBottom(PlacedBlock block) {
    return blocks
        .where((b) => b != block)
        .where((b) => b.top == block.bottom + 1)
        .where((b) =>
            _isRangeIntersecting(block.left, block.right, b.left, b.right));
  }

  Iterable<PlacedBlock> _getBlocksLeft(PlacedBlock block) {
    return blocks
        .where((b) => b != block)
        .where((b) => b.right == block.left - 1)
        .where((b) =>
            _isRangeIntersecting(block.top, block.bottom, b.top, b.bottom));
  }

  Iterable<PlacedBlock> _getBlocksRight(PlacedBlock block) {
    return blocks
        .where((b) => b != block)
        .where((b) => b.left == block.right + 1)
        .where((b) =>
            _isRangeIntersecting(block.top, block.bottom, b.top, b.bottom));
  }

  bool _canFit(PlacedBlock block) {
    return block.top >= 0 &&
        block.left >= 0 &&
        block.bottom < height &&
        block.right < width;
  }

  bool hasWallInDirection(PlacedBlock block, MoveDirection direction) {
    return maxSegmentLengthImpactedInDirection(block, direction, walls) > -1 ||
        maxSegmentLengthImpactedInDirection(block, direction, sharpWalls) > 0;
  }

  bool willBeCutInDirection(PlacedBlock block, MoveDirection direction) {
    return maxSegmentLengthImpactedInDirection(block, direction, sharpWalls) ==
        0;
  }

  List<PlacedBlock> cutBlockInDirection(
      PlacedBlock block, MoveDirection direction) {
    final sharpWalls =
        getSegmentsInDirection(block, direction, this.sharpWalls);
    final newBlocks = <PlacedBlock>[];

    if (direction.isHorizontal) {
      final wallPositions = sharpWalls.map((wall) => wall.start.y).toList();
      final newBlockStarts = [block.top, ...wallPositions]..sort();
      final newBlockEnds = [
        ...wallPositions.map((p) => p - 1).toList(),
        block.bottom
      ]..sort();
      for (var i = 0; i < newBlockStarts.length; i++) {
        final start = newBlockStarts[i];
        final end = newBlockEnds[i];
        final width = block.width;
        final height = end - start + 1;

        newBlocks.add(Block(
          width,
          height,
          isMain: i == 0 && block.isMain,
          hasControl: false,
        ).place(block.position.shifted(direction).x, start));
      }
    } else {
      final wallPositions = sharpWalls.map((wall) => wall.start.x).toList();
      final newBlockStarts = [block.left, ...wallPositions]..sort();
      final newBlockEnds = [
        ...wallPositions.map((p) => p - 1).toList(),
        block.right
      ]..sort();
      for (var i = 0; i < newBlockStarts.length; i++) {
        final start = newBlockStarts[i];
        final end = newBlockEnds[i];
        final width = end - start + 1;
        final height = block.height;

        newBlocks.add(Block(
          width,
          height,
          isMain: i == 0 && block.isMain,
          hasControl: false,
        ).place(start, block.position.shifted(direction).y));
      }
    }
    return newBlocks;
  }

  Iterable<Segment> getSegmentsInDirection(
      PlacedBlock block, MoveDirection direction, Iterable<Segment> segments) {
    switch (direction) {
      case MoveDirection.up:
        return segments.where((s) =>
            s.end.y == block.top &&
            _isRangeIntersecting(
                s.start.x, s.end.x, block.left + 0.5, block.right + 0.5));
      case MoveDirection.down:
        return segments.where((s) =>
            s.start.y == block.bottom + 1 &&
            _isRangeIntersecting(
                s.start.x, s.end.x, block.left + 0.5, block.right + 0.5));
      case MoveDirection.left:
        return segments.where((s) =>
            s.end.x == block.left &&
            _isRangeIntersecting(
                s.start.y, s.end.y, block.top + 0.5, block.bottom + 0.5));

      case MoveDirection.right:
        return segments.where((s) =>
            s.start.x == block.right + 1 &&
            _isRangeIntersecting(
                s.start.y, s.end.y, block.top + 0.5, block.bottom + 0.5));
    }
  }

  int maxSegmentLengthImpactedInDirection(
      PlacedBlock block, MoveDirection direction, Iterable<Segment> segments) {
    switch (direction) {
      case MoveDirection.up:
      case MoveDirection.down:
        return getSegmentsInDirection(block, direction, segments).fold<int>(
            -1, (previousValue, element) => max(previousValue, element.width));
      case MoveDirection.left:
      case MoveDirection.right:
        return getSegmentsInDirection(block, direction, segments).fold<int>(
            -1, (previousValue, element) => max(previousValue, element.height));
    }
  }

  static bool _isRangeIntersecting(num min1, num max1, num min2, num max2) {
    return max(min1, min2) <= min(max1, max2);
  }

  @override
  List<Object?> get props => [
        width,
        height,
        blocks,
        walls,
        sharpWalls,
        controlledBlock,
      ];
}

extension on Position {
  Position shifted(MoveDirection direction) {
    switch (direction) {
      case MoveDirection.up:
        return Position(x, y - 1);
      case MoveDirection.down:
        return Position(x, y + 1);
      case MoveDirection.left:
        return Position(x - 1, y);
      case MoveDirection.right:
        return Position(x + 1, y);
    }
  }
}

extension on PlacedBlock {
  PlacedBlock shifted(MoveDirection direction) {
    switch (direction) {
      case MoveDirection.up:
        return translate(0, -1);
      case MoveDirection.down:
        return translate(0, 1);
      case MoveDirection.left:
        return translate(-1, 0);
      case MoveDirection.right:
        return translate(1, 0);
    }
  }
}
