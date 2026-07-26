// Rebuild any map that fails parseLevel rules.
// Run: flutter test tools/rebuild_bad_maps_test.dart --reporter expanded

import 'dart:io';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rebuild invalid maps in levels.yaml', () {
    final file = File('assets/levels.yaml');
    final raw = file.readAsStringSync().replaceAll('\r\n', '\n');
    final lines = raw.split('\n');

    final out = StringBuffer();
    final mapBuf = StringBuffer();
    String? currentName;
    var inMap = false;
    var rebuilt = 0;
    var kept = 0;
    var total = 0;
    final seen = <String>{};

    void flush() {
      if (!inMap) return;
      total++;
      var map = mapBuf.toString().trimRight();
      map = normalizeParityAndBlocks(map);
      if (!_parses(map) || !seen.add(map)) {
        map = uniqueValidMap(currentName ?? '$total', seen);
        rebuilt++;
      } else {
        kept++;
      }
      for (final row in map.split('\n')) {
        out.writeln('        $row');
      }
      mapBuf.clear();
      inMap = false;
    }

    for (final line in lines) {
      final nm = RegExp(r'^    - name: (.+)$').firstMatch(line);
      if (nm != null) {
        flush();
        currentName = nm.group(1)!.trim().replaceAll('"', '');
        out.writeln(line);
        continue;
      }
      if (RegExp(r'^      map:').hasMatch(line)) {
        flush();
        out.writeln(line);
        inMap = true;
        continue;
      }
      if (inMap) {
        if (line.startsWith('        ')) {
          mapBuf.writeln(line.substring(8));
          continue;
        }
        if (line.trim().isEmpty) continue;
        flush();
        out.writeln(line);
        continue;
      }
      out.writeln(line);
    }
    flush();

    file.writeAsStringSync(out.toString());

    // Final verification
    final verify = extractMaps(file.readAsStringSync());
    final failures = <String>[];
    for (final e in verify.entries) {
      if (!_parses(e.value)) failures.add(e.key);
    }

    print('total=$total kept=$kept rebuilt=$rebuilt failures=${failures.length}');
    expect(failures, isEmpty, reason: failures.take(20).join(', '));
    expect(verify.length, 1000);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

bool _parses(String map) {
  try {
    final state = parseLevel(map);
    return state.blocks.where((b) => b.isMain).length == 1 &&
        state.blocks.any((b) => b.hasControl);
  } catch (_) {
    return false;
  }
}

Map<String, String> extractMaps(String yaml) {
  final lines = yaml.replaceAll('\r\n', '\n').split('\n');
  final maps = <String, String>{};
  String? name;
  final buf = StringBuffer();
  var inMap = false;
  void flush() {
    if (name != null && buf.isNotEmpty) {
      maps[name!] = buf.toString().trimRight();
      buf.clear();
    }
    inMap = false;
  }

  for (final line in lines) {
    final nm = RegExp(r'^    - name: (.+)$').firstMatch(line);
    if (nm != null) {
      flush();
      name = nm.group(1)!.trim().replaceAll('"', '');
      continue;
    }
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

/// Keep walls/exits; move all blocks onto odd-odd cells with separation.
String normalizeParityAndBlocks(String map) {
  var rows = map
      .split('\n')
      .map((r) => r.trimRight())
      .where((r) => r.isNotEmpty)
      .toList();
  if (rows.isEmpty) return uniqueValidMap('empty', {});

  var w = rows.map((r) => r.length).reduce(max);
  rows = rows.map((r) => r.padRight(w, '*')).toList();
  if (w.isEven) {
    rows = rows.map((r) => '*$r').toList();
    w++;
  }
  if (rows.length.isEven) {
    rows.insert(rows.length - 1, '*' + ('.' * (w - 2)) + '*');
  }

  final h = rows.length;
  final grid = rows.map((r) => r.split('')).toList();

  // Collect desired blocks (ignore parity), then clear them from grid.
  var wantMainCtrl = true;
  var extra = 0;
  for (final row in grid) {
    for (final c in row) {
      if (c == 'M') {
        wantMainCtrl = true;
      } else if (c == 'm') {
        // main without control preference
      } else if (c == 'X' || c == 'x') {
        extra++;
      }
    }
  }
  extra = extra.clamp(0, 6);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = grid[y][x].toLowerCase();
      if (c == 'm' || c == 'x') {
        // don't erase border exits/walls incorrectly — only blocks
        if (y == 0 || x == 0 || y == h - 1 || x == w - 1) {
          grid[y][x] = (grid[y][x] == 'e' || rows[y][x] == 'e') ? 'e' : '*';
        } else {
          grid[y][x] = '.';
        }
      }
    }
  }

  // Candidate odd-odd interior cells that are empty and not walls
  final cells = <List<int>>[];
  for (var y = 1; y < h - 1; y += 2) {
    for (var x = 1; x < w - 1; x += 2) {
      if (grid[y][x] == '.' || grid[y][x] == ' ') {
        cells.add([x, y]);
      }
    }
  }
  if (cells.isEmpty) {
    return uniqueValidMap('fallback', {});
  }

  // Place main first
  final main = cells.removeAt(0);
  grid[main[1]][main[0]] = wantMainCtrl ? 'M' : 'M';

  // Place extras with no 4-adjacency to other blocks (avoid merge)
  var placed = 0;
  for (final cell in List<List<int>>.from(cells)) {
    if (placed >= extra) break;
    final x = cell[0];
    final y = cell[1];
    if (_nearBlock(grid, x, y)) continue;
    grid[y][x] = 'x';
    placed++;
    cells.remove(cell);
  }

  return grid.map((r) => r.join()).toList().join('\n');
}

