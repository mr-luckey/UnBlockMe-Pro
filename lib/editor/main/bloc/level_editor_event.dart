part of 'level_editor_bloc.dart';

abstract class LevelEditorEvent {
  const LevelEditorEvent();
}

class EditorObjectMoved extends LevelEditorEvent {
  const EditorObjectMoved(this.object, this.size, this.offset);

  final EditorObject object;
  final Size size;
  final Offset offset;
}

class EditorObjectSelected extends LevelEditorEvent {
  const EditorObjectSelected(this.object);

  final EditorObject? object;
}

class SelectedEditorObjectDeleted extends LevelEditorEvent {
  const SelectedEditorObjectDeleted();
}

class MainEditorBlockSet extends LevelEditorEvent {
  const MainEditorBlockSet(this.block);

  final EditorBlock block;
}

class InitialEditorBlockSet extends LevelEditorEvent {
  const InitialEditorBlockSet(this.block);

  final EditorBlock block;
}

class EditorSegmentTypeSet extends LevelEditorEvent {
  const EditorSegmentTypeSet(this.segment, this.type);

  final EditorSegment segment;
  final SegmentType type;
}

class BlockAdded extends LevelEditorEvent {
  const BlockAdded(this.block);

  final PlacedBlock block;
}

class SegmentAdded extends LevelEditorEvent {
  const SegmentAdded(this.segment);

  final Segment segment;
}

class TestMapPressed extends LevelEditorEvent {
  const TestMapPressed();
}

class TestMapExited extends LevelEditorEvent {
  const TestMapExited();
}

class EditorToolSelected extends LevelEditorEvent {
  const EditorToolSelected(this.tool);

  final EditorTool tool;
}

class GridToggled extends LevelEditorEvent {
  const GridToggled();
}

class MapCleared extends LevelEditorEvent {
  const MapCleared();
}

class SavePressed extends LevelEditorEvent {
  const SavePressed();
}

class EscapePressed extends LevelEditorEvent {
  const EscapePressed();
}
