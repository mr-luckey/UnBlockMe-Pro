import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class BoardColor extends StatelessWidget {
  const BoardColor({
    Key? key,
    required this.data,
    required this.child,
  }) : super(key: key);

  final BoardColorData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InheritedBoardColor(data: data, child: child);
  }

  static BoardColorData of(BuildContext context) {
    final _inheritedBoardColor =
        context.dependOnInheritedWidgetOfExactType<_InheritedBoardColor>();
    assert(_inheritedBoardColor != null, 'BoardColorData is not found.');
    return _inheritedBoardColor!.data;
  }
}

class _InheritedBoardColor extends InheritedWidget {
  const _InheritedBoardColor({
    Key? key,
    required this.data,
    required Widget child,
  }) : super(key: key, child: child);

  final BoardColorData data;

  @override
  bool updateShouldNotify(_InheritedBoardColor oldWidget) =>
      data != oldWidget.data;
}

class BoardColorData {
  const BoardColorData({
    required this.block,
    required this.blockOutline,
    required this.controlledBlock,
    required this.controlledBlockOutline,
    required this.wall,
    required this.floor,
    required this.checkmark,
  });

  BoardColorData.fromColorScheme(ColorScheme colorScheme)
      : this(
          block: colorScheme.secondary.blend(colorScheme.background, 70),
          blockOutline: colorScheme.secondary.blend(colorScheme.background, 30),
          controlledBlock: HSVColor.fromColor(colorScheme.primary)
              .withSaturation(0.35)
              .withValue(0.35)
              .toColor(),
          controlledBlockOutline: colorScheme.primary,
          wall: colorScheme.tertiary.blend(colorScheme.background, 40),
          floor: colorScheme.surface.blend(colorScheme.background, 80),
          checkmark: colorScheme.primary,
        );

  final Color block;
  final Color blockOutline;
  final Color controlledBlock;
  final Color controlledBlockOutline;
  final Color wall;
  final Color floor;
  final Color checkmark;
}
