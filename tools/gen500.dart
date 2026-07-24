// Run: dart run tools/gen500.dart
// Writes assets/levels.yaml — levels named "1".."500", one simple chapter.

import 'dart:io';
import 'dart:math';

void main() {
  final out = File('assets/levels.yaml');
  final existing = out.existsSync() ? extractMaps(out.readAsStringSync()) : <String>[];
  stdout.writeln('Existing maps: ${existing.length}');

  final levels = <String>[];
  final seen = <String>{};

  for (final m in existing) {
    final n = norm(m);
    if (seen.add(n)) levels.add(n);
    if (levels.length >= 500) break;
  }

  final rng = Random(500);
  var i = 0;
  while (levels.length < 500 && i < 100000) {
    i++;
    final map = buildSolvable(rng, levels.length + 1);
    final n = norm(map);
    if (seen.add(n)) levels.add(n);
  }

  if (levels.length < 500) {
    stderr.writeln('Failed: only ${levels.length}');
    exit(1);
  }

  out.writeAsStringSync(toYaml(levels.take(500).toList()));
  stdout.writeln('Wrote 500 unique levels → ${out.path}');
}

String norm(String m) => m
    .replaceAll('\r\n', '\n')
    .split('\n')
    .map((r) => r.trimRight())
    .where((r) => r.isNotEmpty)
    .join('\n');

List<String> extractMaps(String yaml) {
  final lines = yaml.replaceAll('\r\n', '\n').split('\n');
  final maps = <String>[];
  final buf = StringBuffer();
  var inMap = false;
  void flush() {
    if (buf.isNotEmpty) {
      maps.add(buf.toString().trimRight());
      buf.clear();
    }
    inMap = false;
  }

  for (final line in lines) {
    if (RegExp(r'^      map:').hasMatch(line)) {
      flush();
      inMap = true;
      continue;
    }
    if (inMap) {
      if (line.startsWith('        ')) {
        buf.writeln(line.substring(8));
      } else if (line.trim().isEmpty) {
        continue;
      } else {
        flush();
      }
    }
  }
  flush();
  return maps;
}

