import 'package:flutter/material.dart';

class LabeledPuzzleButton extends StatelessWidget {
  const LabeledPuzzleButton({
    Key? key,
    required this.label,
    required this.puzzle,
    this.isCompleted,
    this.isLocked = false,
    this.trailing,
    this.meta,
    this.onPressed,
    this.onLockedPressed,
  }) : super(key: key);

  final Widget label;
  final Widget puzzle;
  final bool? isCompleted;
  final bool isLocked;
  final Widget? trailing;
  final Widget? meta;
  final void Function()? onPressed;
  final void Function()? onLockedPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLocked ? onLockedPressed : onPressed,
      child: Stack(
        children: [
          Opacity(
            opacity: isLocked ? 0.45 : 1.0,
            child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Center(
                child: FittedBox(
                  child: puzzle,
                ),
              ),
            ),
          )),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                child: Wrap(
                  runSpacing: 4,
                  children: [
                    Row(
                      children: [
                        Expanded(child: label),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          trailing!,
                        ],
                      ],
                    ),
                    if (meta != null) meta!,
                  ],
                ),
              ),
            ),
          ),
          if (isCompleted != null && isCompleted!)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: Icon(Icons.check,
                      color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
          if (isLocked)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(Icons.lock, color: Colors.amber),
            ),
        ],
      ),
    );
  }
}
