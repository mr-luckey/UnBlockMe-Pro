part of 'object_builder_bloc.dart';

abstract class ObjectBuilderEvent {
  const ObjectBuilderEvent();
}

class PointUpdate extends ObjectBuilderEvent {
  const PointUpdate(this.position);

  final Position position;
}

class PointCancelled extends ObjectBuilderEvent {
  const PointCancelled();
}

class PointDown extends ObjectBuilderEvent {
  const PointDown(this.position);

  final Position position;
}

class PointUp extends ObjectBuilderEvent {
  const PointUp(this.position);

  final Position position;
}
