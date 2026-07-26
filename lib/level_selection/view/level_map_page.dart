import 'dart:ui';

import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/background/background.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Vertical adventure map: level 1 at the bottom, higher levels climb upward.
class LevelMapPage extends StatefulWidget {
  LevelMapPage(this.chapters, {Key? key})
      : levels = chapters.expand((c) => c.levels).toList(),
        chapterName = chapters.first.name,
        super(key: key) {
    AdManager().addAds(true, true, false);
  }

  final List<LevelChapter> chapters;
  final List<LevelData> levels;
  final String chapterName;

  @override
  State<LevelMapPage> createState() => _LevelMapPageState();
}

class _LevelMapPageState extends State<LevelMapPage> {
  final _scroll = ScrollController();
  late Future<_MapProgress> _progressFuture;

  static const double _rowH = 110;
  static const double _node = 64;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<_MapProgress> _loadProgress() async {
    final stars = <int>[];
    final done = <bool>[];
    for (final l in widget.levels) {
      stars.add(await getLevelStars(l.name));
      done.add(await isLevelCompleted(l.name));
    }
    var current = 0;
    for (var i = 0; i < done.length; i++) {
      if (!done[i]) {
        current = i;
        break;
      }
      current = i;
    }
    return _MapProgress(stars: stars, done: done, currentIndex: current);
  }

  Future<void> _scrollToCurrent() async {
    final p = await _progressFuture;
    if (!mounted || !_scroll.hasClients) return;
    // List is reversed visually via reverse:true, index 0 at bottom.
    final offset = p.currentIndex * _rowH;
    _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
  }

