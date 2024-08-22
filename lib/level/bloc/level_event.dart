part of 'level_bloc.dart';

abstract class LevelEvent {
  const LevelEvent();
}

class LevelStateSet extends LevelEvent {
  const LevelStateSet(this.state);

  final LevelState state;
}

class LevelReset extends LevelEvent {
  const LevelReset();
}

class MoveAttempt extends LevelEvent {
  const MoveAttempt(this.direction);

  final MoveDirection direction;

  Move blocked(PlacedBlock block) {
    return Move._(block, direction, false);
  }

  Move moved(PlacedBlock block) {
    return Move._(block, direction, true);
  }
}

class Move extends MoveAttempt {
  const Move._(this.block, MoveDirection direction, this.didMove)
      : super(direction);

  final PlacedBlock block;
  final bool didMove;
}
