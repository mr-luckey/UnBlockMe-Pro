import 'package:flutter/material.dart';

typedef SizeSnapper = Size Function(Size size);
typedef OffsetSnapper = Offset Function(Offset offset);

double _snapToInterval(
    double value, double? interval, double offset, double min, double max) {
  final offsetValue = value - offset;
  final snappedValue = interval != null
      ? ((offsetValue / interval).roundToDouble() * interval)
      : offsetValue;
  return (snappedValue + offset).clamp(min, max);
}

class SnapSizeDelegate {
  const SnapSizeDelegate(this.sizeSnapper);
  SnapSizeDelegate.interval({
    double? width,
    double? height,
    double widthOffset = 0,
    double heightOffset = 0,
    double minWidth = 0,
    double maxWidth = double.infinity,
    double minHeight = 0,
    double maxHeight = double.infinity,
  }) : sizeSnapper = ((Size size) {
          return Size(
            _snapToInterval(size.width, width, widthOffset, minWidth, maxWidth),
            _snapToInterval(
                size.height, height, heightOffset, minHeight, maxHeight),
          );
        });

  final SizeSnapper sizeSnapper;
}

class SnapOffsetDelegate {
  const SnapOffsetDelegate(this.offsetSnapper);
  SnapOffsetDelegate.interval({
    Offset offset = Offset.zero,
    required Offset interval,
    Offset minOffset = Offset.zero,
    Offset maxOffset = const Offset(double.infinity, double.infinity),
  })  : assert(offset.dx <= interval.dx,
            'Offset dx must be less than interval dx.'),
        assert(offset.dy <= interval.dy,
            'Offset dy must be less than interval dy.'),
        offsetSnapper = ((Offset rawOffset) {
          return Offset(
            _snapToInterval(rawOffset.dx, interval.dx, offset.dx, minOffset.dx,
                maxOffset.dx),
            _snapToInterval(rawOffset.dy, interval.dy, offset.dy, minOffset.dy,
                maxOffset.dy),
          );
        });

  final OffsetSnapper offsetSnapper;
}
