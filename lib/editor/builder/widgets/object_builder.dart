import 'dart:math';

import 'package:blocked/editor/editor.dart';
import 'package:blocked/models/models.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ObjectBuilder extends StatelessWidget {
  const ObjectBuilder({
    Key? key,
    required this.onObjectPlaced,
    required this.hintBuilder,
    required this.offsetTransformer,
    required this.positionTransformer,
    required this.threshold,
  }) : super(key: key);

  final void Function(Position start, Position end) onObjectPlaced;
  final Widget? Function(Position? start, Position? end) hintBuilder;
  final Position Function(Offset offset) offsetTransformer;
  final Offset Function(Position position) positionTransformer;

  /// The number of pixels from a point that the cursor must be within to show hint.
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ObjectBuilderBloc(),
      child: BlocConsumer<ObjectBuilderBloc, ObjectBuilderState>(
        listenWhen: (previous, current) {
          return previous.isObjectPlaced != current.isObjectPlaced &&
              current.isObjectPlaced;
        },
        listener: (context, state) {
          final start = state.start;
          final end = state.end;
          assert(start != null && end != null,
              'object start and end must not be null');
          onObjectPlaced(start!, end!);
        },
        buildWhen: (previous, current) {
          return previous.start != current.start || previous.end != current.end;
        },
        builder: (context, state) {
          final start = state.start;
          final end = state.end;

          return Listener(
            onPointerHover: (event) {
              final position = offsetTransformer(event.localPosition);
              final snappedOffset = positionTransformer(position);
              final difference = snappedOffset - event.localPosition;

              if (min(difference.dx, difference.dy) < threshold) {
                context.read<ObjectBuilderBloc>().add(PointUpdate(position));
              } else {
                context.read<ObjectBuilderBloc>().add(const PointCancelled());
              }
            },
            child: GestureDetector(
              dragStartBehavior: DragStartBehavior.down,
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final position = offsetTransformer(details.localPosition);
                context.read<ObjectBuilderBloc>().add(PointDown(position));
              },
              onTapUp: (details) {
                final position = offsetTransformer(details.localPosition);
                context.read<ObjectBuilderBloc>().add(PointUp(position));
              },
              onPanDown: (details) {
                final position = offsetTransformer(details.localPosition);
                context.read<ObjectBuilderBloc>().add(PointDown(position));
              },
              onPanUpdate: (details) {
                final position = offsetTransformer(details.localPosition);
                context.read<ObjectBuilderBloc>().add(PointUpdate(position));
              },
              onPanEnd: (details) {
                final hoveredPosition =
                    context.read<ObjectBuilderBloc>().state.hoveredPosition;

                context
                    .read<ObjectBuilderBloc>()
                    .add(PointUp(hoveredPosition!));
              },
              child: Stack(
                children: [
                  Positioned.fill(
                      child: Ink(
                    color: Colors.black.withOpacity(0.1),
                  )),
                  hintBuilder(start, end) ?? Container(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
