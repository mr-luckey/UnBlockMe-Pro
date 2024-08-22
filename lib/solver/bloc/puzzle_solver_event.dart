part of 'puzzle_solver_bloc.dart';

abstract class PuzzleSolverEvent {
  const PuzzleSolverEvent();
}

class SolutionViewed extends PuzzleSolverEvent {}

class SolutionPlayed extends PuzzleSolverEvent {}

class SolutionHidden extends PuzzleSolverEvent {}
