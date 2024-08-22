import 'package:blocked/resizable/resizable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension on BoxSide {
  bool get isVertical => this == BoxSide.top || this == BoxSide.bottom;
  bool get isHorizontal => this == BoxSide.left || this == BoxSide.right;

  MouseCursor toResizeCursor() {
    if (isVertical) {
      return SystemMouseCursors.resizeUpDown;
    } else if (isHorizontal) {
      return SystemMouseCursors.resizeLeftRight;
    } else {
      throw Error();
    }
  }
}

extension on BoxCorner {
  MouseCursor toResizeCursor() {
    if (this == BoxCorner.topLeft) {
      return SystemMouseCursors.resizeUpLeft;
    } else if (this == BoxCorner.topRight) {
      return SystemMouseCursors.resizeUpRight;
    } else if (this == BoxCorner.bottomLeft) {
      return SystemMouseCursors.resizeDownLeft;
    } else if (this == BoxCorner.bottomRight) {
      return SystemMouseCursors.resizeDownRight;
    } else {
      throw Error();
    }
  }
}

class PanHandle extends StatelessWidget {
  const PanHandle({Key? key, this.onTap}) : super(key: key);

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          context.read<ResizableBloc>().add(Pan(
                delta: details.delta,
              ));
        },
        onPanEnd: (details) {
          context.read<ResizableBloc>().add(const PanEnd());
        },
        onTap: onTap,
      ),
    );
  }
}

class DragHandle extends StatelessWidget {
  const DragHandle.side(this.side, {required this.size, Key? key})
      : corner = null,
        super(key: key);
  const DragHandle.corner(this.corner, {required this.size, Key? key})
      : side = null,
        super(key: key);

  final BoxSide? side;
  final BoxCorner? corner;
  final double size;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: side?.toResizeCursor() ?? corner!.toResizeCursor(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (side?.isVertical ?? false)
            ? (details) {
                context.read<ResizableBloc>().add(ResizeSide(
                      side: side!,
                      delta: details.primaryDelta!,
                    ));
              }
            : null,
        onVerticalDragEnd: (side?.isVertical ?? false)
            ? (details) {
                context.read<ResizableBloc>().add(const ResizeEnd());
              }
            : null,
        onHorizontalDragUpdate: (side?.isHorizontal ?? false)
            ? (details) {
                context.read<ResizableBloc>().add(ResizeSide(
                      side: side!,
                      delta: details.primaryDelta!,
                    ));
              }
            : null,
        onHorizontalDragEnd: (side?.isHorizontal ?? false)
            ? (details) {
                context.read<ResizableBloc>().add(const ResizeEnd());
              }
            : null,
        onPanUpdate: corner != null
            ? (details) {
                context.read<ResizableBloc>().add(ResizeCorner(
                      corner: corner!,
                      delta: details.delta,
                    ));
              }
            : null,
        onPanEnd: corner != null
            ? (details) {
                context.read<ResizableBloc>().add(const ResizeEnd());
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size,
            minWidth: size,
          ),
          child: Center(
            child: Container(
              foregroundDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              width: kHandleRenderSize,
              height: kHandleRenderSize,
            ),
          ),
        ),
      ),
    );
  }
}
