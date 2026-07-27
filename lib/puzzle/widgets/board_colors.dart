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

  /// Forest / carved-wood board palette derived from the app ColorScheme.
  BoardColorData.fromColorScheme(ColorScheme colorScheme)
      : this(
          // Warm oak slabs — readable on dark tray
          block: colorScheme.secondary
              .blend(const Color(0xFFC4956A), 55)
              .blend(colorScheme.surface, 15),
          blockOutline: colorScheme.secondary
              .blend(const Color(0xFFE8C99A), 40)
              .blend(Colors.white, 10),
          // Selected block — richer primary wood/ember
          controlledBlock: HSVColor.fromColor(colorScheme.primary)
              .withSaturation(0.55)
              .withValue(0.48)
              .toColor()
              .blend(const Color(0xFF8B4513), 25),
          controlledBlockOutline: colorScheme.primary
              .blend(const Color(0xFFFFB74D), 30),
          // Carved rail
          wall: colorScheme.tertiary
              .blend(const Color(0xFF5D4037), 50)
              .blend(colorScheme.surface, 20),
          // Dark walnut tray
          floor: colorScheme.surface
              .blend(const Color(0xFF2A1A10), 65)
              .blend(Colors.black, 10),
          checkmark: colorScheme.primary.blend(const Color(0xFFFFD54F), 25),
        );

  final Color block;
  final Color blockOutline;
  final Color controlledBlock;
  final Color controlledBlockOutline;
  final Color wall;
  final Color floor;
  final Color checkmark;
}
