import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class LevelHudState {
  const LevelHudState({
    required this.elapsed,
    this.bestMoves,
    this.minimumMoves,
  });

  final Duration elapsed;
  final int? bestMoves;
  final int? minimumMoves;

  LevelHudState copyWith({
    Duration? elapsed,
    int? bestMoves,
    int? minimumMoves,
    bool clearBest = false,
  }) {
    return LevelHudState(
      elapsed: elapsed ?? this.elapsed,
      bestMoves: clearBest ? bestMoves : (bestMoves ?? this.bestMoves),
      minimumMoves: minimumMoves ?? this.minimumMoves,
    );
  }
}

/// Timer + meta stats for the play HUD (replaces setState ticks).
class LevelHudCubit extends Cubit<LevelHudState> {
  LevelHudCubit()
      : _stopwatch = Stopwatch()..start(),
        super(const LevelHudState(elapsed: Duration.zero)) {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(state.copyWith(elapsed: _stopwatch.elapsed));
    });
  }

  final Stopwatch _stopwatch;
  Timer? _ticker;

  Duration get elapsed => _stopwatch.elapsed;

  void setBestMoves(int? value) => emit(state.copyWith(bestMoves: value));

  void setMinimumMoves(int? value) =>
      emit(state.copyWith(minimumMoves: value));

  void resetTimer() {
    _stopwatch
      ..reset()
      ..start();
    emit(state.copyWith(elapsed: Duration.zero));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _stopwatch.stop();
    return super.close();
  }
}
