import 'package:blocked/resizable/resizable.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'resizable_event.dart';
part 'resizable_state.dart';

class ResizableBloc extends Bloc<ResizeEvent, ResizableState> {
  ResizableBloc({
    required double top,
    required double left,
    required double width,
    required double height,
    this.snapSizeDelegate,
    this.snapOffsetDelegate,
    this.snapWhileResizing = false,
    this.snapWhileMoving = false,
  })  : assert(
          snapSizeDelegate != null || !snapWhileResizing,
          'snapSizeDelegate must be provided if snapWhileDragging is set to true.',
        ),
        assert(
          snapOffsetDelegate != null || !snapWhileMoving,
          'snapOffsetDelegate must be provided if snapWhilePanning is set to true.',
        ),
        super(ResizableState(
            top: top, left: left, bottom: top + height, right: left + width)) {
    on<ResizeSide>(_onResize);
    on<ResizeCorner>(_onResizeCorner);
    on<Pan>(_onPan);
    on<ResizeEnd>(_onResizeEnd);
    on<PanEnd>(_onPanEnd);
  }

  final SnapSizeDelegate? snapSizeDelegate;
  final SnapOffsetDelegate? snapOffsetDelegate;
  final bool snapWhileResizing;
  final bool snapWhileMoving;

  void _onResize(ResizeSide event, Emitter<ResizableState> emit) {
    switch (event.side) {
      case BoxSide.top:
        emit(state.copyWith(
          top: state.internalPosition.top + event.delta,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: [event.side],
        ));
        break;
      case BoxSide.left:
        emit(state.copyWith(
          left: state.internalPosition.left + event.delta,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: [event.side],
        ));
        break;
      case BoxSide.bottom:
        emit(state.copyWith(
          bottom: state.internalPosition.bottom + event.delta,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: [event.side],
        ));
        break;
      case BoxSide.right:
        emit(state.copyWith(
          right: state.internalPosition.right + event.delta,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: [event.side],
        ));
        break;
      default:
    }
  }

  void _onResizeCorner(ResizeCorner event, Emitter<ResizableState> emit) {
    switch (event.corner) {
      case BoxCorner.topLeft:
        emit(state.copyWith(
          top: state.internalPosition.top + event.delta.dy,
          left: state.internalPosition.left + event.delta.dx,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: event.corner.sides,
        ));
        break;
      case BoxCorner.topRight:
        emit(state.copyWith(
          top: state.internalPosition.top + event.delta.dy,
          right: state.internalPosition.right + event.delta.dx,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: event.corner.sides,
        ));
        break;
      case BoxCorner.bottomLeft:
        emit(state.copyWith(
          bottom: state.internalPosition.bottom + event.delta.dy,
          left: state.internalPosition.left + event.delta.dx,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
          sidesToAdjust: event.corner.sides,
        ));
        break;
      case BoxCorner.bottomRight:
        emit(state.copyWith(
          bottom: state.internalPosition.bottom + event.delta.dy,
          right: state.internalPosition.right + event.delta.dx,
          sidesToAdjust: event.corner.sides,
          sizeSnapper: snapSizeDelegate?.sizeSnapper,
          offsetSnapper: snapOffsetDelegate?.offsetSnapper,
        ));
        break;
    }
  }

  void _onPan(Pan event, Emitter<ResizableState> emit) {
    final delta = event.delta;
    emit(state.copyWith(
      top: state.internalPosition.top + delta.dy,
      left: state.internalPosition.left + delta.dx,
      bottom: state.internalPosition.bottom + delta.dy,
      right: state.internalPosition.right + delta.dx,
      offsetSnapper: snapOffsetDelegate?.offsetSnapper,
      sizeSnapper: snapSizeDelegate?.sizeSnapper,
      sidesToAdjust: [],
    ));
  }

  void _onPanEnd(PanEnd event, Emitter<ResizableState> emit) {
    if (snapOffsetDelegate != null) {
      final snapOffset = snapOffsetDelegate!.offsetSnapper(Offset(
        state.internalPosition.left,
        state.internalPosition.top,
      ));
      emit(state.copyWith(
        top: snapOffset.dy,
        left: snapOffset.dx,
        sizeSnapper: snapSizeDelegate?.sizeSnapper,
        offsetSnapper: snapOffsetDelegate?.offsetSnapper,
        sidesToAdjust: [],
      ));
    }
  }

  void _onResizeEnd(ResizeEnd event, Emitter<ResizableState> emit) {
    if (snapSizeDelegate != null) {
      final size =
          Size(state.internalPosition.width, state.internalPosition.height);
      final snapSize = snapSizeDelegate!.sizeSnapper(size);
      emit(state.copyWith(
        right: state.internalPosition.left + snapSize.width,
        bottom: state.internalPosition.top + snapSize.height,
        sizeSnapper: snapSizeDelegate?.sizeSnapper,
        offsetSnapper: snapOffsetDelegate?.offsetSnapper,
        sidesToAdjust: [],
      ));
    }
  }
}
