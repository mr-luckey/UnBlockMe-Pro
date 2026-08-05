import 'dart:math' as math;

import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// How far the rim reaches outside the board rect. The board layout itself is
/// untouched; the rim simply claims a little room around it.
const kBoardFrameOverhang = 15.0;

/// How far the rim reaches into the board rect. The first cell starts at
/// [kWallWidth] + [kBlockGap], so staying well short of that leaves the blocks
/// breathing room instead of pressing them against the wood.
const kBoardFrameInnerReach = 3.0;

/// Total thickness of the rim.
const kBoardFrameThickness = kBoardFrameOverhang + kBoardFrameInnerReach;

/// Keeping the two radii a rim apart makes the ring the same width all the way
/// round, corners included.
const _outerRadius = 26.0;
const _innerRadius = _outerRadius - kBoardFrameThickness;

/// Dark walnut, lit from the top left.
const _woodLit = Color(0xFF7A5230);
const _woodMid = Color(0xFF4E3117);
const _woodDeep = Color(0xFF33200E);
const _woodShadow = Color(0xFF1D1006);
const _woodHighlight = Color(0xFFEFD3A6);
const _woodBlack = Color(0xFF0E0803);

const _exitGold = Color(0xFFFFCE5C);

/// The exit is floored with warm wood rather than left open, so the gold
/// markings always have something to read against.
const _exitBedMid = Color(0xFF63401F);
const _exitBedDeep = Color(0xFF3A2410);

/// An exit segment spans a whole wall run, but only a block's width actually
/// passes through it. Narrowing the carve by this much on each side makes the
/// gap exactly as wide as the block that leaves through it.
const _passageInset = kWallWidth + kBlockGap;

/// A single carved dark-wood rim around the board.
///
/// Everything is painted, so the rim keeps a constant [kBoardFrameThickness]
/// and crisp corners on every board size. Exits are carved straight out of the
/// rim and marked with a lit channel, so the way out is always readable.
class BoardFrame extends StatelessWidget {
  const BoardFrame({
    Key? key,
    required this.boardWidth,
    required this.boardHeight,
    required this.exits,
    required this.child,
  }) : super(key: key);

  final int boardWidth;
  final int boardHeight;
  final List<Segment> exits;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // The rim casts its shadow slightly outside its own box.
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(kBoardFrameOverhang),
          child: child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _BoardFramePainter(
                openings: _openings(),
                tray: BoardColor.of(context).floor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_Opening> _openings() {
    final openings = <_Opening>[];
    for (final exit in exits) {
      if (exit.isVertical && exit.height > 0) {
        final side = exit.start.x == 0
            ? _Side.left
            : exit.start.x == boardWidth
                ? _Side.right
                : null;
        if (side == null) continue;
        final from =
            exit.start.y.toWallOffset() + kBoardFrameOverhang + _passageInset;
        openings.add(
          _Opening(
              side, from, from + exit.height.toWallSize() - 2 * _passageInset),
        );
      } else if (exit.isHorizontal && exit.width > 0) {
        final side = exit.start.y == 0
            ? _Side.top
            : exit.start.y == boardHeight
                ? _Side.bottom
                : null;
        if (side == null) continue;
        final from =
            exit.start.x.toWallOffset() + kBoardFrameOverhang + _passageInset;
        openings.add(
          _Opening(
              side, from, from + exit.width.toWallSize() - 2 * _passageInset),
        );
      }
    }
    return openings;
  }
}

enum _Side { left, top, right, bottom }

/// A stretch of rim that is carved away so a block can leave the board.
@immutable
class _Opening {
  const _Opening(this.side, this.from, this.to);

  final _Side side;

  /// Extent along the edge, in rim coordinates.
  final double from;
  final double to;

  bool get isHorizontalFlow => side == _Side.left || side == _Side.right;

  /// Unit vector pointing the way a block travels as it leaves.
  Offset get outward {
    switch (side) {
      case _Side.left:
        return const Offset(-1, 0);
      case _Side.right:
        return const Offset(1, 0);
      case _Side.top:
        return const Offset(0, -1);
      case _Side.bottom:
        return const Offset(0, 1);
    }
  }

