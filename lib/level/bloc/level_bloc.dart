import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'level_event.dart';
part 'level_state.dart';

class LevelBloc extends Bloc<LevelEvent, LevelState> {
  LevelBloc(this.initialState) : super(initialState) {
    on<MoveAttempt>(_onMove);
    on<LevelReset>(_onReset);
    on<LevelStateSet>(_onLevelStateSet);
  }

  final LevelState initialState;

  void _onMove(MoveAttempt event, Emitter<LevelState> emit) async {
    if (!state.isCompleted) {
      final newStates = state.withMoveAttempt(event);
      for (var state in newStates) {
        emit(state);
        await WidgetsBinding.instance?.endOfFrame;
      }
    }
  }

  void _onReset(LevelReset event, Emitter<LevelState> emit) {
    emit(initialState);
  }

  void _onLevelStateSet(LevelStateSet event, Emitter<LevelState> emit) {
    emit(event.state);
  }
}
