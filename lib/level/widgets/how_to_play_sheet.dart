import 'package:flutter/material.dart';

/// One-time "How to Play" overlay.
///
/// Shown exactly once, the first time any level page mounts on a fresh
/// install (gated by `hasSeenTutorial()` / `markTutorialSeen()` in
/// progress_saver.dart). Deliberately kept to three short, icon-led rows
/// instead of a swipeable multi-page tutorial — the goal is "get out of the
/// way in under five seconds", not a full walkthrough. Uses only built-in
/// Material icons/widgets so it costs nothing in extra assets.
class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HowToPlaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outline.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.extension_rounded, color: colors.tertiary, size: 28),
                const SizedBox(width: 10),
                Text('How to Play', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 20),
            _TutorialRow(
              icon: Icons.pan_tool_alt_rounded,
              iconColor: colors.primary,
              text: 'Drag any block — it slides straight along its own row '
                  'or column, not off it.',
            ),
            const SizedBox(height: 16),
            _TutorialRow(
              icon: Icons.flag_rounded,
              iconColor: colors.tertiary,
              text: 'Clear the way for the marked block to reach the '
                  'glowing exit.',
            ),
            const SizedBox(height: 16),
            _TutorialRow(
              icon: Icons.star_rounded,
              iconColor: colors.secondary,
              text: 'Fewer moves than par earns more stars — check the '
                  'move bar as you play.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Got it — let's play!",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialRow extends StatelessWidget {
  const _TutorialRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