  Alignment get flowStart {
    switch (side) {
      case _Side.left:
        return Alignment.centerRight;
      case _Side.right:
        return Alignment.centerLeft;
      case _Side.top:
        return Alignment.bottomCenter;
      case _Side.bottom:
        return Alignment.topCenter;
    }
  }

  Alignment get flowEnd {
    switch (side) {
      case _Side.left:
        return Alignment.centerLeft;
      case _Side.right:
        return Alignment.centerRight;
      case _Side.top:
        return Alignment.topCenter;
      case _Side.bottom:
        return Alignment.bottomCenter;
    }
  }

  Rect rect(Size size) {
    const t = kBoardFrameThickness;
    switch (side) {
      case _Side.left:
        return Rect.fromLTRB(0, from, t, to);
      case _Side.right:
        return Rect.fromLTRB(size.width - t, from, size.width, to);
      case _Side.top:
        return Rect.fromLTRB(from, 0, to, t);
      case _Side.bottom:
        return Rect.fromLTRB(from, size.height - t, to, size.height);
    }
  }

  /// The carve reaches a hair past the outer face so no sliver of rim is left.
  Rect carveRect(Size size) {
    const bleed = 1.5;
    final r = rect(size);
    switch (side) {
      case _Side.left:
        return Rect.fromLTRB(r.left - bleed, r.top, r.right, r.bottom);
      case _Side.right:
        return Rect.fromLTRB(r.left, r.top, r.right + bleed, r.bottom);
      case _Side.top:
        return Rect.fromLTRB(r.left, r.top - bleed, r.right, r.bottom);
      case _Side.bottom:
        return Rect.fromLTRB(r.left, r.top, r.right, r.bottom + bleed);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _Opening &&
      other.side == side &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(side, from, to);
}

class _BoardFramePainter extends CustomPainter {
  const _BoardFramePainter({required this.openings, required this.tray});

  final List<_Opening> openings;
  final Color tray;

  static const double _t = kBoardFrameThickness;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 3 * _t || size.height < 3 * _t) return;

    final bounds = Offset.zero & size;
    final outer =
        RRect.fromRectAndRadius(bounds, const Radius.circular(_outerRadius));
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTRB(_t, _t, size.width - _t, size.height - _t),
      const Radius.circular(_innerRadius),
    );

    _paintCastShadow(canvas, size, outer);

    canvas
      ..save()
      ..clipPath(_carvedAway(size));
    _paintRim(canvas, size, bounds, outer, inner);
    canvas.restore();

    for (final opening in openings) {
      _paintOpening(canvas, size, opening);
    }
  }

