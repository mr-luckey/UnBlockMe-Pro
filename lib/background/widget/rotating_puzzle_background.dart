import 'package:blocked/background/widget/background_puzzle_controller.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';

class RotatingPuzzleBackground extends StatelessWidget {
  const RotatingPuzzleBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _controller = BackgroundRotationController.of(context);
    return IgnorePointer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SizedBox.expand(
            child: Opacity(
              opacity: 0.1,
              child: RotationTransition(
                turns: _controller.drive(Tween(begin: 1.0, end: 0.0)),
                child: Transform.scale(
                  scale: 0.8,
                  child: const Puzzle(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
