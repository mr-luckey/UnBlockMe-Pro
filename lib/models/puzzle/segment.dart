import 'dart:math';

import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:collection/collection.dart';

/// A line segment that can be placed in a [Puzzle].
class Segment {
  const Segment(this.start, this.end);

  Segment.from(
    Position start,
    Position end,
  )   : start = Position(min(start.x, end.x), min(start.y, end.y)),
        end = Position(max(start.x, end.x), max(start.y, end.y));

  Segment.point({
    required int x,
    required int y,
  })  : start = Position(x, y),
        end = Position(x, y);

  Segment.vertical({
    required int x,
    required int start,
    required int end,
  })  : start = Position(x, min(start, end)),
        end = Position(x, max(start, end));

  Segment.horizontal({
    required int y,
    required int start,
    required int end,
  })  : start = Position(min(start, end), y),
        end = Position(max(start, end), y);

  Segment translate(int dx, int dy) => Segment.from(
        start + Position(dx, dy),
        end + Position(dx, dy),
      );

  final Position start;
  final Position end;

  int get width => end.x - start.x;
  int get height => end.y - start.y;
  bool get isVertical => start.x == end.x;
  bool get isHorizontal => start.y == end.y;

  int get cross => isVertical ? start.x : start.y;
  int get mainStart => isVertical ? start.y : start.x;
  int get mainEnd => isVertical ? end.y : end.x;

  Iterable<Segment> subtract(Segment? other) {
    if (other == null) {
      return [this];
    }
    if (isVertical != other.isVertical) {
      return [this];
    } else if (cross != other.cross) {
      return [this];
    }
    if (isVertical) {
      final x = cross;

      final intersection = Segment.vertical(
        x: x,
        start: max(start.y, other.start.y),
        end: min(end.y, other.end.y),
      );

      // Return the vertical segment that is not intersecting with the other segment.
      final start1 = start.y;
      final end1 = intersection.start.y;
      final start2 = intersection.end.y;
      final end2 = end.y;

      return [
        if (end1 > start1) Segment.vertical(x: x, start: start1, end: end1),
        if (end2 > start2) Segment.vertical(x: x, start: start2, end: end2),
      ];
    } else {
      final y = cross;

      final intersection = Segment.horizontal(
        y: y,
        start: max(start.x, other.start.x),
        end: min(end.x, other.end.x),
      );

      // Return the horizontal segment that is not intersecting with the other segment.
      final start1 = start.x;
      final end1 = intersection.start.x;
      final start2 = intersection.end.x;
      final end2 = end.x;

      return [
        if (end1 > start1) Segment.horizontal(y: y, start: start1, end: end1),
        if (end2 > start2) Segment.horizontal(y: y, start: start2, end: end2),
      ];
    }
  }

  Iterable<Segment> subtractAll(Iterable<Segment> others) {
    Iterable<Segment> segments = [this];
    for (final other in others) {
      segments = segments.map((s) => s.subtract(other)).flattened;
    }
    return segments;
  }

  @override
  String toString() {
    return 'Segment($start, $end)';
  }
}
