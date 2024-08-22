import 'dart:math';

import 'package:blocked/models/models.dart';
import 'package:equatable/equatable.dart';

part 'placed_block.dart';

class Block with EquatableMixin {
  const Block(this.width, this.height,
      {this.isMain = false, this.hasControl = false});

  final int width;
  final int height;
  final bool isMain;
  final bool hasControl;

  @override
  List<Object?> get props => [
        width,
        height,
        isMain,
        hasControl,
      ];
}
