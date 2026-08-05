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
    this.grainSeed = 0,
    this.curve = const Interval(0.5, 1),
    this.duration = _defaultDuration,
  }) : super(key: key);

  final Block block;

  /// Fixes this piece's grain pattern. Anything stable for the lifetime of the
  /// block works; the board passes its index so the grain does not crawl while
  /// the piece slides around.
  final int grainSeed;
  final Curve curve;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final boardColors = BoardColor.of(context);
    final controlled = block.hasControl;
    final fill = controlled ? boardColors.controlledBlock : boardColors.block;
    final outline = controlled
        ? boardColors.controlledBlockOutline
        : boardColors.blockOutline;
    final gem = controlled
        ? boardColors.controlledBlockOutline
        : const Color(0xFFFFC857);

    final radius = BorderRadius.circular(12);

    return RepaintBoundary(
      child: SizedBox(
        width: block.width.toBlockSize(),
        height: block.height.toBlockSize(),
        child: Align(
          alignment: Alignment.topLeft,
          child: AnimatedContainer(
            constraints: BoxConstraints(
              maxWidth: block.width.toBlockSize(),
              maxHeight: block.height.toBlockSize(),
            ),
            curve: curve,
            duration: duration,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: controlled ? 11 : 8,
                  offset: const Offset(2, 5),
                  spreadRadius: -1,
                ),
                if (controlled)
                  BoxShadow(
                    color: outline.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 0.5,
                  ),
              ],
            ),
            child: CustomPaint(
              painter: _WoodBlockPainter(
                fill: fill,
                outline: outline,
                controlled: controlled,
                seed: grainSeed,
                radius: radius.topLeft.x,
              ),
              child: Center(
                child: AnimatedOpacity(
                  opacity: block.isMain ? 1 : 0,
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
                          2.15,
                      height: (block.isMain ? 1 : 0) *
                          min(block.width, block.height) *
                          kBlockSize /
                          2.15,
                      child: _MainGem(color: gem, glow: outline),
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

class _WoodBlockPainter extends CustomPainter {
  const _WoodBlockPainter({
    required this.fill,
    required this.outline,
    required this.controlled,
    required this.seed,
    required this.radius,
  });

  final Color fill;
  final Color outline;
  final bool controlled;
  final int seed;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    paintWoodBlock(
      canvas,
      Offset.zero & size,
      fill: fill,
      outline: outline,
      seed: seed,
      radius: radius,
      controlled: controlled,
    );
  }

  @override
  bool shouldRepaint(covariant _WoodBlockPainter oldDelegate) =>
      fill != oldDelegate.fill ||
      outline != oldDelegate.outline ||
      controlled != oldDelegate.controlled ||
      seed != oldDelegate.seed ||
      radius != oldDelegate.radius;
}

class _MainGem extends StatelessWidget {
  const _MainGem({required this.color, required this.glow});

  final Color color;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.55),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          gradient: RadialGradient(
            colors: [
              Color.lerp(color, Colors.white, 0.55)!,
              color,
              Color.lerp(color, Colors.black, 0.25)!,
            ],
            stops: const [0.15, 0.55, 1],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.north_east_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.95),
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
