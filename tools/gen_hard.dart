// Varied block sizes + choke puzzles for deeper thinking.
// 1) dart run tools/gen_hard.dart
// 2) flutter test tools/harden_levels_test.dart --reporter expanded

import 'dart:io';
import 'dart:math';

void main() {
  final rng = Random(2026072611);
  final seen = <String>{};
  final levels = <_Lev>[];

  for (final t in _teach()) {
    if (seen.add(t.map)) levels.add(t);
  }

  var attempts = 0;
  while (levels.length < 500 && attempts < 500000) {
    attempts++;
    final n = levels.length + 1;
    final lev = _candidate(rng, n);
    if (!seen.add(lev.map)) continue;
    levels.add(lev);
    if (levels.length % 50 == 0) {
      stdout.writeln('draft ${levels.length}/500');
    }
  }

  if (levels.length < 500) {
    stderr.writeln('Only ${levels.length}/500');
    exit(1);
  }

  File('assets/levels.yaml').writeAsStringSync(_yaml(levels));
  stdout.writeln('Wrote drafts → run flutter test tools/harden_levels_test.dart');
}

class _Lev {
  _Lev(this.map, {this.hint});
  final String map;
  final String? hint;
}

class _Grid {
  _Grid(this.cw, this.ch)
      : aw = cw * 2 + 1,
        ah = ch * 2 + 1,
        g = List.generate(ch * 2 + 1, (_) => List.filled(cw * 2 + 1, '.')),
        occ = <String>{} {
    for (var x = 0; x < aw; x++) {
      g[0][x] = '*';
      g[ah - 1][x] = '*';
    }
    for (var y = 0; y < ah; y++) {
      g[y][0] = '*';
      g[y][aw - 1] = '*';
    }
  }

  final int cw, ch, aw, ah;
  final List<List<String>> g;
  final Set<String> occ;

  bool canPlace(int cx, int cy, int bw, int bh) {
    if (cx < 0 || cy < 0 || cx + bw > cw || cy + bh > ch) return false;
    for (var y = cy; y < cy + bh; y++) {
      for (var x = cx; x < cx + bw; x++) {
        if (occ.contains('$x,$y')) return false;
      }
    }
    return true;
  }

  void mark(int cx, int cy, int bw, int bh) {
    for (var y = cy; y < cy + bh; y++) {
      for (var x = cx; x < cx + bw; x++) {
        occ.add('$x,$y');
      }
    }
  }

  void paint(int cx, int cy, int bw, int bh, String ch_) {
    final ax0 = cx * 2 + 1;
    final ay0 = cy * 2 + 1;
    final ax1 = (cx + bw - 1) * 2 + 1;
    final ay1 = (cy + bh - 1) * 2 + 1;
    for (var ay = ay0; ay <= ay1; ay++) {
      for (var ax = ax0; ax <= ax1; ax++) {
        g[ay][ax] = ch_;
      }
    }
    mark(cx, cy, bw, bh);
  }

  /// Right-side exit spanning [row..row+h)
  void exitRight(int row, int h) {
    for (var i = 0; i < h; i++) {
      final y = (row + i) * 2 + 1;
      if (y > 0 && y < ah - 1) g[y][aw - 1] = 'e';
    }
  }

  void exitBottom(int col, int w) {
    for (var i = 0; i < w; i++) {
      final x = (col + i) * 2 + 1;
      if (x > 0 && x < aw - 1) g[ah - 1][x] = 'e';
    }
  }

  void exitLeft(int row, int h) {
    for (var i = 0; i < h; i++) {
      final y = (row + i) * 2 + 1;
      if (y > 0 && y < ah - 1) g[y][0] = 'e';
    }
  }

  void exitTop(int col, int w) {
    for (var i = 0; i < w; i++) {
      final x = (col + i) * 2 + 1;
      if (x > 0 && x < aw - 1) g[0][x] = 'e';
    }
  }

