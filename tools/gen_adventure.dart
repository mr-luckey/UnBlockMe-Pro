// Generates 500 unique, solvable adventure levels.
// Run: dart run tools/gen_adventure.dart
// Then: flutter test tools/ensure_solvable_test.dart

import 'dart:io';
import 'dart:math';

void main() {
  final rng = Random(26072026);
  final seen = <String>{};
  final levels = <_Level>[];

  for (final hand in _tutorials()) {
    if (seen.add(hand.map)) levels.add(hand);
  }

  var attempts = 0;
  while (levels.length < 500 && attempts < 300000) {
    attempts++;
    final n = levels.length + 1;
    final built = _build(rng, n);
    if (!seen.add(built.map)) continue;
    levels.add(built);
    if (levels.length % 50 == 0) stdout.writeln('Progress ${levels.length}/500');
  }

  if (levels.length < 500) {
    stderr.writeln('Only ${levels.length}/500');
    exit(1);
  }

  File('assets/levels.yaml')
      .writeAsStringSync(_toYaml(levels.take(500).toList()));
  stdout.writeln('Wrote 500 adventure levels (pre-solver filter)');
}

class _Level {
  _Level(this.map, {this.hint});
  final String map;
  final String? hint;
}

List<_Level> _tutorials() => [
      _Level('*******\n*M....e\n*******',
          hint: 'Swipe to move. Guide the circled block out the exit.'),
      _Level('*******\n*M.x..e\n*.....*\n*.....*\n*******',
          hint: 'Bump into another block to take control of it.'),
      _Level('*******\n*x.M..e\n*.....*\n*.....*\n*******',
          hint: 'Only the main block (circle) can escape.'),
      _Level('*********\n*M.x.x..e\n*.......*\n*.......*\n*********',
          hint: 'Control transfers only when exactly one block is ahead.'),
      _Level(
          '*********\n*M......*\n*...*.*.*\n*......xe\n*.......*\n*.......*\n*********',
          hint: 'Walls force clever routes — keep the exit lane clear.'),
      _Level('*********\n*M..*.*.e\n*...*...*\n*.......*\n*********',
          hint: 'Find the gap through the walls.'),
      _Level(
          '*********\n*M.x.x..*\n*.......*\n*......xe\n*.......*\n*.......*\n*********'),
      _Level(
          '***********\n*M........*\n*.*.*.*.*.*\n*.........*\n*.*.*.*.*.e\n*.........*\n***********'),
    ];

