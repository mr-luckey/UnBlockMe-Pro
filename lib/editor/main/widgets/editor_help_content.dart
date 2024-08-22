import 'package:blocked/editor/editor.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class EditorHelpContent extends StatelessWidget {
  const EditorHelpContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Adding blocks, walls',
              style: Theme.of(context).textTheme.titleLarge),
          RichText(
            text: TextSpan(children: const [
              TextSpan(
                text: '1. Select ',
              ),
              WidgetSpan(
                child: Icon(MdiIcons.checkboxIntermediate),
              ),
              TextSpan(
                text: ' to enter block-building mode, ',
              ),
              WidgetSpan(
                child: Icon(MdiIcons.wall),
              ),
              TextSpan(
                text: ' to enter wall-building mode.',
              ),
            ], style: Theme.of(context).textTheme.bodyLarge),
          ),
          const Text('2. Drag on the grid to place the selected object type.'),
          const Text(
              '3. After placing an object, the editor switches back to select mode.'),
          const SizedBox(height: 32),
          Text('Adding exits', style: Theme.of(context).textTheme.titleLarge),
          const Text(
              'Place a wall along the perimeter of the level to create an exit.'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IgnorePointer(
              child: SizedBox(
                width: 5.toBoardSize(),
                height: 3.toBoardSize(),
                child: Portal(
                  child: Stack(
                    children: [
                      ResizableFloor.container(
                        EditorFloor.initial(2, 2),
                        [
                          Segment.vertical(x: 2, start: 0, end: 1),
                        ],
                        isSelected: false,
                      ),
                      ResizableSegment(
                        EditorSegment.initial(
                            Segment.vertical(x: 2, start: 0, end: 1),
                            type: SegmentType.wall),
                        isSelected: true,
                        isExit: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Resizing, modifying and deleting objects',
              style: Theme.of(context).textTheme.titleLarge),
          const Text(
              'Select an object to view its drag handles, delete it and more.'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IgnorePointer(
              child: SizedBox(
                width: 4.toBoardSize(),
                height: 3.toBoardSize(),
                child: Portal(
                  child: Stack(
                    children: [
                      ResizableBlock(
                        EditorBlock.initial(const Block(1, 1).place(0, 0)),
                        isSelected: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('Level requirements',
              style: Theme.of(context).textTheme.titleLarge),
          const Text('Every level requires at least:'),
          const Text('- A main block'),
          const Text(
              '- An initial block (controlled at the start of the level)'),
          const Text('- An exit'),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),
          Text(
            'Trying a level',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          RichText(
            text: TextSpan(children: const [
              TextSpan(text: '1. Select "'),
              WidgetSpan(
                child: Icon(MdiIcons.play),
              ),
              TextSpan(text: ' Play" to play the level.'),
            ], style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 16),
          Text(
            'Sharing a level',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RichText(
            text: TextSpan(children: [
              const TextSpan(text: '1. On the generated level page, select "'),
              WidgetSpan(
                child: Icon(Icons.adaptive.share),
              ),
              const TextSpan(
                  text: ' Copy link" to copy a link to the generated level.'),
            ], style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
