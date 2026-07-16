import 'dart:ui';

import 'package:flutter/material.dart';

/// Redesigned level card.
///
/// What changed vs the old version:
/// - Real elevation/gradient instead of a flat OutlinedButton -> feels like
///   a "tile" you can press, not a form control.
/// - Press feedback: AnimatedScale + InkWell splash so tapping feels alive.
/// - Locked state uses a blurred puzzle preview + centered lock chip instead
///   of a washed-out opacity + tiny icon in the corner.
/// - Stars are real Icon widgets (crisp, themeable) instead of an emoji
///   string, and they sit in a small pill instead of floating text.
/// - Completed state gets a colored corner ribbon instead of a plain
///   bordered box, so "done" reads at a glance across a grid.
class LabeledPuzzleButton extends StatefulWidget {
  const LabeledPuzzleButton({
    Key? key,
    required this.label,
    required this.puzzle,
    this.isCompleted,
    this.isLocked = false,
    this.stars = 0,
    this.metaText,
    this.onPressed,
    this.onLockedPressed,
  }) : super(key: key);

  final Widget label;
  final Widget puzzle;
  final bool? isCompleted;
  final bool isLocked;

  /// 0-3. Replaces the old `trailing` emoji-star widget with a typed value
  /// so the card can render its own consistent star row.
  final int stars;

  /// Replaces the old `meta` widget with plain text ("128 moves · 42s",
  /// "Not solved yet", etc.) so styling stays consistent across cards.
  final String? metaText;

  final void Function()? onPressed;
  final void Function()? onLockedPressed;

  @override
  State<LabeledPuzzleButton> createState() => _LabeledPuzzleButtonState();
}

class _LabeledPuzzleButtonState extends State<LabeledPuzzleButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final completed = widget.isCompleted ?? false;

    final accent = completed
        ? colors.tertiary
        : widget.isLocked
            ? colors.outline
            : colors.primary;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.isLocked ? widget.onLockedPressed : widget.onPressed,
          onHighlightChanged: _setPressed,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.surfaceVariant.withOpacity(0.55),
                  colors.surface,
                ],
              ),
              border: Border.all(
                color: accent.withOpacity(completed ? 0.9 : 0.35),
                width: completed ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // --- Puzzle preview ---
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 46, 14, 34),
                      child: Center(
                        child: FittedBox(
                          child: ImageFiltered(
                            imageFilter: widget.isLocked
                                ? ImageFilter.blur(sigmaX: 4, sigmaY: 4)
                                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                            child: Opacity(
                              opacity: widget.isLocked ? 0.35 : 1.0,
                              child: widget.puzzle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Top label bar ---
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.92),
                        border: Border(
                          bottom: BorderSide(
                            color: accent.withOpacity(0.25),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DefaultTextStyle.merge(
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                              child: widget.label,
                            ),
                          ),
                          if (!widget.isLocked) _StarRow(stars: widget.stars),
                        ],
                      ),
                    ),
                  ),

                  // --- Bottom meta bar ---
                  if (widget.metaText != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color: colors.surface.withOpacity(0.85),
                        child: Text(
                          widget.metaText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),

                  // --- Locked overlay ---
                  if (widget.isLocked)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 16, color: colors.outline),
                            const SizedBox(width: 6),
                            Text(
                              'Locked',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (stars <= 0) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: filled ? colors.tertiary : colors.outline.withOpacity(0.5),
        );
      }),
    );
  }
}
