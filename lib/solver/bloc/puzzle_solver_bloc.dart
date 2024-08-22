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

  void _onSolutionViewed(
      SolutionViewed event, Emitter<PuzzleSolverState> emit) async {
    final requestedState = state.copyWithSolutionRequested();
    emit(requestedState);

    final viewedState = await requestedState
        .copyWithSolutionViewed(viewed: true)
        .copyWithSolutionFor(levelBloc.initialState.puzzle);

    final isInitialState =
        levelBloc.state.puzzle == levelBloc.initialState.puzzle;

    if (!isInitialState) {
      levelBloc.add(const LevelReset());
      await Future.delayed(kSlideDuration);
    }
    emit(viewedState);
  }

  void _onSolutionPlayed(
      SolutionPlayed event, Emitter<PuzzleSolverState> emit) async {
    final requestedState = state.copyWithSolutionRequested();
    emit(requestedState);

    final newState =
        await requestedState.copyWithSolutionFor(levelBloc.initialState.puzzle);
    final moves = newState.solution!;

    emit(newState);

    Future<void> runSolution() async {
      final isInitialState =
          levelBloc.state.puzzle == levelBloc.initialState.puzzle;

      if (!isInitialState) {
        levelBloc.add(const LevelReset());
        await Future.delayed(kSlideDuration * 1.5);
      }

      for (var move in moves) {
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
