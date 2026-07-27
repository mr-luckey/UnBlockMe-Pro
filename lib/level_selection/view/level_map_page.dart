import 'dart:math' as math;

import 'package:blocked/level_selection/cubit/map_progress_cubit.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/progress/progress.dart';
import 'package:blocked/routing/routing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Adventure map — virtualized list (fast) + batch progress Cubit.
class LevelMapPage extends StatelessWidget {
  LevelMapPage(this.chapters, {Key? key})
      : levels = [
          for (final c in chapters)
            for (final l in c.levels) _FlatLevel(c.name, l)
        ],
        super(key: key);

  final List<LevelChapter> chapters;
  final List<_FlatLevel> levels;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapProgressCubit([
        for (final l in levels) l.name,
      ]),
      child: _LevelMapView(levels: levels),
    );
  }
}

class _FlatLevel {
  const _FlatLevel(this.chapterName, this.data);
  final String chapterName;
  final LevelData data;
  String get name => data.name;
}

class _LevelMapView extends StatefulWidget {
  const _LevelMapView({required this.levels});
  final List<_FlatLevel> levels;

  @override
  State<_LevelMapView> createState() => _LevelMapViewState();
}

class _LevelMapViewState extends State<_LevelMapView> {
  final _scroll = ScrollController();
  bool _didScroll = false;

  static const _assets = 'assets/ui/map';
  static const double _padBottom = 20;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCurrent(int currentIndex) {
    if (_didScroll || !_scroll.hasClients) return;
    _didScroll = true;
    final max = _scroll.position.maxScrollExtent;
    final n = math.max(1, widget.levels.length - 1);
    final target = (currentIndex / n) * max;
    _scroll.jumpTo(target.clamp(0.0, max));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (size.height / 840).clamp(0.80, 1.12);
    final n = widget.levels.length;
    final side = (size.width * 0.04).clamp(12.0, 22.0);
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              SizedBox(height: pad.top + 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side),
                child: _MapHeader(
                  scale: s,
                  onBack: () =>
                      context.read<NavigatorCubit>().navigateToHome(),
                ),
              ),
              Expanded(
                child: BlocConsumer<MapProgressCubit, MapProgressState>(
                  listenWhen: (prev, next) =>
                      prev.loading && !next.loading && next.progress != null,
                  listener: (context, state) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToCurrent(state.progress!.currentIndex);
                    });
                  },
                  builder: (context, state) {
                    if (state.loading || state.progress == null) {
                      return const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                      );
                    }
                    final progress = state.progress!;
                    // reverse:true → index 0 at bottom (level 1)
                    return ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: _padBottom, top: 16),
                      itemExtent: _MapPath.rowH,
                      itemCount: n,
                      itemBuilder: (context, index) {
                        final level = widget.levels[index];
                        final stars = progress.stars[level.name] ?? 0;
                        final unlocked = progress.unlocked[index];
                        final isCurrent = index == progress.currentIndex;
                        final x = _MapPath.xFor(index, size.width);
                        final alignX = ((x / size.width) * 2) - 1;

                        return CustomPaint(
                          painter: _SegmentPainter(
                            index: index,
                            count: n,
                            width: size.width,
                          ),
                          child: Align(
                            alignment: Alignment(alignX.clamp(-1.0, 1.0), 0),
                            child: GestureDetector(
                              onTap: !unlocked
                                  ? null
                                  : () => context
                                      .read<NavigatorCubit>()
                                      .navigateToLevel(
                                        level.chapterName,
                                        level.name,
                                      ),
                              child: _MapNode(
                                number: index + 1,
                                stars: stars,
                                locked: !unlocked,
                                current: isCurrent,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPath {
  static const double rowH = 96;
  static const double zigLevels = 3.2;

  static double xFor(int index, double width) {
    final wave = -math.cos((index / zigLevels) * math.pi);
    final organic = math.sin(index * 0.55) * 0.1;
    final amplitude = width * 0.38;
    return width * 0.5 + (wave + organic).clamp(-1.0, 1.0) * amplitude;
  }
}

/// Paints only the short trail segment for this row (cheap + virtualized).
class _SegmentPainter extends CustomPainter {
  _SegmentPainter({
    required this.index,
    required this.count,
    required this.width,
  });

  final int index;
  final int count;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (index >= count - 1) return;
    final x0 = _MapPath.xFor(index, width);
    final x1 = _MapPath.xFor(index + 1, width);
    // reverse list: higher level is visually above → next index is toward top
    final y0 = size.height * 0.5;
    final y1 = -size.height * 0.5;

    final path = Path()
      ..moveTo(x0, y0)
      ..cubicTo(x0, (y0 + y1) / 2, x1, (y0 + y1) / 2, x1, y1);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5C3A1E).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD4A574)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF0D9B0).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    final mid = Offset((x0 + x1) / 2, (y0 + y1) / 2);
    canvas.drawCircle(mid, 2.8, Paint()..color = const Color(0xFFFFF3D6));
  }

  @override
  bool shouldRepaint(covariant _SegmentPainter old) =>
      old.index != index || old.width != width;
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.scale, required this.onBack});

  final double scale;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final btn = (44.0 * scale).clamp(40.0, 52.0);
    final bannerH = (56.0 * scale).clamp(48.0, 68.0);

    return Row(
      children: [
        _WoodIconButton(
          size: btn,
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/ui/map/banner.png',
              height: bannerH,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
        ),
        StreamBuilder<PlayerProgress>(
          stream: playerProgressStream(),
          builder: (context, snap) {
            final stars = snap.data?.totalStars ?? 0;
            return _StarsChip(stars: stars, height: btn * 0.85);
          },
        ),
      ],
    );
  }
}