bool _nearBlock(List<List<String>> g, int x, int y) {
  bool block(int xx, int yy) {
    if (yy < 0 || xx < 0 || yy >= g.length || xx >= g[yy].length) return false;
    final c = g[yy][xx].toLowerCase();
    return c == 'm' || c == 'x';
  }

  // Check orthogonal neighbors in tile space (including even gaps)
  for (var dy = -2; dy <= 2; dy++) {
    for (var dx = -2; dx <= 2; dx++) {
      if (dx == 0 && dy == 0) continue;
      if (dx.abs() + dy.abs() > 2) continue;
      if (block(x + dx, y + dy)) return true;
    }
  }
  return false;
}

String uniqueValidMap(String seed, Set<String> seen) {
  final rng = Random(seed.hashCode);
  for (var attempt = 0; attempt < 500; attempt++) {
    final cw = 3 + rng.nextInt(4); // 3..6 cells
    final ch = 2 + rng.nextInt(4); // 2..5 cells
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

    final lane = rng.nextInt(ch);
    final ly = lane * 2 + 1;
    g[ly][aw - 1] = 'e';
    g[ly][1] = 'M';

    final extras = rng.nextInt(4);
    var placed = 0;
    for (var t = 0; t < 40 && placed < extras; t++) {
      final cx = 1 + 2 * rng.nextInt(cw);
      final cy = 1 + 2 * rng.nextInt(ch);
      if (cy == ly && cx >= 1) continue; // keep clear lane
      if (g[cy][cx] != '.') continue;
      // avoid adjacency merge
      var near = false;
      for (var dy = -2; dy <= 2 && !near; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          if (dx == 0 && dy == 0) continue;
          if (dx.abs() + dy.abs() > 2) continue;
          final yy = cy + dy;
          final xx = cx + dx;
          if (yy < 0 || xx < 0 || yy >= ah || xx >= aw) continue;
          final c = g[yy][xx].toLowerCase();
          if (c == 'm' || c == 'x') near = true;
        }
      }
      if (near) continue;
      g[cy][cx] = 'x';
      placed++;
    }

    // a few inner walls on even lines off-lane
    for (var i = 0; i < rng.nextInt(3); i++) {
      if (cw > 1 && rng.nextBool()) {
        final wx = 2 * (1 + rng.nextInt(cw - 1));
        final wy = 1 + 2 * rng.nextInt(ch);
        if (wy != ly && g[wy][wx] == '.') g[wy][wx] = '*';
      }
    }

    final map = g.map((r) => r.join()).join('\n');
    if (seen.contains(map)) continue;
    if (_parses(map)) {
      seen.add(map);
      return map;
    }
  }
  // Absolute fallback
  const fallback = '*******\n*M....e\n*******';
  seen.add(fallback);
  return fallback;
}
