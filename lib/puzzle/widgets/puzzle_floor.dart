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
    final boardW = width.toBoardSize();
    final boardH = height.toBoardSize();
    final floor = BoardColor.of(context).floor;
    final wall = BoardColor.of(context).wall;
    final deep = Color.lerp(floor, Colors.black, 0.35)!;
    final lift = Color.lerp(floor, const Color(0xFFC4A882), 0.18)!;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [lift, floor, deep],
        stops: const [0, 0.45, 1],
      ),
      border: Border.all(
        color: Color.lerp(wall, Colors.black, 0.25)!,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 3),
          spreadRadius: -1,
        ),
      ],
    );

    final content = Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _FloorGridPainter(
              cols: width,
              rows: height,
              line: wall.withValues(alpha: 0.22),
              cell: Color.lerp(floor, Colors.black, 0.08)!
                  .withValues(alpha: 0.35),
            ),
          ),
        ),
        // Soft vignette so blocks read clearly
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.22),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
        ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );

    if (isContainer) {
      return Container(
        width: boardW,
        height: boardH,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }
    return Ink(
      width: boardW,
      height: boardH,
      decoration: decoration,
      child: content,
    );
  }
}

class _FloorGridPainter extends CustomPainter {
  _FloorGridPainter({
    required this.cols,
    required this.rows,
    required this.line,
    required this.cell,
  });

  final int cols;
  final int rows;
  final Color line;
  final Color cell;

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint()..color = cell;
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke;

    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final left = x.toBlockOffset();
        final top = y.toBlockOffset();
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, kBlockSize, kBlockSize),
          const Radius.circular(8),
        );
        // Checker tint for depth
        if ((x + y).isEven) {
          canvas.drawRRect(rect, cellPaint);
        }
        canvas.drawRRect(rect, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FloorGridPainter oldDelegate) =>
      cols != oldDelegate.cols ||
      rows != oldDelegate.rows ||
      line != oldDelegate.line ||
      cell != oldDelegate.cell;
}