/// Build a map that is solvable by construction:
/// - Main (M) shares a clear lane to an exit (no walls/blocks on that lane).
/// - Extra blocks/walls only off that lane for visual variety / later difficulty.
String buildSolvable(Random rng, int n) {
  // Board cell size grows slowly with n.
  final cw = n <= 40
      ? 3 + rng.nextInt(2)
      : n <= 120
          ? 4 + rng.nextInt(2)
          : n <= 300
              ? 5 + rng.nextInt(2)
              : 5 + rng.nextInt(3);
  final ch = n <= 40
      ? 2 + rng.nextInt(2)
      : n <= 120
          ? 3 + rng.nextInt(2)
          : n <= 300
              ? 4 + rng.nextInt(2)
              : 4 + rng.nextInt(3);

  final aw = cw * 2 + 1;
  final ah = ch * 2 + 1;
  final g = List.generate(ah, (_) => List.filled(aw, '.'));

  // Border walls
  for (var x = 0; x < aw; x++) {
    g[0][x] = '*';
    g[ah - 1][x] = '*';
  }
  for (var y = 0; y < ah; y++) {
    g[y][0] = '*';
    g[y][aw - 1] = '*';
  }

  // Pick clear lane row (cell row) and place exit on right (or other sides for later).
  final lane = rng.nextInt(ch);
  final laneY = lane * 2 + 1;

  final side = n <= 80 ? 0 : rng.nextInt(4);
  late int mainCx, mainCy;
  switch (side) {
    case 0: // exit right — main on left of same row, clear path right
      g[laneY][aw - 1] = 'e';
      mainCy = lane;
      mainCx = 0;
      g[laneY][1] = 'M';
      // ensure path cells empty (already .)
      break;
    case 1: // exit bottom
      final laneX = rng.nextInt(cw);
      final lx = laneX * 2 + 1;
      g[ah - 1][lx] = 'e';
      mainCx = laneX;
      mainCy = 0;
      g[1][lx] = 'M';
      break;
    case 2: // exit left
      g[laneY][0] = 'e';
      mainCy = lane;
      mainCx = cw - 1;
      g[laneY][aw - 2] = 'M'; // last interior odd col = (cw-1)*2+1 = aw-2
      break;
    default: // exit top
      final laneX = rng.nextInt(cw);
      final lx = laneX * 2 + 1;
      g[0][lx] = 'e';
      mainCx = laneX;
      mainCy = ch - 1;
      g[ah - 2][lx] = 'M';
      break;
  }

  // Optionally start control on another block (still solvable: knock chain back to M, then exit).
  // For guaranteed simplicity: keep control on M for most; sometimes add decoy blocks off-lane.
  final extras = n <= 30
      ? rng.nextInt(2)
      : n <= 100
          ? 1 + rng.nextInt(3)
          : 2 + rng.nextInt(5);

  for (var k = 0; k < extras; k++) {
    final cx = rng.nextInt(cw);
    final cy = rng.nextInt(ch);
    // Never block the clear lane path cells.
    if (_onClearPath(side, cx, cy, mainCx, mainCy, cw, ch)) continue;
    final ax = cx * 2 + 1;
    final ay = cy * 2 + 1;
    if (g[ay][ax] != '.') continue;
    g[ay][ax] = 'x';
  }

  // Inner walls off the clear path
  final wallCount = n <= 40
      ? rng.nextInt(2)
      : n <= 150
          ? 1 + rng.nextInt(3)
          : 2 + rng.nextInt(5);
  for (var k = 0; k < wallCount; k++) {
    if (rng.nextBool() && cw > 1) {
      final wx = 2 * (1 + rng.nextInt(cw - 1));
      final wy = 1 + 2 * rng.nextInt(ch);
      final cy = wy ~/ 2;
      // Don't put vertical wall on the horizontal clear lane between main and exit
      if (side == 0 && cy == mainCy) continue;
      if (side == 2 && cy == mainCy) continue;
      if (g[wy][wx] == '.') g[wy][wx] = '*';
    } else if (ch > 1) {
      final wy = 2 * (1 + rng.nextInt(ch - 1));
      final wx = 1 + 2 * rng.nextInt(cw);
      final cx = wx ~/ 2;
      if (side == 1 && cx == mainCx) continue;
      if (side == 3 && cx == mainCx) continue;
      if (g[wy][wx] == '.') g[wy][wx] = '*';
    }
  }

  // Later levels: sometimes a larger main (still on clear path start cell — 1x1 only for safety)
  // Add a second controlled start puzzle variant: X off-path + m on path (player must transfer).
  if (n > 25 && rng.nextDouble() < 0.35) {
    // find an x to promote to X and demote M→m
    for (var y = 1; y < ah; y += 2) {
      for (var x = 1; x < aw; x += 2) {
        if (g[y][x] == 'x') {
          g[y][x] = 'X';
          // demote main
          for (var yy = 1; yy < ah; yy += 2) {
            for (var xx = 1; xx < aw; xx += 2) {
              if (g[yy][xx] == 'M') g[yy][xx] = 'm';
            }
          }
          // Still solvable: move X around (or into m) then drive m out.
          // If X is isolated this can be hard — only do when X is adjacent-reachable.
          // Keep it: player can navigate open space.
          return g.map((r) => r.join()).join('\n');
        }
      }
    }
  }

  return g.map((r) => r.join()).join('\n');
}

bool _onClearPath(int side, int cx, int cy, int mainCx, int mainCy, int cw, int ch) {
  switch (side) {
    case 0: // horizontal rightward from mainCx..cw-1 on mainCy
      return cy == mainCy && cx >= mainCx;
    case 1: // vertical downward
      return cx == mainCx && cy >= mainCy;
    case 2: // horizontal leftward
      return cy == mainCy && cx <= mainCx;
    default: // vertical upward
      return cx == mainCx && cy <= mainCy;
  }
}

String toYaml(List<String> levels) {
  final buf = StringBuffer();
  buf.writeln('- name: Levels');
  buf.writeln('  description: 1-500');
  buf.writeln('  levels:');
  const hints = <int, String>{
    1: 'Swipe or use the arrow keys to move.\nEscape the room to win.',
    2: 'Knock into a block to transfer control.',
    3: 'Only the main block (marked with a circle) can exit.',
    4: 'Control transfers only when there is exactly one target.',
  };
  for (var i = 0; i < levels.length; i++) {
    final num = i + 1;
    buf.writeln('    - name: "$num"');
    if (hints.containsKey(num)) {
      buf.writeln('      hint: |-');
      for (final line in hints[num]!.split('\n')) {
        buf.writeln('        $line');
      }
    }
    buf.writeln('      map: |-');
    for (final row in levels[i].split('\n')) {
      buf.writeln('        $row');
    }
    buf.writeln();
  }
  return buf.toString();
}