  void wallDot(int wx, int wy) {
    if (wy <= 0 || wx <= 0 || wy >= ah - 1 || wx >= aw - 1) return;
    if (g[wy][wx] == '.') g[wy][wx] = '*';
  }

  String dump() => g.map((r) => r.join()).join('\n');
}

List<_Lev> _teach() => [
      _Lev(
        '*********\n'
        '*M.x....e\n'
        '*.......*\n'
        '*.......*\n'
        '*********',
        hint: 'Clear the small blocker, then escape.',
      ),
      _Lev(
        '*********\n'
        '*M.xxx..e\n'
        '*.......*\n'
        '*.......*\n'
        '*.......*\n'
        '*********',
        hint: 'Long blocks need parking space before you can pass.',
      ),
      _Lev(
        '*********\n'
        '*MM.x...e\n'
        '*MM.....*\n'
        '*.......*\n'
        '*.......*\n'
        '*********',
        hint: 'Big main needs a clear exit lane matching its size.',
      ),
      _Lev(
        '***********\n'
        '*M.x......*\n'
        '*..xxx....*\n'
        '*.........*\n'
        '*........xe\n'
        '*.........*\n'
        '***********',
        hint: 'Slide the long bar out of the way first.',
      ),
      _Lev(
        '*********\n'
        '*X.xx...*\n'
        '*.......*\n'
        '*mm.....*\n'
        '*mm....xe\n'
        '*.......*\n'
        '*********',
        hint: 'Transfer to the big main, then carve a path out.',
      ),
      _Lev(
        '***********\n'
        '*M..*.*.*.e\n'
        '*xx.*...*.*\n'
        '*.........*\n'
        '*.*.*.*.*.*\n'
        '*....xxx..*\n'
        '***********',
        hint: 'Rooms and fat blockers — order matters.',
      ),
      _Lev(
        '*********\n'
        '*xxx....e\n'
        '*xxx....*\n'
        '*.......*\n'
        '*M......*\n'
        '*.......*\n'
        '*********',
      ),
      _Lev(
        '***********\n'
        '*..x.MM.x.*\n'
        '*....MM...*\n'
        '*.*.*.*.*.*\n'
        '*........xe\n'
        '*.........*\n'
        '***********',
      ),
    ];

