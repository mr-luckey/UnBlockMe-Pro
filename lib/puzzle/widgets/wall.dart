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
    return Transform.scale(
      scaleX: (isSharp && segment.width == 0 ? 2 : 1),
      scaleY: (isSharp && segment.height == 0 ? 2 : 1),
      child: AnimatedContainer(
        curve: curve,
        duration: duration,
        decoration: isSharp
            ? ShapeDecoration(
                shape: BeveledRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                color: BoardColor.of(context).wall,
              )
            : BoxDecoration(
                color: BoardColor.of(context).wall,
                borderRadius: BorderRadius.circular(2.0),
              ),
        width: segment.width.toWallSize(),
        height: segment.height.toWallSize(),
      ),
    );
  }
}

class PuzzleExit extends StatelessWidget {
  const PuzzleExit(this.segment, {Key? key}) : super(key: key);

  final Segment segment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: BoardColor.of(context).wall,
          width: 2.0,
        ),
      ),
      width: segment.width.toWallSize(),
      height: segment.height.toWallSize(),
    );
  }
}
