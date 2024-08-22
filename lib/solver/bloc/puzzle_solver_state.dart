part of 'puzzle_solver_bloc.dart';

class PuzzleSolverState {
  const PuzzleSolverState.initial()
      : solution = null,
        hasSolutionResult = false,
        isSolutionVisible = false,
        isSolutionRequested = false,
        solutionPlayback = null;
  const PuzzleSolverState({
    required this.solution,
    required this.hasSolutionResult,
    required this.isSolutionVisible,
    required this.isSolutionRequested,
    required this.solutionPlayback,
  });

  final List<MoveDirection>? solution;
  final bool hasSolutionResult;
  final bool isSolutionVisible;
  final bool isSolutionRequested;
  final CancelableOperation? solutionPlayback;

  Future<PuzzleSolverState> copyWithSolutionFor(PuzzleState puzzleState) async {
    if (hasSolutionResult) {
      return this;
    }

    return PuzzleSolverState(
        solution: await solve(puzzleState),
        hasSolutionResult: true,
        isSolutionRequested: isSolutionRequested,
        isSolutionVisible: isSolutionVisible,
        solutionPlayback: null);
  }

  PuzzleSolverState copyWithSolutionPlaying(
      CancelableOperation solutionPlayback) {
    return PuzzleSolverState(
        solution: solution,
        hasSolutionResult: hasSolutionResult,
        isSolutionRequested: isSolutionRequested,
        isSolutionVisible: isSolutionVisible,
        solutionPlayback: solutionPlayback);
  }

  PuzzleSolverState copyWithSolutionViewed({required bool viewed}) {
    return PuzzleSolverState(
        solution: solution,
        hasSolutionResult: hasSolutionResult,
        isSolutionRequested: isSolutionRequested,
        isSolutionVisible: viewed,
        solutionPlayback: solutionPlayback);
  }

  PuzzleSolverState copyWithSolutionRequested() {
    return PuzzleSolverState(
        solution: solution,
        hasSolutionResult: hasSolutionResult,
        isSolutionRequested: true,
        isSolutionVisible: isSolutionVisible,
        solutionPlayback: solutionPlayback);
  }
}
