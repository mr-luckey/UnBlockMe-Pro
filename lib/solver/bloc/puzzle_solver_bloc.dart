import 'package:async/async.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/solver/solver.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'puzzle_solver_event.dart';
part 'puzzle_solver_state.dart';

class PuzzleSolverBloc extends Bloc<PuzzleSolverEvent, PuzzleSolverState> {
  PuzzleSolverBloc(this.levelBloc) : super(const PuzzleSolverState.initial()) {
    on<SolutionViewed>(_onSolutionViewed);
    on<SolutionPlayed>(_onSolutionPlayed);
    on<SolutionHidden>(_onSolutionHidden);
  }

  final LevelBloc levelBloc;

  /// HINT: apply only the next correct move on the live board.
  /// (No SolutionPage — avoids Hero crash with the play-screen board.)
  void _onSolutionViewed(
      SolutionViewed event, Emitter<PuzzleSolverState> emit) async {
    if (levelBloc.state.isCompleted) return;

    await state.solutionPlayback?.cancel();

    emit(state.copyWithSolutionRequested());

    final moves = await solve(levelBloc.state.puzzle);
    if (isClosed) return;

    emit(
      PuzzleSolverState(
        solution: moves,
        hasSolutionResult: true,
        isSolutionRequested: false,
        isSolutionVisible: false,
        solutionPlayback: null,
      ),
    );

    if (moves != null && moves.isNotEmpty && !levelBloc.state.isCompleted) {
      levelBloc.add(MoveAttempt(moves.first));
    }
  }

  /// SOLVE: reset to start (if needed) and animate the full solution on-board.
  void _onSolutionPlayed(
      SolutionPlayed event, Emitter<PuzzleSolverState> emit) async {
    if (levelBloc.state.isCompleted) return;

    await state.solutionPlayback?.cancel();

    final requestedState = state.copyWithSolutionRequested();
    emit(requestedState);

    // Always re-solve from the *initial* puzzle (hint may have cached a
    // mid-game partial path).
    final moves = await solve(levelBloc.initialState.puzzle);
    if (isClosed) return;

    final newState = PuzzleSolverState(
      solution: moves,
      hasSolutionResult: true,
      isSolutionRequested: false,
      isSolutionVisible: false,
      solutionPlayback: null,
    );
    emit(newState);

    if (moves == null || moves.isEmpty) return;

    Future<void> runSolution() async {
      final isInitialState =
          levelBloc.state.puzzle == levelBloc.initialState.puzzle;

      if (!isInitialState) {
        levelBloc.add(const LevelReset());
        await Future.delayed(kSlideDuration * 1.5);
      }

      for (final move in moves) {
        if (levelBloc.isClosed || levelBloc.state.isCompleted) break;
        levelBloc.add(MoveAttempt(move));
        await Future.delayed(kSlideDuration * 1.5);
      }
    }

    final solutionPlayback = CancelableOperation.fromFuture(runSolution());
    emit(newState.copyWithSolutionPlaying(solutionPlayback));
  }

  void _onSolutionHidden(
      SolutionHidden event, Emitter<PuzzleSolverState> emit) {
    emit(state.copyWithSolutionViewed(viewed: false));
  }

  @override
  Future<void> close() async {
    await state.solutionPlayback?.cancel();
    return super.close();
  }
}
