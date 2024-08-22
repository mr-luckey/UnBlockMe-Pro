part of 'object_builder_bloc.dart';

class ObjectBuilderState {
  const ObjectBuilderState.initial()
      : _start = null,
        _end = null,
        hoveredPosition = null;
  const ObjectBuilderState(
      {Position? start, Position? end, this.hoveredPosition})
      : _start = start,
        _end = end;

  static const _invalidPosition = Position(-1, -1);

  Position? get start => _start ?? hoveredPosition;
  Position? get end => _end ?? hoveredPosition;
  bool get isObjectPlaced => _start != null && _end != null;

  final Position? _start;
  final Position? _end;
  final Position? hoveredPosition;

  ObjectBuilderState copyWith({
    Position? start = _invalidPosition,
    Position? end = _invalidPosition,
    Position? hoveredPosition = _invalidPosition,
  }) {
    return ObjectBuilderState(
      start: start != _invalidPosition ? start : _start,
      end: end != _invalidPosition ? end : _end,
      hoveredPosition: hoveredPosition != _invalidPosition
          ? hoveredPosition
          : this.hoveredPosition,
    );
  }
}