class _WoodIconButton extends StatelessWidget {
  const _WoodIconButton({
    required this.size,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1E), Color(0xFF3A2210)],
            ),
            border: Border.all(color: const Color(0xFFC4A574), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.48),
        ),
      ),
    );
  }
}

class _StarsChip extends StatelessWidget {
  const _StarsChip({required this.stars, required this.height});

  final int stars;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1E)],
        ),
        border: Border.all(color: const Color(0xFFC4A574), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/ui/home/icon_star.png',
            height: height * 0.55,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
          const SizedBox(width: 6),
          Text(
            '$stars',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: height * 0.42,
              shadows: const [
                Shadow(
                    color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.number,
    required this.stars,
    required this.locked,
    required this.current,
  });

  final int number;
  final int stars;
  final bool locked;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final size = current ? 58.0 : 52.0;
    final colors = locked
        ? const [Color(0xFF6B6B6B), Color(0xFF4A4A4A), Color(0xFF333333)]
        : current
            ? const [Color(0xFFFFB347), Color(0xFFFF8C1A), Color(0xFFE06A00)]
            : const [Color(0xFF5CB8FF), Color(0xFF2E8DE8), Color(0xFF1A6BC4)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (current)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'YOU',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE06A00),
                letterSpacing: 0.6,
              ),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: current ? 0.75 : 0.45),
              width: current ? 3 : 2.2,
            ),
            boxShadow: [
              if (current)
                BoxShadow(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.65),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              else if (!locked)
                BoxShadow(
                  color: const Color(0xFF2E8DE8).withValues(alpha: 0.4),
                  blurRadius: 10,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: locked
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$number',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1,
                        ),
                      ),
                      const Icon(Icons.lock_rounded,
                          size: 14, color: Colors.white70),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$number',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: number >= 100 ? 13 : 16,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      if (stars > 0) ...[
                        const SizedBox(height: 1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            3,
                            (i) => Icon(
                              Icons.star_rounded,
                              size: 9,
                              color: i < stars
                                  ? const Color(0xFFFFE566)
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
