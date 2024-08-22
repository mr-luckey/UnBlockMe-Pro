import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';

class PuzzleFloor extends StatelessWidget {
  const PuzzleFloor.container({
    Key? key,
    required this.width,
    required this.height,
    this.child,
  })  : isContainer = true,
        super(key: key);
  const PuzzleFloor.material({
    Key? key,
    required this.width,
    required this.height,
    this.child,
  })  : isContainer = false,
        super(key: key);

  final int width;
  final int height;
  final Widget? child;
  final bool isContainer;

  @override
  Widget build(BuildContext context) {
    if (isContainer) {
      return Container(
        decoration: BoxDecoration(
          color: BoardColor.of(context).floor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        width: width.toBoardSize(),
        height: height.toBoardSize(),
        child: child,
      );
    } else {
      return Ink(
        decoration: BoxDecoration(
          color: BoardColor.of(context).floor,
          borderRadius: BorderRadius.circular(8.0),
        ),
        width: width.toBoardSize(),
        height: height.toBoardSize(),
        child: child,
      );
    }
  }
}
