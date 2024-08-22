part of 'level_bloc.dart';

class LevelState {
  const LevelState.initial(this.puzzle)
      : latestMove = null,
        isCompleted = false;

  const LevelState(
    this.puzzle, {
    required this.latestMove,
    required this.isCompleted,
  });

  final PuzzleState puzzle;
  final Move? latestMove;
  final bool isCompleted;

  int get width => puzzle.width;
  int get height => puzzle.height;
  List<PlacedBlock> get blocks => puzzle.blocks;
  List<Segment> get walls => puzzle.walls;
  List<Segment> get sharpWalls => puzzle.sharpWalls;
  PlacedBlock get controlledBlock => puzzle.controlledBlock;

  List<LevelState> withMoveAttempt(MoveAttempt move) {
    final movedBlock = puzzle.controlledBlock;
    final newPuzzle = puzzle.withMoveAttempt(move);

    final isMoveBlocked = puzzle == newPuzzle;
    final isMoveBlockedByWall =
        puzzle.hasWallInDirection(movedBlock, move.direction);
    final wouldBeCut = puzzle.willBeCutInDirection(movedBlock, move.direction);
    final cannotBeCut = wouldBeCut &&
        puzzle.getBlocksAhead(movedBlock, move.direction).isNotEmpty;
    final isMoveFailedControlShift = isMoveBlocked && !isMoveBlockedByWall;
    final wasCut = puzzle.blocks.length != newPuzzle.blocks.length;
    final isMoveBlockedByControlShift =
        newPuzzle.controlledBlock != puzzle.controlledBlock && !wasCut;

    if (isMoveBlockedByWall || cannotBeCut) {
      return [this];
    } else if (isMoveBlockedByControlShift || isMoveFailedControlShift) {
      return [
        LevelState(
          newPuzzle,
          isCompleted: newPuzzle.isCompleted,
          latestMove: move.blocked(movedBlock),
        )
      ];
    } else {
      final intermediateState =
          puzzle.getIntermediateStateWithMoveAttempt(move);
      return [
        if (intermediateState != null)
          LevelState(
            intermediateState,
            isCompleted: intermediateState.isCompleted,
            latestMove: move.moved(
                movedBlock), // moved specified to prevent blocked animation
          ),
        LevelState(
          newPuzzle,
          isCompleted: newPuzzle.isCompleted,
          latestMove: move.moved(movedBlock),
        )
      ];
    }
  }

  /// Convert the puzzle to a string representation parseable by the level reader.
  String toMapString() {
    return stateToMapString(this);
  }
}
