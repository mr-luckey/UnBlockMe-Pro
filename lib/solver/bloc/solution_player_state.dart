part of 'solution_player_bloc.dart';

class SolutionPlayerState extends Equatable {
  const SolutionPlayerState.initial(this.stepCount) : index = 0;
  const SolutionPlayerState(this.index, this.stepCount);

  final int index;
  final int stepCount;

  SolutionPlayerState previous() =>
      SolutionPlayerState(max(0, index - 1), stepCount);
  SolutionPlayerState next() =>
      SolutionPlayerState(min(stepCount - 1, index + 1), stepCount);
  SolutionPlayerState withIndex(int index) =>
      SolutionPlayerState(index, stepCount);

  @override
  List<Object?> get props => [index, stepCount];
}
