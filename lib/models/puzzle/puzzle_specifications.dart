import 'package:blocked/models/models.dart';

class PuzzleSpecifications {
  const PuzzleSpecifications({
    required this.width,
    required this.height,
    required this.blocks,
    required this.walls,
    required this.sharpWalls,
  });

  final int width;
  final int height;
  final List<PlacedBlock> blocks;
  final List<Segment> walls;
  final List<Segment> sharpWalls;
}
