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
    final controlled = block.hasControl;
    final fill = controlled ? boardColors.controlledBlock : boardColors.block;
    final outline = controlled
        ? boardColors.controlledBlockOutline
        : boardColors.blockOutline;
    final highlight = Color.lerp(fill, Colors.white, 0.38)!;
    final shade = Color.lerp(fill, Colors.black, 0.42)!;
    final mid = Color.lerp(fill, shade, 0.2)!;
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
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: controlled ? 10 : 7,
                  offset: const Offset(0, 4),
                ),
                if (controlled)
                  BoxShadow(
                    color: outline.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 0.5,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Body — carved wood / stone slab
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          highlight,
                          fill,
                          mid,
                          shade,
                        ],
                        stops: const [0, 0.28, 0.72, 1],
                      ),
                      border: Border.all(
                        color: Color.lerp(outline, shade, 0.25)!,
                        width: 2.5,
                      ),
                      borderRadius: radius,
                    ),
                  ),
                  // Top bevel shine
                  Positioned(
                    left: 4,
                    right: 4,
                    top: 3,
                    height: max(8.0, min(block.width, block.height) * 8.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.38),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Side rim light
                  Positioned(
                    left: 3,
                    top: 10,
                    bottom: 8,
                    width: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  // Bottom edge depth
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 3,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  // Grain lines (subtle)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BlockGrainPainter(
                        color: shade.withValues(alpha: 0.18),
                        horizontal: block.width >= block.height,
                      ),
                    ),
                  ),
                  // Main exit gem
                  Center(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class _BlockGrainPainter extends CustomPainter {
  _BlockGrainPainter({required this.color, required this.horizontal});

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    if (horizontal) {
      final step = size.height / 5;
      for (var i = 1; i < 5; i++) {
        final y = step * i;
        canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
      }
    } else {
      final step = size.width / 5;
      for (var i = 1; i < 5; i++) {
        final x = step * i;
        canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlockGrainPainter oldDelegate) =>
      color != oldDelegate.color || horizontal != oldDelegate.horizontal;
}
