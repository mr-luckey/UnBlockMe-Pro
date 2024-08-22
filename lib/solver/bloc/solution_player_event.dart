part of 'solution_player_bloc.dart';

abstract class SolutionPlayerEvent {
  const SolutionPlayerEvent();
}

class SolutionStepSelected extends SolutionPlayerEvent {
  const SolutionStepSelected(this.step);

  final int step;
}

class NextSolutionStepSelected extends SolutionPlayerEvent {
  const NextSolutionStepSelected();
}

class PreviousSolutionStepSelected extends SolutionPlayerEvent {
  const PreviousSolutionStepSelected();
}
