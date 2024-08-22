import 'package:equatable/equatable.dart';

class Position extends Equatable {
  const Position(this.x, this.y);
  final int x;
  final int y;

  @override
  String toString() {
    return '($x, $y)';
  }

  Position operator +(Position other) {
    return Position(x + other.x, y + other.y);
  }

  Position operator -(Position other) {
    return Position(x - other.x, y - other.y);
  }

  Position copyWith({int? x, int? y}) {
    return Position(x ?? this.x, y ?? this.y);
  }

  @override
  List<Object?> get props => [x, y];
}
