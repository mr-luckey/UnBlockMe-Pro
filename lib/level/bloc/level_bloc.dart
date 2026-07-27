import 'package:blocked/audio/game_feel.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'level_event.dart';
part 'level_state.dart';

class LevelBloc extends Bloc<LevelEvent, LevelState> {
  LevelBloc(
    this.initialState, {
    /// Decorative / background puzzles must stay silent.
    this.enableFeel = true,
  }) : super(initialState) {
    on<MoveAttempt>(_onMove);
    on<LevelReset>(_onReset);
    on<LevelUndo>(_onUndo);
    on<LevelStateSet>(_onLevelStateSet);
  }

  final LevelState initialState;
  final bool enableFeel;
  final List<LevelState> _history = [];

  bool get canUndo => _history.isNotEmpty;

  void _onMove(MoveAttempt event, Emitter<LevelState> emit) async {
    if (!state.isCompleted) {
      final before = state;
      final newStates = state.withMoveAttempt(event);
      if (newStates.isEmpty) return;

      // Only real gameplay levels play haptic/SFX — never the looping
      // BackgroundPuzzleController LevelBloc.
      if (enableFeel) {
        final resultMove = newStates.last.latestMove;
        if (resultMove != null) {
          if (resultMove.didMove) {
            GameFeel.instance.blockSlide();
          } else {
            GameFeel.instance.blockHit();
          }
        }
      }

      final changed = newStates.length > 1 ||
          newStates.first.puzzle != before.puzzle ||
          newStates.first.moves != before.moves ||
          newStates.first.latestMove != before.latestMove;
      if (changed) {
        _history.add(before);
      }
      for (final next in newStates) {
        emit(next);
        await WidgetsBinding.instance.endOfFrame;
      }
    }
  }

  void _onReset(LevelReset event, Emitter<LevelState> emit) {
    _history.clear();
    emit(initialState);
  }

  void _onUndo(LevelUndo event, Emitter<LevelState> emit) {
    if (_history.isEmpty || state.isCompleted) return;
    emit(_history.removeLast());
  }

  void _onLevelStateSet(LevelStateSet event, Emitter<LevelState> emit) {
    emit(event.state);
  }
}
