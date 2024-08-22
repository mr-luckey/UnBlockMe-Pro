part of 'resizable_bloc.dart';

class ResizableState {
  ResizableState({
    required double top,
    required double left,
    required double bottom,
    required double right,
  })  : internalPosition = ResizablePosition(
          top: top,
          left: left,
          bottom: bottom,
          right: right,
        ),
        displayedPosition = ResizablePosition(
          top: top,
          left: left,
          bottom: bottom,
          right: right,
        ),
        resizingSides = [];
  const ResizableState._({
    required this.internalPosition,
    required this.displayedPosition,
    required this.resizingSides,
  });

  final ResizablePosition internalPosition;
  final ResizablePosition displayedPosition;
  final List<BoxSide> resizingSides;

  double get top => displayedPosition.top;
  double get left => displayedPosition.left;
  double get bottom => displayedPosition.bottom;
  double get right => displayedPosition.right;

  double get width => displayedPosition.width;
  double get height => displayedPosition.height;
  Size get size => displayedPosition.size;
  Offset get offset => displayedPosition.offset;

  ResizableState copyWith({
    double? top,
    double? left,
    double? bottom,
    double? right,
    required List<BoxSide> sidesToAdjust,
    required OffsetSnapper? offsetSnapper,
    required SizeSnapper? sizeSnapper,
  }) {
    final newInternalPosition = ResizablePosition(
      top: top ?? internalPosition.top,
      left: left ?? internalPosition.left,
      bottom: bottom ?? internalPosition.bottom,
      right: right ?? internalPosition.right,
    );
    var newDisplayedPosition = ResizablePosition(
      top: top ?? displayedPosition.top,
      left: left ?? displayedPosition.left,
      bottom: bottom ?? displayedPosition.bottom,
      right: right ?? displayedPosition.right,
    );
    if (sizeSnapper != null) {
      newDisplayedPosition = newDisplayedPosition.withSize(
        sizeSnapper(newDisplayedPosition.size),
        sidesToAdjust: sidesToAdjust,
      );
    }
    if (offsetSnapper != null) {
      newDisplayedPosition = newDisplayedPosition
          .atOffset(offsetSnapper(newDisplayedPosition.offset));
    }
    return ResizableState._(
      internalPosition: newInternalPosition,
      displayedPosition: newDisplayedPosition,
      resizingSides: sidesToAdjust,
    );
  }
}

class ResizablePosition extends Equatable {
  const ResizablePosition({
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });

  final double top;
  final double left;
  final double bottom;
  final double right;

  double get width => right - left;
  double get height => bottom - top;
  Size get size => Size(width, height);
  Offset get offset => Offset(left, top);

  ResizablePosition copyWith({
    double? top,
    double? left,
    double? bottom,
    double? right,
  }) {
    return ResizablePosition(
      top: top ?? this.top,
      left: left ?? this.left,
      bottom: bottom ?? this.bottom,
      right: right ?? this.right,
    );
  }

  ResizablePosition withSize(Size size,
      {required List<BoxSide> sidesToAdjust}) {
    final adjustTop = sidesToAdjust.contains(BoxSide.top);
    final adjustLeft = sidesToAdjust.contains(BoxSide.left);
    final newTop = adjustTop ? bottom - size.height : top;
    final newLeft = adjustLeft ? right - size.width : left;
    final newBottom = adjustTop ? bottom : top + size.height;
    final newRight = adjustLeft ? right : left + size.width;
    return ResizablePosition(
      top: newTop,
      left: newLeft,
      bottom: newBottom,
      right: newRight,
    );
  }

  ResizablePosition atOffset(Offset offset) {
    return ResizablePosition(
      top: offset.dy,
      left: offset.dx,
      bottom: offset.dy + height,
      right: offset.dx + width,
    );
  }

  @override
  List<Object> get props => [top, left, bottom, right];
}
