// Fix invalid maps in assets/levels.yaml (odd size, main, control).
// Run: dart run tools/fix_levels.dart

import 'dart:io';

void main() {
  final file = File('assets/levels.yaml');
  final raw = file.readAsStringSync().replaceAll('\r\n', '\n');
  final lines = raw.split('\n');

  final out = StringBuffer();
  final mapBuf = StringBuffer();
  var inMap = false;
  var fixed = 0;
  var totalMaps = 0;
  var stillBad = 0;

  void flushMap() {
    if (!inMap) return;
    totalMaps++;
    final original = mapBuf.toString().trimRight();
    final repaired = repairMap(original);
    if (repaired != original) fixed++;
    final check = validate(repaired);
    if (check != null) {
      stillBad++;
      stderr.writeln('STILL BAD after repair: $check');
      stderr.writeln(repaired);
    }
    for (final row in repaired.split('\n')) {
      out.writeln('        $row');
    }
    mapBuf.clear();
    inMap = false;
  }

  for (final line in lines) {
    if (RegExp(r'^      map:').hasMatch(line)) {
      flushMap();
      out.writeln(line);
      inMap = true;
      continue;
    }
    if (inMap) {
      if (line.startsWith('        ')) {
        mapBuf.writeln(line.substring(8));
        continue;
      }
      if (line.trim().isEmpty) {
        // ignore blank inside map
        continue;
      }
      flushMap();
      out.writeln(line);
      continue;
    }
    out.writeln(line);
  }
  flushMap();

  file.writeAsStringSync(out.toString());
  stdout.writeln(
      'Done. maps=$totalMaps fixed=$fixed stillBad=$stillBad → ${file.path}');
}

String? validate(String map) {
  final rows = map.split('\n').where((r) => r.isNotEmpty).toList();
  if (rows.isEmpty) return 'empty';
  final w = rows.first.length;
  final h = rows.length;
  if (rows.any((r) => r.length != w)) return 'uneven';
  if (w % 2 == 0 || h % 2 == 0) return 'even ${w}x$h';
  final flat = rows.join();
  if (!flat.contains('m') && !flat.contains('M')) return 'noMain';
  if (!RegExp(r'[A-Z]').hasMatch(flat)) return 'noCtrl';
  if (!flat.contains('e') && !flat.contains('E')) return 'noExit';
  return null;
}

String repairMap(String map) {
  var rows = map
      .split('\n')
      .map((r) => r.trimRight())
      .where((r) => r.isNotEmpty)
      .toList();
  if (rows.isEmpty) {
    return '*****\n*M..e\n*****';
  }

  // Equalize width
  var w = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  rows = rows.map((r) => r.padRight(w, '*')).toList();

  // Make width odd — pad on the side that is NOT an exit edge when possible.
  if (w.isEven) {
    final exitOnRight = rows.any((r) => r.endsWith('e') || r.endsWith('E'));
    final exitOnLeft = rows.any((r) => r.startsWith('e') || r.startsWith('E'));
    if (exitOnRight && !exitOnLeft) {
      rows = rows.map((r) => '*$r').toList();
    } else if (exitOnLeft && !exitOnRight) {
      rows = rows.map((r) => '$r*').toList();
    } else {
      // default: pad left so right-edge exits stay on border
      rows = rows.map((r) => '*$r').toList();
    }
    w = rows.first.length;
  }

  // Make height odd
  var h = rows.length;
  if (h.isEven) {
    final exitOnBottom = rows.last.contains('e') || rows.last.contains('E');
    final exitOnTop = rows.first.contains('e') || rows.first.contains('E');
    final filler = '*' + ('.' * (w - 2)) + '*';
    final wall = '*' * w;
    if (exitOnBottom && !exitOnTop) {
      // insert interior row after top wall
      if (rows.length >= 2) {
        rows.insert(1, filler);
      } else {
        rows.insert(0, wall);
      }
    } else if (exitOnTop && !exitOnBottom) {
      if (rows.length >= 2) {
        rows.insert(rows.length - 1, filler);
      } else {
        rows.add(wall);
      }
    } else {
      // default: insert empty interior row before bottom border
      if (rows.length >= 2) {
        rows.insert(rows.length - 1, filler);
      } else {
        rows.add(wall);
      }
    }
    h = rows.length;
  }

  // Ensure controlled + main
  rows = ensureBlocks(rows);

  // Final safety: if somehow still even, force pad
  w = rows.first.length;
  h = rows.length;
  if (w.isEven) {
    rows = rows.map((r) => '*$r').toList();
  }
  if (rows.length.isEven) {
    rows.add('*' * rows.first.length);
  }

  return rows.join('\n');
}

List<String> ensureBlocks(List<String> rows) {
  final grid = rows.map((r) => r.split('')).toList();
  final h = grid.length;
  final w = grid.first.length;

  bool isBlockChar(String c) {
    final l = c.toLowerCase();
    return l == 'm' || l == 'x';
  }

  var mainCount = 0;
  var hasCtrl = false;
  for (final row in grid) {
    for (final c in row) {
      if (c.toLowerCase() == 'm') mainCount++;
      if (c == 'M' || c == 'X') hasCtrl = true;
    }
  }

  // Ensure exactly one main: convert extras m/M → x/X, or promote first x
  if (mainCount == 0) {
    outer:
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (grid[y][x] == 'x' || grid[y][x] == 'X') {
          grid[y][x] = grid[y][x] == 'X' ? 'M' : 'm';
          mainCount = 1;
          break outer;
        }
      }
    }
  } else if (mainCount > 1) {
    var seen = false;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final c = grid[y][x];
        if (c.toLowerCase() == 'm') {
          if (!seen) {
            seen = true;
          } else {
            grid[y][x] = c == 'M' ? 'X' : 'x';
          }
        }
      }
    }
  }

  // Recompute control
  hasCtrl = false;
  for (final row in grid) {
    for (final c in row) {
      if (c == 'M' || c == 'X') hasCtrl = true;
    }
  }
  if (!hasCtrl) {
    // Prefer promote main to M
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (grid[y][x] == 'm') {
          grid[y][x] = 'M';
          hasCtrl = true;
          break;
        }
      }
      if (hasCtrl) break;
    }
  }
  if (!hasCtrl) {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (grid[y][x] == 'x') {
          grid[y][x] = 'X';
          hasCtrl = true;
          break;
        }
      }
      if (hasCtrl) break;
    }
  }

  // Last resort: place M inside if no blocks at all
  if (!grid.any((r) => r.any(isBlockChar))) {
    final cy = (h ~/ 2).isOdd ? h ~/ 2 : (h ~/ 2) - 1;
    final cx = (w ~/ 2).isOdd ? w ~/ 2 : (w ~/ 2) - 1;
    final yy = cy.clamp(1, h - 2);
    final xx = cx.clamp(1, w - 2);
    grid[yy][xx] = 'M';
  }

  return grid.map((r) => r.join()).toList();
}
