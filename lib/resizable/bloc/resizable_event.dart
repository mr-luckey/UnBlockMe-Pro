part of 'resizable_bloc.dart';


extension CornerToSides on BoxCorner {
  List<BoxSide> get sides {
    switch (this) {
      case BoxCorner.topLeft:
        return [BoxSide.top, BoxSide.left];
      case BoxCorner.topRight:
        return [BoxSide.top, BoxSide.right];
      case BoxCorner.bottomLeft:
        return [BoxSide.bottom, BoxSide.left];
      case BoxCorner.bottomRight:
        return [BoxSide.bottom, BoxSide.right];
    }
  }
}

abstract class ResizeEvent {
  const ResizeEvent();
}

class Pan extends ResizeEvent {
  const Pan({required this.delta});

  final Offset delta;
}

class PanEnd extends ResizeEvent {
  const PanEnd();
}

class ResizeSide extends ResizeEvent {
  const ResizeSide({
    required this.side,
    required this.delta,
  });

  final BoxSide side;
  final double delta;
}

class ResizeCorner extends ResizeEvent {
  const ResizeCorner({
    required this.corner,
    required this.delta,
  });

  final BoxCorner corner;
  final Offset delta;
}

class ResizeEnd extends ResizeEvent {
  const ResizeEnd();
}
