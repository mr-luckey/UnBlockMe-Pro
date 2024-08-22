import 'package:blocked/models/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'object_builder_event.dart';
part 'object_builder_state.dart';

class ObjectBuilderBloc extends Bloc<ObjectBuilderEvent, ObjectBuilderState> {
  ObjectBuilderBloc() : super(const ObjectBuilderState.initial()) {
    on<PointDown>(_onPointDown);
    on<PointUp>(_onPointUp);
    on<PointUpdate>(_onPointUpdate);
    on<PointCancelled>(_onPointCancelled);
  }

  void _onPointUpdate(PointUpdate event, Emitter<ObjectBuilderState> emit) {
    emit(state.copyWith(
      hoveredPosition: event.position,
    ));
  }

  void _onPointCancelled(
      PointCancelled event, Emitter<ObjectBuilderState> emit) {
    emit(state.copyWith(
      hoveredPosition: null,
      start: null,
      end: null,
    ));
  }

  void _onPointDown(PointDown event, Emitter<ObjectBuilderState> emit) {
    if (state._start == null) {
      emit(state.copyWith(
        start: event.position,
      ));
    } else {}
  }

  void _onPointUp(PointUp event, Emitter<ObjectBuilderState> emit) {
    if (state._start != null) {
      emit(state.copyWith(
        end: state.hoveredPosition ?? event.position,
      ));
      emit(state.copyWith(
        start: null,
        end: null,
      ));
    }
  }
}