  bool _isUnlocked(int index, _MapProgress p) {
    if (unlockAllLevelsForTesting) return true;
    if (index == 0) return true;
    return p.stars[index - 1] >= 2 || p.done[index - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final n = widget.levels.length;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppBottomTab.levels),
      body: Stack(
        children: [
          const RotatingPuzzleBackground(),
          // Soft sky gradient overlay for map feel
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withOpacity(0.18),
                    Colors.transparent,
                    colors.tertiary.withOpacity(0.12),
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          FutureBuilder<_MapProgress>(
            future: _progressFuture,
            builder: (context, snap) {
              final p = snap.data ??
                  _MapProgress(
                    stars: List.filled(n, 0),
                    done: List.filled(n, false),
                    currentIndex: 0,
                  );

              return CustomScrollView(
                controller: _scroll,
                reverse: true, // level 1 at bottom, climb up
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: _MapHeader(
                        cleared: p.done.where((e) => e).length,
                        total: n,
                        current: p.currentIndex + 1,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: n * _rowH + 40,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          return Stack(
                            children: [
                              // Path ribbon
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _PathPainter(
                                    count: n,
                                    rowH: _rowH,
                                    width: width,
                                    node: _node,
                                    color: colors.primary.withOpacity(0.45),
                                    glow: colors.tertiary.withOpacity(0.25),
                                  ),
                                ),
                              ),
                              // Nodes (index 0 at bottom because reverse list parent;
                              // inside this stack y=0 is top of the tall box.
                              // With reverse CustomScrollView, first sliver child
                              // appears at bottom — our tall box grows upward.
                              // Place level i near bottom: y = (n-1-i)*rowH
                              for (var i = 0; i < n; i++)
                                _buildNode(
                                  context,
                                  index: i,
                                  progress: p,
                                  width: width,
                                  top: (n - 1 - i) * _rowH + 20,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNode(
    BuildContext context, {
    required int index,
    required _MapProgress progress,
    required double width,
    required double top,
  }) {
    final level = widget.levels[index];
    final unlocked = _isUnlocked(index, progress);
    final isCurrent = index == progress.currentIndex;
    final stars = progress.stars[index];
    final done = progress.done[index];
    final x = _nodeX(index, width);

    return Positioned(
      top: top,
      left: x - _node / 2,
      child: _LevelNode(
        number: index + 1,
        unlocked: unlocked,
        isCurrent: isCurrent,
        stars: stars,
        completed: done,
        size: _node,
        onTap: () {
          if (!unlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  index == 0
                      ? 'Start here!'
                      : 'Clear level $index with 2★ to unlock',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          context
              .read<NavigatorCubit>()
              .navigateToLevel(widget.chapterName, level.name);
        },
      ),
    );
  }

  double _nodeX(int index, double width) {
    // Winding S-path: alternate left/right lobes
    final t = (index % 6) / 5.0;
    final lobe = (index ~/ 3).isEven;
    final edge = 56.0;
    if (lobe) {
      return lerpDouble(edge + _node / 2, width - edge - _node / 2, t)!;
    }
    return lerpDouble(width - edge - _node / 2, edge + _node / 2, t)!;
  }
}

class _MapProgress {
  _MapProgress({
    required this.stars,
    required this.done,
    required this.currentIndex,
  });
  final List<int> stars;
  final List<bool> done;
  final int currentIndex;
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.cleared,
    required this.total,
    required this.current,
  });

  final int cleared;
  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colors.surface.withOpacity(0.72),
            border: Border.all(color: colors.outline.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adventure Map', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Climb from the bottom — twisty rooms await',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.flag_rounded, size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Text('Level $current', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '$cleared / $total',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : cleared / total,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.number,
    required this.unlocked,
    required this.isCurrent,
    required this.stars,
    required this.completed,
    required this.size,
    required this.onTap,
  });

  final int number;
  final bool unlocked;
  final bool isCurrent;
  final int stars;
  final bool completed;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = !unlocked
        ? colors.surfaceContainerHighest.withValues(alpha: 0.85)
        : completed
            ? colors.primary
            : isCurrent
                ? colors.tertiary
                : colors.secondaryContainer;

    final fg = !unlocked
        ? colors.onSurfaceVariant
        : completed || isCurrent
            ? colors.onPrimary
            : colors.onSecondaryContainer;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(
                color: isCurrent
                    ? colors.onTertiary.withOpacity(0.9)
                    : colors.outline.withOpacity(unlocked ? 0.15 : 0.35),
                width: isCurrent ? 3 : 1.5,
              ),
              boxShadow: [
                if (unlocked)
                  BoxShadow(
                    color: (completed ? colors.primary : colors.tertiary)
                        .withOpacity(isCurrent ? 0.45 : 0.22),
                    blurRadius: isCurrent ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: unlocked
                ? Text(
                    '$number',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                  )
                : Icon(Icons.lock_rounded, color: fg, size: 22),
          ),
          const SizedBox(height: 4),
          if (unlocked && stars > 0)
            Text(
              '★' * stars,
              style: TextStyle(
                fontSize: 11,
                color: colors.primary,
                height: 1,
              ),
            )
          else if (isCurrent)
            Text(
              'YOU',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({
    required this.count,
    required this.rowH,
    required this.width,
    required this.node,
    required this.color,
    required this.glow,
  });

  final int count;
  final double rowH;
  final double width;
  final double node;
  final Color color;
  final Color glow;

  double _x(int index) {
    final t = (index % 6) / 5.0;
    final lobe = (index ~/ 3).isEven;
    const edge = 56.0;
    if (lobe) {
      return lerpDouble(edge + node / 2, width - edge - node / 2, t)!;
    }
    return lerpDouble(width - edge - node / 2, edge + node / 2, t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final path = Path();
    for (var i = 0; i < count; i++) {
      final x = _x(i);
      final y = (count - 1 - i) * rowH + 20 + node / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final px = _x(i - 1);
        final py = (count - 1 - (i - 1)) * rowH + 20 + node / 2;
        final midY = (py + y) / 2;
        path.cubicTo(px, midY, x, midY, x, y);
      }
    }

    final glowPaint = Paint()
      ..color = glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);

    // Dashed sparkle dots along path
    final metric = path.computeMetrics().first;
    final dot = Paint()..color = color.withOpacity(0.7);
    for (var d = 0.0; d < metric.length; d += 28) {
      final tan = metric.getTangentForOffset(d);
      if (tan == null) continue;
      canvas.drawCircle(tan.position, 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.width != width ||
      oldDelegate.color != color;
}
