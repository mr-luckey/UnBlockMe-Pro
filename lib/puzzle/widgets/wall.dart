import 'package:blocked/models/puzzle/puzzle.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';

class PuzzleWall extends StatelessWidget {
  const PuzzleWall(
    this.segment, {
    Key? key,
    required this.isSharp,
    this.curve = Curves.linear,
    this.duration = const Duration(milliseconds: 0),
  }) : super(key: key);

  final bool isSharp;
  final Segment segment;
  final Curve curve;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final wall = BoardColor.of(context).wall;
    final light = Color.lerp(wall, const Color(0xFFE8C99A), 0.35)!;
    final dark = Color.lerp(wall, Colors.black, 0.4)!;
    final horizontal = segment.width >= segment.height;

    return Transform.scale(
      scaleX: (isSharp && segment.width == 0 ? 2 : 1),
      scaleY: (isSharp && segment.height == 0 ? 2 : 1),
      child: AnimatedContainer(
        curve: curve,
        duration: duration,
        width: segment.width.toWallSize(),
        height: segment.height.toWallSize(),
        decoration: isSharp
            ? ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [light, wall, dark],
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  begin: horizontal ? Alignment.topCenter : Alignment.centerLeft,
                  end: horizontal
                      ? Alignment.bottomCenter
                      : Alignment.centerRight,
                  colors: [light, wall, dark],
                  stops: const [0, 0.45, 1],
                ),
                border: Border.all(
                  color: dark.withValues(alpha: 0.7),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
      ),
    );
  }
}

class PuzzleExit extends StatelessWidget {
  const PuzzleExit(this.segment, {Key? key}) : super(key: key);

  final Segment segment;

  @override
  Widget build(BuildContext context) {
    final outline = BoardColor.of(context).controlledBlockOutline;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: outline.withValues(alpha: 0.85),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: outline.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      width: segment.width.toWallSize(),
      height: segment.height.toWallSize(),
    );
  }
}
