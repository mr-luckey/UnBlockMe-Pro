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
    // Floor
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                0, 0, board.width.toBoardSize(), board.height.toBoardSize()),
            const Radius.circular(2)),
        Paint()..color = boardColors.floor);

    for (var wall in board.walls) {
      final wallPaint = Paint()..color = boardColors.wall;
      final wallRect = Rect.fromLTWH(
          wall.start.x.toWallOffset(),
          wall.start.y.toWallOffset(),
          wall.width.toWallSize(),
          wall.height.toWallSize());
      canvas.drawRRect(
          RRect.fromRectAndRadius(wallRect, const Radius.circular(2)),
          wallPaint);
    }

    /// TODO: Draw sharp walls

    for (var block in board.blocks) {
      final blockPaint = Paint()
        ..color = block == controlledBlock
            ? boardColors.controlledBlock
            : boardColors.block
        ..style = PaintingStyle.fill;
      final outlinePaint = Paint()
        ..color = block == controlledBlock
            ? boardColors.controlledBlockOutline
            : boardColors.blockOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      final blockRect = Rect.fromLTWH(
          block.position.x.toBlockOffset(),
          block.position.y.toBlockOffset(),
          block.width.toBlockSize(),
          block.height.toBlockSize());
      canvas.drawRRect(
          RRect.fromRectAndRadius(blockRect, const Radius.circular(2)),
          blockPaint);

      canvas.drawRRect(
          RRect.fromRectAndRadius(blockRect, const Radius.circular(2)),
          outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