_Lev _candidate(Random rng, int n) {
  final band = n <= 40
      ? 0
      : n <= 120
          ? 1
          : n <= 250
              ? 2
              : n <= 380
                  ? 3
                  : 4;

  final cw = [5, 5, 6, 6, 7][band] + rng.nextInt(2);
  final ch = [4, 5, 5, 6, 6][band] + rng.nextInt(2);
  final grid = _Grid(cw, ch);

  // Main size grows with difficulty (still often 1x1 early)
  var mainW = 1;
  var mainH = 1;
  final sizeRoll = rng.nextDouble();
  if (n > 15 && sizeRoll < 0.35) {
    if (rng.nextBool()) {
      mainW = 2;
    } else {
      mainH = 2;
    }
  }
  if (n > 80 && sizeRoll < 0.18) {
    mainW = 2;
    mainH = 2;
  }
  if (n > 200 && sizeRoll < 0.08) {
    mainW = 3;
    mainH = 1 + rng.nextInt(2);
  }

  final side = n < 20 ? 0 : rng.nextInt(4);
  final pattern = rng.nextInt(5); // 0 lane-block, 1 off-row, 2 parking, 3 transfer, 4 maze

  late int mainCx, mainCy;

  switch (side) {
    case 0: // right exit
      final ey = rng.nextInt(max(1, ch - mainH + 1));
      grid.exitRight(ey, mainH);
      if (pattern == 0 || pattern == 2) {
        mainCy = ey;
        mainCx = 0;
        grid.paint(mainCx, mainCy, mainW, mainH, 'M');
        // Long horizontal blockers on exit lane (classic rush-hour feel)
        _placeLaneBlockers(rng, grid, band,
            horizontal: true, lane: ey, from: mainW, to: cw - 1);
      } else {
        mainCy = (ey + mainH + rng.nextInt(max(1, ch - mainH))) %
            max(1, ch - mainH + 1);
        mainCx = rng.nextInt(max(1, (cw / 2).floor()));
        if (!grid.canPlace(mainCx, mainCy, mainW, mainH)) {
          mainCx = 0;
          mainCy = ey;
        }
        grid.paint(mainCx, mainCy, mainW, mainH, 'M');
        // Guard near exit with long piece
        final gw = 1 + rng.nextInt(1 + min(2, band + 1));
        final gx = max(0, cw - gw);
        if (grid.canPlace(gx, ey, gw, 1)) {
          grid.paint(gx, ey, gw, 1, 'x');
        }
      }
      break;
    case 1: // bottom
      final ex = rng.nextInt(max(1, cw - mainW + 1));
      grid.exitBottom(ex, mainW);
      mainCx = pattern == 0 ? ex : rng.nextInt(max(1, cw - mainW + 1));
      mainCy = 0;
      grid.paint(mainCx, mainCy, mainW, mainH, 'M');
      _placeLaneBlockers(rng, grid, band,
          horizontal: false, lane: ex, from: mainH, to: ch - 1);
      break;
    case 2: // left
      final ey = rng.nextInt(max(1, ch - mainH + 1));
      grid.exitLeft(ey, mainH);
      mainCy = ey;
      mainCx = max(0, cw - mainW);
      grid.paint(mainCx, mainCy, mainW, mainH, 'M');
      _placeLaneBlockers(rng, grid, band,
          horizontal: true, lane: ey, from: 0, to: mainCx);
      break;
    default: // top
      final ex = rng.nextInt(max(1, cw - mainW + 1));
      grid.exitTop(ex, mainW);
      mainCx = ex;
      mainCy = max(0, ch - mainH);
      grid.paint(mainCx, mainCy, mainW, mainH, 'M');
      _placeLaneBlockers(rng, grid, band,
          horizontal: false, lane: ex, from: 0, to: mainCy);
      break;
  }

  // Mix of fat / long decoys in free space
  final extras = [1, 2, 3, 3, 4][band] + rng.nextInt(2);
  var placed = 0;
  for (var t = 0; t < 120 && placed < extras; t++) {
    final shape = _randomShape(rng, band);
    final cx = rng.nextInt(cw);
    final cy = rng.nextInt(ch);
    if (!grid.canPlace(cx, cy, shape[0], shape[1])) continue;
    grid.paint(cx, cy, shape[0], shape[1], 'x');
    placed++;
  }

  // Corridor walls
  final walls = [1, 1, 2, 3, 3][band] + rng.nextInt(2);
  for (var i = 0; i < walls; i++) {
    if (rng.nextBool() && cw > 1) {
      grid.wallDot(2 * (1 + rng.nextInt(cw - 1)), 1 + 2 * rng.nextInt(ch));
    } else if (ch > 1) {
      grid.wallDot(1 + 2 * rng.nextInt(cw), 2 * (1 + rng.nextInt(ch - 1)));
    }
  }

  // Start-on-helper twist
  if (n > 35 && pattern == 3 && placed > 0) {
    // demote M→m across painted main
    for (var y = 1; y < grid.ah; y++) {
      for (var x = 1; x < grid.aw; x++) {
        if (grid.g[y][x] == 'M') grid.g[y][x] = 'm';
      }
    }
    outer:
    for (var y = 1; y < grid.ah; y += 2) {
      for (var x = 1; x < grid.aw; x += 2) {
        if (grid.g[y][x] == 'x') {
          // promote whole connected? top-left only matters for control flag on first cell
          // Paint just this cell X - for multi block need top-left
          // Find block top-left by scanning
          grid.g[y][x] = 'X';
          // If this is mid of a multi block, fix: uppercase whole rect's top-left only
          break outer;
        }
      }
    }
  }

  // Salt
  for (var i = 0; i < 1 + rng.nextInt(3); i++) {
    final wx = 1 + rng.nextInt(max(1, grid.aw - 2));
    final wy = 1 + rng.nextInt(max(1, grid.ah - 2));
    if (wx.isOdd && wy.isOdd) continue;
    grid.wallDot(wx, wy);
  }

  _ensureControl(grid);

  String? hint;
  if (n == 18) {
    hint = 'Long bars park sideways — make a bay, then slide.';
  }
  if (n == 45) {
    hint = 'Big mains need matching exit width. Plan the lane.';
  }
  if (n == 100) {
    hint = 'Fat blockers + tight corridors = think two moves ahead.';
  }

  return _Lev(grid.dump(), hint: hint);
}

