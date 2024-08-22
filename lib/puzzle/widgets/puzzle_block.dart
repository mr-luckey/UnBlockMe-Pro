import 'dart:math';

import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';

const _defaultDuration = Duration(milliseconds: 225); // kSlideDuration * 1.5
const _mainCircleAnimationDuration = Duration(milliseconds: 250);

class PuzzleBlock extends StatelessWidget {
  const PuzzleBlock(
    this.block, {
    Key? key,
    this.curve = const Interval(0.5, 1),
    this.duration = _defaultDuration,
  }) : super(key: key);

  final Block block;
  final Curve curve;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final boardColors = BoardColor.of(context);
    return RepaintBoundary(
      child: Material(
        elevation: 8.0,
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(2.0),
        child: SizedBox(
          width: block.width.toBlockSize(),
          height: block.height.toBlockSize(),
          child: Align(
            alignment: Alignment.topLeft,
            child: AnimatedContainer(
              // Set constraints so that a split block will
              // animate smoothly back to its original size upon reset.

              // The box constraints will cause the block to animate
              // when expanding, but instantly change size when shrinking.
              constraints: BoxConstraints(
                maxWidth: block.width.toBlockSize(),
                maxHeight: block.height.toBlockSize(),
              ),
              curve: curve,
              decoration: BoxDecoration(
                color: block.hasControl
                    ? boardColors.controlledBlock
                    : boardColors.block,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: block.hasControl
                      ? boardColors.controlledBlockOutline
                      : boardColors.blockOutline,
                  width: 4.0,
                ),
              ),
              duration: duration,
              alignment: Alignment.center,
              child: AnimatedOpacity(
                opacity: (block.isMain ? 1 : 0),
                duration: _mainCircleAnimationDuration,
                child: AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: curve,
                  switchOutCurve: curve.flipped,
                  child: AnimatedContainer(
                    key: ValueKey(block.hasControl),
                    duration: _mainCircleAnimationDuration,
                    curve: Curves.easeOutQuad,
                    width: (block.isMain ? 1 : 0) *
                        min(block.width, block.height) *
                        kBlockSize /
                        2,
                    height: (block.isMain ? 1 : 0) *
                        min(block.width, block.height) *
                        kBlockSize /
                        2,
                    child: FittedBox(
                      child: Icon(
                        Icons.circle_outlined,
                        color: block.hasControl
                            ? boardColors.controlledBlockOutline
                            : boardColors.blockOutline,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
