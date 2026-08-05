import 'dart:math' as math;

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';

class BoardPainter extends CustomPainter {
  BoardPainter(this.context, this.board, this.controlledBlock)
      : boardColors = BoardColor.of(context);

  final LevelState board;
  final BuildContext context;
  final PlacedBlock controlledBlock;
  final BoardColorData boardColors;

  @override
  void paint(Canvas canvas, Size size) {
    final floorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        0,
        0,
        board.width.toBoardSize(),
        board.height.toBoardSize(),
      ),
      const Radius.circular(14),
    );

    final floorDeep = Color.lerp(boardColors.floor, Colors.black, 0.3)!;
    canvas.drawRRect(
      floorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(boardColors.floor, const Color(0xFFC4A882), 0.15)!,
            boardColors.floor,
            floorDeep,
          ],
        ).createShader(floorRect.outerRect),
    );

    // Soft cell hints
    final cellPaint = Paint()
      ..color = boardColors.wall.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = 0; y < board.height; y++) {
      for (var x = 0; x < board.width; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x.toBlockOffset(),
              y.toBlockOffset(),
              kBlockSize,
              kBlockSize,
            ),
            const Radius.circular(6),
          ),
          cellPaint,
        );
      }
    }

    for (final wall in board.walls) {
      final wallRect = Rect.fromLTWH(
        wall.start.x.toWallOffset(),
        wall.start.y.toWallOffset(),
        wall.width.toWallSize(),
        wall.height.toWallSize(),
      );
      final light =
          Color.lerp(boardColors.wall, const Color(0xFFE8C99A), 0.3)!;
      final dark = Color.lerp(boardColors.wall, Colors.black, 0.35)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(wallRect, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(
            colors: [light, boardColors.wall, dark],
          ).createShader(wallRect),
      );
    }

    for (final (index, block) in board.blocks.indexed) {
      final controlled = block == controlledBlock;
      final fill =
          controlled ? boardColors.controlledBlock : boardColors.block;
      final outline = controlled
          ? boardColors.controlledBlockOutline
          : boardColors.blockOutline;

      final blockRect = Rect.fromLTWH(
        block.position.x.toBlockOffset(),
        block.position.y.toBlockOffset(),
        block.width.toBlockSize(),
        block.height.toBlockSize(),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(blockRect, const Radius.circular(10))
            .shift(const Offset(1, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.32),
      );
      paintWoodBlock(
        canvas,
        blockRect,
        fill: fill,
        outline: outline,
        seed: index,
        controlled: controlled,
      );

      if (block.isMain) {
        final gem = controlled
            ? boardColors.controlledBlockOutline
            : const Color(0xFFFFC857);
        final cx = blockRect.center.dx;
        final cy = blockRect.center.dy;
        final r = (math.min(block.width, block.height) * kBlockSize) / 5;
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.lerp(gem, Colors.white, 0.5)!,
                gem,
              ],
            ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