  /// Everything except the exit carvings.
  Path _carvedAway(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTRB(-_t, -_t, size.width + _t, size.height + _t));
    for (final opening in openings) {
      path.addRect(opening.carveRect(size));
    }
    return path;
  }

  void _paintCastShadow(Canvas canvas, Size size, RRect outer) {
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTRB(-40, -40, size.width + 40, size.height + 40))
      ..addRRect(outer);
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        outer.shift(const Offset(0, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..restore();
  }

  void _paintRim(
    Canvas canvas,
    Size size,
    Rect bounds,
    RRect outer,
    RRect inner,
  ) {
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addRRect(outer),
      Path()..addRRect(inner),
    );

    canvas.drawPath(
      ring,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_woodLit, _woodMid, _woodDeep, _woodShadow],
          stops: [0, 0.34, 0.68, 1],
        ).createShader(bounds),
    );

    canvas
      ..save()
      ..clipPath(ring);
    _paintGrain(canvas, size);
    _paintMiterJoints(canvas, size);
    canvas.restore();

    // Rounded-over outer edge: catches the light on the top left, falls away
    // into shadow on the bottom right.
    canvas.drawRRect(
      outer.deflate(1.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _woodHighlight.withValues(alpha: 0.82),
            _woodLit.withValues(alpha: 0.30),
            _woodBlack.withValues(alpha: 0.78),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      outer.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _woodBlack.withValues(alpha: 0.55),
    );

    // Inner edge is lit the opposite way, which reads as a sunken tray.
    canvas.drawRRect(
      inner.inflate(1.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _woodBlack.withValues(alpha: 0.85),
            _woodDeep.withValues(alpha: 0.45),
            _woodHighlight.withValues(alpha: 0.42),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      inner.inflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _woodBlack.withValues(alpha: 0.7),
    );
  }

  /// Grain runs along each rail and stops at the mitred joints, the way four
  /// cut lengths of timber would.
  void _paintGrain(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final top = Path()
      ..addPolygon(
        [Offset.zero, Offset(w, 0), Offset(w - _t, _t), const Offset(_t, _t)],
        true,
      );
    final bottom = Path()
      ..addPolygon(
        [
          Offset(0, h),
          Offset(w, h),
          Offset(w - _t, h - _t),
          Offset(_t, h - _t),
        ],
        true,
      );
    final left = Path()
      ..addPolygon(
        [Offset.zero, Offset(0, h), Offset(_t, h - _t), const Offset(_t, _t)],
        true,
      );
    final right = Path()
      ..addPolygon(
        [
          Offset(w, 0),
          Offset(w, h),
          Offset(w - _t, h - _t),
          Offset(w - _t, _t),
        ],
        true,
      );

    _paintRailGrain(canvas, top, horizontal: true, span: w, base: 0, sign: 1);
    _paintRailGrain(canvas, bottom,
        horizontal: true, span: w, base: h, sign: -1);
    _paintRailGrain(canvas, left, horizontal: false, span: h, base: 0, sign: 1);
    _paintRailGrain(canvas, right,
        horizontal: false, span: h, base: w, sign: -1);
  }

  void _paintRailGrain(
    Canvas canvas,
    Path rail, {
    required bool horizontal,
    required double span,
    required double base,
    required double sign,
  }) {
    canvas
      ..save()
      ..clipPath(rail);

    // Fixed seed so the grain never shimmers between frames.
    final random = math.Random(horizontal ? 17 : 43);
    for (var i = 0; i < 5; i++) {
      final depth = base + sign * _t * (0.13 + i * 0.18);
      final lit = i.isOdd;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lit ? 1.2 : 0.9
        ..color = lit
            ? _woodHighlight.withValues(alpha: 0.10)
            : _woodBlack.withValues(alpha: 0.22);

      final wobble = 0.6 + random.nextDouble() * 1.0;
      final phase = random.nextDouble() * math.pi * 2;
      final path = Path();
      const steps = 16;
      for (var s = 0; s <= steps; s++) {
        final along = span * s / steps;
        final drift = math.sin(phase + s * 0.85) * wobble;
        final point = horizontal
            ? Offset(along, depth + drift)
            : Offset(depth + drift, along);
        if (s == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  void _paintMiterJoints(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _woodBlack.withValues(alpha: 0.45);
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _woodHighlight.withValues(alpha: 0.12);

    void joint(Offset corner, Offset toward) {
      canvas
        ..drawLine(corner, toward, seam)
        ..drawLine(
          corner + const Offset(0, 1.6),
          toward + const Offset(0, 1.6),
          glint,
        );
    }

    joint(Offset.zero, const Offset(_t, _t));
    joint(Offset(w, 0), Offset(w - _t, _t));
    joint(Offset(0, h), Offset(_t, h - _t));
    joint(Offset(w, h), Offset(w - _t, h - _t));
  }

  void _paintOpening(Canvas canvas, Size size, _Opening opening) {
    final rect = opening.rect(size);
    if (rect.isEmpty) return;

    canvas
      ..save()
      ..clipRect(rect);

    // The carve is floored with warm wood rather than left open, so the gold
    // markings stay legible. It falls back into shadow at the mouth, which is
    // what keeps the channel reading as cut into the rim rather than stuck on.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: opening.flowStart,
          end: opening.flowEnd,
          colors: [
            Color.lerp(tray, _exitBedDeep, 0.55)!,
            _exitBedMid,
            Color.lerp(_exitBedMid, _exitBedDeep, 0.6)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    _paintChannelWalls(canvas, rect, opening);
    _paintExitArrows(canvas, rect, opening);

    canvas.restore();
  }

  /// The two cut faces of the rim on either side of the channel, plus the gold
  /// threading that marks the way out.
  void _paintChannelWalls(Canvas canvas, Rect rect, _Opening opening) {
    const wall = 3.4;
    final Rect shaded;
    final Rect lit;
    if (opening.isHorizontalFlow) {
      shaded = Rect.fromLTWH(rect.left, rect.top, rect.width, wall);
      lit = Rect.fromLTWH(rect.left, rect.bottom - wall, rect.width, wall);
    } else {
      shaded = Rect.fromLTWH(rect.left, rect.top, wall, rect.height);
      lit = Rect.fromLTWH(rect.right - wall, rect.top, wall, rect.height);
    }

    // Cut wood runs the whole depth of the carve, only easing off a little as
    // it reaches the mouth.
    Shader face(Rect r, Color color, double alpha) => LinearGradient(
          begin: opening.flowStart,
          end: opening.flowEnd,
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.78),
            color.withValues(alpha: alpha * 0.5),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(r);

    // Gold brightens towards the mouth so the eye is pulled outwards.
    Shader thread(Rect r) => LinearGradient(
          begin: opening.flowStart,
          end: opening.flowEnd,
          colors: [
            _exitGold.withValues(alpha: 0.25),
            _exitGold.withValues(alpha: 0.5),
            _exitGold.withValues(alpha: 0.8),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(r);

    canvas
      ..drawRect(shaded, Paint()..shader = face(shaded, _woodBlack, 0.9))
      ..drawRect(lit, Paint()..shader = face(lit, _woodHighlight, 0.34));

    final rail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    if (opening.isHorizontalFlow) {
      rail.shader = thread(shaded);
      canvas.drawLine(
        Offset(rect.left, rect.top + 0.9),
        Offset(rect.right, rect.top + 0.9),
        rail,
      );
      rail.shader = thread(lit);
      canvas.drawLine(
        Offset(rect.left, rect.bottom - 0.9),
        Offset(rect.right, rect.bottom - 0.9),
        rail,
      );
    } else {
      rail.shader = thread(shaded);
      canvas.drawLine(
        Offset(rect.left + 0.9, rect.top),
        Offset(rect.left + 0.9, rect.bottom),
        rail,
      );
      rail.shader = thread(lit);
      canvas.drawLine(
        Offset(rect.right - 0.9, rect.top),
        Offset(rect.right - 0.9, rect.bottom),
        rail,
      );
    }

    // The rim overhangs its own carve, so the mouth sits in shadow. Without
    // this the channel reads as a tab stuck onto the frame rather than a hole
    // cut through it.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: opening.flowStart,
          end: opening.flowEnd,
          colors: [
            Colors.transparent,
            _woodBlack.withValues(alpha: 0.45),
          ],
          stops: const [0.45, 1],
        ).createShader(rect),
    );
  }

  void _paintExitArrows(Canvas canvas, Rect rect, _Opening opening) {
    final depth = opening.isHorizontalFlow ? rect.width : rect.height;
    final breadth = opening.isHorizontalFlow ? rect.height : rect.width;
    final reach = math.min(depth * 0.36, breadth * 0.26);
    if (reach < 3) return;

    final direction = opening.outward;
    final across = Offset(-direction.dy, direction.dx);
    // Pull the pair back so the leading chevron stops short of the mouth.
    final centre = rect.center - direction * (depth * 0.02 + reach * 0.625);

    for (var i = 0; i < 2; i++) {
      final lead = centre + direction * (i * reach * 1.15);
      final tip = lead + direction * (reach * 0.55);
      final tail = lead - direction * (reach * 0.45);
      final chevron = Path()
        ..moveTo(tail.dx + across.dx * reach, tail.dy + across.dy * reach)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tail.dx - across.dx * reach, tail.dy - across.dy * reach);

      final opacity = i == 0 ? 0.95 : 0.45;
      canvas
        ..drawPath(
          chevron,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = reach * 0.85
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _exitGold.withValues(alpha: opacity * 0.28)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, reach * 0.45),
        )
        ..drawPath(
          chevron,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2.2, reach * 0.42)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _exitGold.withValues(alpha: opacity),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardFramePainter oldDelegate) =>
      oldDelegate.tray != tray || !listEquals(oldDelegate.openings, openings);
}