_Level _build(Random rng, int n) {
  final band = n <= 50
      ? 0
      : n <= 150
          ? 1
          : n <= 300
              ? 2
              : n <= 420
                  ? 3
                  : 4;

  final cw = 3 + rng.nextInt(4); // 3..6
  final ch = 3 + rng.nextInt(4); // 3..6

  // Exit side twist (still keeps a clear lane for main)
  final side = n < 30 ? 0 : rng.nextInt(4); // 0R 1B 2L 3T

  final aw = cw * 2 + 1;
  final ah = ch * 2 + 1;
  final g = List.generate(ah, (_) => List.filled(aw, '.'));
  for (var x = 0; x < aw; x++) {
    g[0][x] = '*';
    g[ah - 1][x] = '*';
  }
  for (var y = 0; y < ah; y++) {
    g[y][0] = '*';
    g[y][aw - 1] = '*';
  }

  late int mainCx, mainCy;

  switch (side) {
    case 0:
      mainCy = rng.nextInt(ch);
      mainCx = 0;
      g[mainCy * 2 + 1][aw - 1] = 'e';
      // wide gate twist
      if (n > 40 && mainCy + 1 < ch && rng.nextBool()) {
        g[(mainCy + 1) * 2 + 1][aw - 1] = 'e';
      }
      g[mainCy * 2 + 1][1] = 'M';
      break;
    case 1:
      mainCx = rng.nextInt(cw);
      mainCy = 0;
      g[ah - 1][mainCx * 2 + 1] = 'e';
      g[1][mainCx * 2 + 1] = 'M';
      break;
    case 2:
      mainCy = rng.nextInt(ch);
      mainCx = cw - 1;
      g[mainCy * 2 + 1][0] = 'e';
      g[mainCy * 2 + 1][aw - 2] = 'M';
      break;
    default:
      mainCx = rng.nextInt(cw);
      mainCy = ch - 1;
      g[0][mainCx * 2 + 1] = 'e';
      g[ah - 2][mainCx * 2 + 1] = 'M';
      break;
  }

  bool onClear(int cx, int cy) {
    switch (side) {
      case 0:
        return cy == mainCy && cx >= mainCx;
      case 1:
        return cx == mainCx && cy >= mainCy;
      case 2:
        return cy == mainCy && cx <= mainCx;
      default:
        return cx == mainCx && cy <= mainCy;
    }
  }

  bool nearBlock(int cx, int cy) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= cw || ny >= ch) continue;
        final c = g[ny * 2 + 1][nx * 2 + 1].toLowerCase();
        if (c == 'm' || c == 'x') return true;
      }
    }
    return false;
  }

  final extras = [1, 2, 3, 4, 5][band] + rng.nextInt(2);
  var placed = 0;
  for (var t = 0; t < 100 && placed < extras; t++) {
    final cx = rng.nextInt(cw);
    final cy = rng.nextInt(ch);
    if (onClear(cx, cy)) continue;
    if (g[cy * 2 + 1][cx * 2 + 1] != '.') continue;
    if (nearBlock(cx, cy)) continue;
    g[cy * 2 + 1][cx * 2 + 1] = 'x';
    placed++;
  }

  // Walls off the clear lane (fun pockets / corridors)
  final wallN = [0, 1, 2, 3, 4][band] + rng.nextInt(band == 0 ? 1 : 2);
  for (var i = 0; i < wallN; i++) {
    if (rng.nextBool() && cw > 1) {
      final wx = 2 * (1 + rng.nextInt(cw - 1));
      final wy = 1 + 2 * rng.nextInt(ch);
      if ((side == 0 || side == 2) && wy ~/ 2 == mainCy) continue;
      if (g[wy][wx] == '.') g[wy][wx] = '*';
    } else if (ch > 1) {
      final wy = 2 * (1 + rng.nextInt(ch - 1));
      final wx = 1 + 2 * rng.nextInt(cw);
      if ((side == 1 || side == 3) && wx ~/ 2 == mainCx) continue;
      if (g[wy][wx] == '.') g[wy][wx] = '*';
    }
  }

  // Mirror decoys (off path only)
  if (n > 80 && rng.nextDouble() < 0.35) {
    for (var cy = 0; cy < ch; cy++) {
      for (var cx = 0; cx < cw; cx++) {
        if (g[cy * 2 + 1][cx * 2 + 1] != 'x') continue;
        final mx = cw - 1 - cx;
        final my = ch - 1 - cy;
        if (onClear(mx, my)) continue;
        if (g[my * 2 + 1][mx * 2 + 1] != '.') continue;
        if (nearBlock(mx, my)) continue;
        g[my * 2 + 1][mx * 2 + 1] = 'x';
      }
    }
  }

  // Sprinkle unique salt: isolated wall dots off-path so maps don't collide.
  for (var i = 0; i < 2 + rng.nextInt(4); i++) {
    final wx = 1 + rng.nextInt(max(1, aw - 2));
    final wy = 1 + rng.nextInt(max(1, ah - 2));
    if (wx.isOdd && wy.isOdd) continue; // don't overwrite blocks
    if ((side == 0 || side == 2) && wy ~/ 2 == mainCy && wy.isOdd) continue;
    if ((side == 1 || side == 3) && wx ~/ 2 == mainCx && wx.isOdd) continue;
    if (g[wy][wx] == '.') g[wy][wx] = '*';
  }

  final map = g.map((r) => r.join()).join('\n');
  String? hint;
  if (n == 20) hint = 'Try different exit sides — left, right, top, bottom.';
  if (n == 60) hint = 'Decoys look busy, but your escape lane stays open.';
  if (n == 120) hint = 'Mirrored rooms: style over stress — keep moving.';

  return _Level(map, hint: hint);
}

String _toYaml(List<_Level> levels) {
  final buf = StringBuffer();
  buf.writeln('- name: Adventure');
  buf.writeln('  description: Climb the path — escape every room');
  buf.writeln('  levels:');
  for (var i = 0; i < levels.length; i++) {
    buf.writeln('    - name: "${i + 1}"');
    final hint = levels[i].hint;
    if (hint != null) {
      buf.writeln('      hint: |-');
      buf.writeln('        $hint');
    }
    buf.writeln('      map: |-');
    for (final row in levels[i].map.split('\n')) {
      buf.writeln('        $row');
    }
    buf.writeln();
  }
  return buf.toString();
}