void _placeLaneBlockers(
  Random rng,
  _Grid grid,
  int band, {
  required bool horizontal,
  required int lane,
  required int from,
  required int to,
}) {
  if (to - from < 1) return;
  final count = 1 + rng.nextInt(1 + min(2, band + 1));
  for (var i = 0; i < count; i++) {
    if (horizontal) {
      final len = 1 + rng.nextInt(1 + min(3, band + 1));
      final maxStart = max(from, to - len);
      if (maxStart < from) continue;
      final bx = from + rng.nextInt(max(1, maxStart - from + 1));
      if (grid.canPlace(bx, lane, len, 1)) {
        grid.paint(bx, lane, len, 1, 'x');
      }
    } else {
      final len = 1 + rng.nextInt(1 + min(3, band + 1));
      final maxStart = max(from, to - len);
      if (maxStart < from) continue;
      final by = from + rng.nextInt(max(1, maxStart - from + 1));
      if (grid.canPlace(lane, by, 1, len)) {
        grid.paint(lane, by, 1, len, 'x');
      }
    }
  }
}

List<int> _randomShape(Random rng, int band) {
  final roll = rng.nextDouble();
  if (roll < 0.45) return [1, 1];
  if (roll < 0.65) return rng.nextBool() ? [2, 1] : [1, 2];
  if (roll < 0.80) return rng.nextBool() ? [3, 1] : [1, 3];
  if (roll < 0.92 && band >= 1) return [2, 2];
  if (band >= 2 && roll < 0.97) return rng.nextBool() ? [3, 2] : [2, 3];
  return [1, 1];
}

void _ensureControl(_Grid grid) {
  var hasCtrl = false;
  var hasMain = false;
  for (final row in grid.g) {
    for (final c in row) {
      if (c == 'M' || c == 'X') hasCtrl = true;
      if (c.toLowerCase() == 'm') hasMain = true;
    }
  }
  if (!hasMain) {
    // emergency 1x1
    for (var cy = 0; cy < grid.ch; cy++) {
      for (var cx = 0; cx < grid.cw; cx++) {
        if (grid.canPlace(cx, cy, 1, 1)) {
          grid.paint(cx, cy, 1, 1, 'M');
          return;
        }
      }
    }
  }
  if (!hasCtrl) {
    for (var y = 1; y < grid.ah; y += 2) {
      for (var x = 1; x < grid.aw; x += 2) {
        if (grid.g[y][x] == 'm') {
          grid.g[y][x] = 'M';
          return;
        }
      }
    }
  }
}

String _yaml(List<_Lev> levels) {
  final buf = StringBuffer();
  buf.writeln('- name: Adventure');
  buf.writeln('  description: Climb the path — think before you slide');
  buf.writeln('  levels:');
  for (var i = 0; i < levels.length; i++) {
    buf.writeln('    - name: "${i + 1}"');
    final h = levels[i].hint;
    if (h != null) {
      buf.writeln('      hint: |-');
      buf.writeln('        $h');
    }
    buf.writeln('      map: |-');
    for (final row in levels[i].map.split('\n')) {
      buf.writeln('        $row');
    }
    buf.writeln();
  }
  return buf.toString();
}
