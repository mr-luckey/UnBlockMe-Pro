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
  double radius = 10,
  bool controlled = false,
}) {
  if (rect.width <= 0 || rect.height <= 0) return;

  final shortest = math.min(rect.width, rect.height);
  final chamfer = (shortest * 0.13).clamp(2.5, 9.0);
  final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  final face = rect.deflate(chamfer);
  if (face.width <= 0 || face.height <= 0) return;
  final inner = RRect.fromRectAndRadius(
    face,
    Radius.circular(math.max(2, radius - chamfer * 0.55)),
  );

  // Grain runs the length of the piece, the way a sawn plank would.
  final alongWidth = rect.width >= rect.height;

  final lit = Color.lerp(fill, _sun, 0.46)!;
  final dim = Color.lerp(fill, _pitch, 0.52)!;

  canvas
    ..save()
    ..clipRRect(outer);

  // Four cut faces around the top face. Corners fall where the quads meet, so
  // the chamfer mitres itself.
  void cut(Offset a, Offset b, Offset c, Offset d, Color color) {
    canvas.drawPath(
      Path()..addPolygon([a, b, c, d], true),
      Paint()..color = color,
    );
  }

  canvas.drawRRect(outer, Paint()..color = fill);
  cut(rect.topLeft, rect.topRight, face.topRight, face.topLeft,
      Color.lerp(lit, _sun, 0.16)!);
  cut(rect.topLeft, face.topLeft, face.bottomLeft, rect.bottomLeft,
      Color.lerp(fill, lit, 0.6)!);
  cut(rect.topRight, rect.bottomRight, face.bottomRight, face.topRight,
      Color.lerp(fill, dim, 0.7)!);
  cut(rect.bottomLeft, face.bottomLeft, face.bottomRight, rect.bottomRight,
      dim);

  // The top face carries a shallow barrel of light across the grain.
  canvas.drawRRect(
    inner,
    Paint()
      ..shader = LinearGradient(
        begin: alongWidth ? Alignment.topCenter : Alignment.centerLeft,
        end: alongWidth ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [
          Color.lerp(fill, lit, 0.72)!,
          Color.lerp(fill, lit, 0.26)!,
          fill,
          Color.lerp(fill, dim, 0.34)!,
        ],
        stops: const [0, 0.3, 0.64, 1],
      ).createShader(face),
  );

  canvas
    ..save()
    ..clipRRect(inner);
  _paintGrain(canvas, face, lit, dim, alongWidth, seed);
  // Diagonal sheen so the light direction matches the chamfer.
  canvas
    ..drawRect(
      face,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.15),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(face),
    )
    ..restore();

  // Hairline where the chamfer meets the face: bright on the lit side, dark on
  // the far side. This is what sells the step up out of the board.
  canvas
    ..drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _sun.withValues(alpha: 0.45),
            Colors.transparent,
            _pitch.withValues(alpha: 0.5),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(face),
    )
    ..restore();

  canvas.drawRRect(
    outer.deflate(0.8),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Color.lerp(outline, _pitch, controlled ? 0.2 : 0.4)!
          .withValues(alpha: controlled ? 0.95 : 0.75),
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
