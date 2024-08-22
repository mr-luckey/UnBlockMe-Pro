import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'solution_player_event.dart';
part 'solution_player_state.dart';

class SolutionPlayerBloc
    extends Bloc<SolutionPlayerEvent, SolutionPlayerState> {
  SolutionPlayerBloc(int stepCount) : super(SolutionPlayerState.initial(stepCount)) {
    on<SolutionStepSelected>(_onSolutionStepSelected);
    on<NextSolutionStepSelected>(_onNextSolutionStepSelected);
    on<PreviousSolutionStepSelected>(_onPreviousSolutionStepSelected);
  }

  void _onSolutionStepSelected(
      SolutionStepSelected event, Emitter<SolutionPlayerState> emit) {
    emit(state.withIndex(event.step));
  }

  void _onNextSolutionStepSelected(
      NextSolutionStepSelected event, Emitter<SolutionPlayerState> emit) {
    emit(state.next());
  }

  void _onPreviousSolutionStepSelected(
      PreviousSolutionStepSelected event, Emitter<SolutionPlayerState> emit) {
    emit(state.previous());
  }
}
