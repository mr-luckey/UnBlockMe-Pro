import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lit faces are pulled towards warm sunlight and shaded faces towards a warm
/// pitch, so a block always reads as timber rather than tinted plastic.
const _sun = Color(0xFFFFE7C2);
const _pitch = Color(0xFF1B0D03);

/// Paints a block as a chamfered piece of timber, lit from the top left.
///
/// [fill] and [outline] come straight from the board palette, so the piece
/// keeps whatever colour it was given; the depth is all shading, chamfer and
/// grain. [seed] fixes the grain pattern to a block so it does not crawl while
/// the block slides.
void paintWoodBlock(
  Canvas canvas,
  Rect rect, {
  required Color fill,
  required Color outline,
  required int seed,
  double radius = 5,
  bool controlled = false,
}) {
  if (rect.width <= 0 || rect.height <= 0) return;

  final shortest = math.min(rect.width, rect.height);
  // How far the rounded-over edge reaches in from the outline.
  final edge = (shortest * 0.16).clamp(3.0, 11.0);
  final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));

  // Grain runs the length of the piece, the way a sawn plank would.
  final alongWidth = rect.width >= rect.height;

  final lit = Color.lerp(fill, _sun, 0.5)!;
  final dim = Color.lerp(fill, _pitch, 0.55)!;

  canvas
    ..save()
    ..clipRRect(outer);

  // One solid piece of timber: the whole face is wood, with a shallow barrel of
  // light running across the grain.
  canvas
    ..drawRRect(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: alongWidth ? Alignment.topCenter : Alignment.centerLeft,
          end: alongWidth ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [
            Color.lerp(fill, lit, 0.5)!,
            Color.lerp(fill, lit, 0.14)!,
            fill,
            Color.lerp(fill, dim, 0.3)!,
          ],
          stops: const [0, 0.32, 0.66, 1],
        ).createShader(rect),
    )
    ..drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.12),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );

  _paintGrain(canvas, rect, lit, dim, alongWidth, seed);

  // The rounded-over edge, drawn as a soft stroke of the outline itself. Being
  // the same shape it stays concentric and melts into the face, so the piece
  // never reads as a box sitting inside another box.
  final edgeShader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(fill, _sun, 0.66)!,
      Color.lerp(fill, _sun, 0.1)!.withValues(alpha: 0.45),
      Color.lerp(fill, _pitch, 0.34)!.withValues(alpha: 0.55),
      Color.lerp(fill, _pitch, 0.74)!,
    ],
    stops: const [0, 0.34, 0.6, 1],
  ).createShader(rect);

  canvas
    ..drawRRect(
      outer.deflate(edge / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge
        ..shader = edgeShader
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, edge * 0.42),
    )
    // A crisper catch of light right on the lip.
    ..drawRRect(
      outer.deflate(1.3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sun.withValues(alpha: 0.58),
            Colors.transparent,
            _pitch.withValues(alpha: 0.55),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(rect),
    )
    ..restore();

  canvas.drawRRect(
    outer.deflate(0.7),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Color.lerp(outline, _pitch, controlled ? 0.25 : 0.45)!
          .withValues(alpha: controlled ? 0.9 : 0.7),
  );
}

void _paintGrain(
  Canvas canvas,
  Rect face,
  Color lit,
  Color dim,
  bool alongWidth,
  int seed,
) {
  final random = math.Random(seed * 2654435761 % 100003);
  final span = alongWidth ? face.width : face.height;
  final across = alongWidth ? face.height : face.width;
  final start = alongWidth ? face.left : face.top;
  final lines = math.max(4, (across / 6.5).round());

  for (var i = 0; i < lines; i++) {
    final dark = random.nextDouble() < 0.62;
    final base = (alongWidth ? face.top : face.left) +
        across * (i + 0.5) / lines +
        (random.nextDouble() - 0.5) * (across / lines) * 0.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = dark
          ? 0.8 + random.nextDouble() * 1.4
          : 0.7 + random.nextDouble() * 0.8
      ..color = (dark ? dim : lit).withValues(
        alpha: dark ? 0.18 + random.nextDouble() * 0.2 : 0.13,
      );

    final amp = across * (0.015 + random.nextDouble() * 0.045);
    final freq = 1.1 + random.nextDouble() * 2.1;
    final phase = random.nextDouble() * math.pi * 2;

    final path = Path();
    const steps = 20;
    for (var s = 0; s <= steps; s++) {
      final u = s / steps;
      final drift = math.sin(phase + u * math.pi * freq) * amp +
          math.sin(phase * 1.7 + u * math.pi * freq * 2.7) * amp * 0.3;
      final along = start + span * u;
      final point = alongWidth
          ? Offset(along, base + drift)
          : Offset(base + drift, along);
      if (s == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, paint);
  }
}
