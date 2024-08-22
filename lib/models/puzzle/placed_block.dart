part of 'block.dart';

class PlacedBlock extends Block with EquatableMixin {
  PlacedBlock.from(
    Position start,
    Position end, {
    required bool isMain,
    required bool hasControl,
  })  : position = Position(min(start.x, end.x), min(start.y, end.y)),
        super((end.x - start.x).abs() + 1, (end.y - start.y).abs() + 1,
            isMain: isMain, hasControl: hasControl);

  const PlacedBlock(
    int width,
    int height,
    this.position, {
    required bool isMain,
    required bool hasControl,
  }) : super(
          width,
          height,
          isMain: isMain,
          hasControl: hasControl,
        );

  final Position position;

  int get left => position.x;
  int get right => position.x + width - 1;
  int get top => position.y;
  int get bottom => position.y + height - 1;

  PlacedBlock translate(int dx, int dy) => PlacedBlock(
        width,
        height,
        position + Position(dx, dy),
        isMain: isMain,
        hasControl: hasControl,
      );

  PlacedBlock copyWith({
    int? width,
    int? height,
    Position? position,
    bool? isMain,
    bool? hasControl,
  }) =>
      PlacedBlock(
        width ?? this.width,
        height ?? this.height,
        position ?? this.position,
        isMain: isMain ?? this.isMain,
        hasControl: hasControl ?? this.hasControl,
      );

  @override
  List<Object?> get props => [width, height, position, isMain, hasControl];
}

extension PlaceBlock on Block {
  PlacedBlock withPosition(Position position) =>
      PlacedBlock(width, height, position,
          isMain: isMain, hasControl: hasControl);
  PlacedBlock place(int x, int y) => PlacedBlock(
        width,
        height,
        Position(x, y),
        isMain: isMain,
        hasControl: hasControl,
      );
}
