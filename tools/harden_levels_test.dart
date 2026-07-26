// Filters drafts: keep solvable non-trivial maps; replace junk with
// multi-size template variants (fast — no 250x A* candidate hunt).
// Run: flutter test tools/harden_levels_test.dart --reporter expanded

import 'dart:io';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('harden all adventure levels', () async {
    File('tools/harden_progress.txt').writeAsStringSync('start');
    print('harden start');

    final file = File('assets/levels.yaml');
    final entries = _read(file.readAsStringSync());
    expect(entries.length, greaterThanOrEqualTo(400));
    print('loaded ${entries.length} levels');
    File('tools/harden_progress.txt').writeAsStringSync('loaded ${entries.length}');

    final seen = entries.map((e) => e.map).toSet();
    final rng = Random(4242);
    var replaced = 0;
    var kept = 0;

    for (var i = 0; i < entries.length; i++) {
      final n = i + 1;
      final minMoves = _minMoves(n);
      final cur = entries[i];

      if (i % 25 == 0) {
        final msg = 'progress $n/500 kept=$kept replaced=$replaced';
        print(msg);
        File('tools/harden_progress.txt').writeAsStringSync(msg);
      }

      // Always keep intentional teach maps
      if (n <= 8) {
        kept++;
        continue;
      }

      final moves = await _solveMoves(cur.map);
      final ok = moves != null && moves >= minMoves && moves <= _maxMoves(n);

      if (ok) {
        kept++;
        continue;
      }

      // Prefer a fresh multi-size candidate a few times, then template pool
      String? best;
      for (var t = 0; t < 12; t++) {
        final cand = _hardCandidate(rng, n);
        if (seen.contains(cand)) continue;
        final m = await _solveMoves(cand);
        if (m != null && m >= minMoves && m <= _maxMoves(n)) {
          best = cand;
          break;
        }
      }

      best ??= _templateVariant(rng, n, seen);
      seen.remove(cur.map);
      seen.add(best);
      entries[i] = _E(cur.name, best, cur.hint);
      replaced++;
    }

    file.writeAsStringSync(_yaml(entries));
    final done = 'DONE kept=$kept replaced=$replaced total=${entries.length}';
    print(done);
    File('tools/harden_progress.txt').writeAsStringSync(done);

    for (var i = 0; i < min(40, entries.length); i++) {
      final m = await _solveMoves(entries[i].map);
      expect(m, isNotNull, reason: 'level ${i + 1} unsolvable');
      expect(m! >= 2, isTrue, reason: 'level ${i + 1} too easy ($m)');
    }
  }, timeout: const Timeout(Duration(minutes: 40)));
}

int _minMoves(int n) {
  if (n <= 10) return 3;
  if (n <= 40) return 4;
  if (n <= 100) return 5;
  if (n <= 250) return 6;
  return 7;
}

int _maxMoves(int n) => n <= 40 ? 35 : 60;

class _E {
  _E(this.name, this.map, this.hint);
  final String name;
  final String map;
  final String? hint;
}

List<_E> _read(String yaml) {
  final lines = yaml.replaceAll('\r\n', '\n').split('\n');
  final out = <_E>[];
  String? name;
  String? hint;
  final mapBuf = StringBuffer();
  final hintBuf = StringBuffer();
  var inMap = false;
  var inHint = false;

  void flush() {
    if (name != null && mapBuf.isNotEmpty) {
      out.add(_E(
        name!,
        mapBuf.toString().trimRight(),
        hint ?? (hintBuf.isEmpty ? null : hintBuf.toString().trim()),
      ));
    }
    mapBuf.clear();
    hintBuf.clear();
    hint = null;
    inMap = false;
    inHint = false;
  }

  for (final line in lines) {
    final nm = RegExp(r'^    - name: "([^"]+)"').firstMatch(line);
    if (nm != null) {
      flush();
      name = nm.group(1);
      continue;
    }
    final hm = RegExp(r'^      hint: \|?-?\s*(.*)$').firstMatch(line);
    if (hm != null) {
      inHint = true;
      final rest = hm.group(1)!;
      if (rest.isNotEmpty) {
        hint = rest;
        inHint = false;
      }
      continue;
    }
    if (RegExp(r'^      map:').hasMatch(line)) {
      inHint = false;
      inMap = true;
      continue;
    }
    if (inHint && line.startsWith('        ')) {
      hintBuf.writeln(line.trim());
      continue;
    }
    if (inMap) {
      if (line.startsWith('        ')) {
        mapBuf.writeln(line.substring(8));
      } else if (line.trim().isEmpty) {
        continue;
      } else {
        flush();
      }
    }
  }
  flush();
  return out;
}

Future<int?> _solveMoves(String map) async {
  try {
    final state = parseLevel(map);
    return await _solve(state.puzzle, maxVisited: 18000);
  } catch (_) {
    return null;
  }
}

Future<int?> _solve(PuzzleState start, {required int maxVisited}) async {
  final frontier = PriorityQueue<_N>();
  final visited = <int>{};
  frontier.add(_N(start, 0, _hash(start)));

  while (frontier.isNotEmpty) {
    final cur = frontier.removeFirst();
    if (!visited.add(cur.hash)) continue;
    if (visited.length > maxVisited) return null;
    if (cur.state.isCompleted) return cur.g;
    for (final d in MoveDirection.values) {
      final next = cur.state.withMoveAttempt(MoveAttempt(d));
      final h = _hash(next);
      if (!visited.contains(h)) {
        frontier.add(_N(next, cur.g + 1, h));
      }
    }
  }
  return null;
}

int _hash(PuzzleState s) =>
    Object.hash(s.controlledBlock, Object.hashAllUnordered(s.blocks));

class _N implements Comparable<_N> {
  _N(this.state, this.g, this.hash);
  final PuzzleState state;
  final int g;
  final int hash;

  @override
  int compareTo(_N o) {
    final ha = _h(state);
    final hb = _h(o.state);
    return (g + ha).compareTo(o.g + hb);
  }
}

int _h(PuzzleState s) {
  final m = s.mainBlock;
  final c = s.controlledBlock;
  return (m.position.x - c.position.x).abs() +
      (m.position.y - c.position.y).abs() +
      min(m.position.x, s.width - 1 - m.position.x).toInt() +
      min(m.position.y, s.height - 1 - m.position.y).toInt();
}

/// Hand-tuned multi-size puzzles (solvable). Variants via salt walls / shift.
const _templates = <String>[
  // Long bar parking
  '*********\n'
      '*M.xxx..e\n'
      '*.......*\n'
      '*.......*\n'
      '*.......*\n'
      '*********',
  // Big 2x2 main
  '*********\n'
      '*MM.x...e\n'
      '*MM.....*\n'
      '*.......*\n'
      '*.......*\n'
      '*********',
  // Fat 2x2 blocker
  '***********\n'
      '*M..xx....e\n'
      '*...xx....*\n'
      '*.........*\n'
      '*....x....*\n'
      '*.........*\n'
      '***********',
  // Tall vertical guard
  '*********\n'
      '*M......e\n'
      '*....x..*\n'
      '*....x..*\n'
      '*....x..*\n'
      '*.......*\n'
      '*********',
  // Transfer + long
  '*********\n'
      '*X.xx...*\n'
      '*.......*\n'
      '*mm.....*\n'
      '*mm....xe\n'
      '*.......*\n'
      '*********',
  // 3-wide bar + bay
  '***********\n'
      '*M.xxx....e\n'
      '*.........*\n'
      '*....x....*\n'
      '*.........*\n'
      '*.........*\n'
      '***********',
  // Rooms
  '***********\n'
      '*M..*.*.*.e\n'
      '*xx.*...*.*\n'
      '*.........*\n'
      '*.*.*.*.*.*\n'
      '*....xxx..*\n'
      '***********',
  // Off-lane main, long guard
  '*********\n'
      '*.......e\n'
      '*....xxx*\n'
      '*M......*\n'
      '*.......*\n'
      '*.......*\n'
      '*********',
  // Dual long pieces
  '***********\n'
      '*M.xx..x..e\n'
      '*.........*\n'
      '*...xxx...*\n'
      '*.........*\n'
      '*.........*\n'
      '***********',
  // Tall main
  '*********\n'
      '*M.x....e\n'
      '*M......*\n'
      '*.......*\n'
      '*...xx..*\n'
      '*.......*\n'
      '*********',
  // Bottom exit style corridor
  '*********\n'
      '*M.x....*\n'
      '*.......*\n'
      '*..xxx..*\n'
      '*.......*\n'
      '*......e*\n'
      '*********',
  // Squeeze past 2x2
  '***********\n'
      '*MM.......e\n'
      '*MM.xx....*\n'
      '*...xx....*\n'
      '*.........*\n'
      '*....x....*\n'
      '***********',
];

String _templateVariant(Random rng, int n, Set<String> seen) {
  for (var attempt = 0; attempt < 40; attempt++) {
    final base = _templates[(n + attempt) % _templates.length];
    final rows = base.split('\n').map((r) => r.split('')).toList();
    // Salt a few even-cell walls if empty
    final ah = rows.length;
    final aw = rows[0].length;
    final salts = 1 + rng.nextInt(3);
    for (var s = 0; s < salts; s++) {
      final wy = 1 + rng.nextInt(max(1, ah - 2).toInt());
      final wx = 1 + rng.nextInt(max(1, aw - 2).toInt());
      if (wx.isOdd && wy.isOdd) continue;
      if (rows[wy][wx] == '.') rows[wy][wx] = '*';
    }
    final map = rows.map((r) => r.join()).join('\n');
    if (!seen.contains(map)) return map;
  }
  return _templates[n % _templates.length];
}

String _hardCandidate(Random rng, int n) {
  final band = n <= 40
      ? 0
      : n <= 120
          ? 1
          : n <= 250
              ? 2
              : 3;
  final cw = 5 + band + rng.nextInt(2);
  final ch = 4 + (band < 2 ? band : 2) + rng.nextInt(2);
  final aw = cw * 2 + 1;
  final ah = ch * 2 + 1;
  final g = List.generate(ah, (_) => List.filled(aw, '.'));
  final occ = <String>{};

  for (var x = 0; x < aw; x++) {
    g[0][x] = '*';
    g[ah - 1][x] = '*';
  }
  for (var y = 0; y < ah; y++) {
    g[y][0] = '*';
    g[y][aw - 1] = '*';
  }

  bool can(int cx, int cy, int bw, int bh) {
    if (cx < 0 || cy < 0 || cx + bw > cw || cy + bh > ch) return false;
    for (var y = cy; y < cy + bh; y++) {
      for (var x = cx; x < cx + bw; x++) {
        if (occ.contains('$x,$y')) return false;
      }
    }
    return true;
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
    for (var y = cy; y < cy + bh; y++) {
      for (var x = cx; x < cx + bw; x++) {
        occ.add('$x,$y');
      }
    }
  }

  var mainW = 1, mainH = 1;
  final roll = rng.nextDouble();
  if (n > 20 && roll < 0.4) {
    if (rng.nextBool()) {
      mainW = 2;
    } else {
      mainH = 2;
    }
  }
  if (n > 100 && roll < 0.18) {
    mainW = 2;
    mainH = 2;
  }

  final ey = rng.nextInt(max(1, ch - mainH + 1).toInt());
  for (var i = 0; i < mainH; i++) {
    g[(ey + i) * 2 + 1][aw - 1] = 'e';
  }

  final mode = rng.nextInt(4);
  if (mode == 0) {
    paint(0, ey, mainW, mainH, 'M');
    final len = 2 + rng.nextInt(1 + min(2, band + 1).toInt());
    final bx = mainW + rng.nextInt(max(1, cw - mainW - len + 1).toInt());
    if (can(bx, ey, len, 1)) paint(bx, ey, len, 1, 'x');
  } else if (mode == 1) {
    final mySpan = max(1, ch - mainH + 1).toInt();
    final my = (ey + mainH) % mySpan;
    paint(0, my, mainW, mainH, 'M');
    final len = 2 + rng.nextInt(2);
    final gy = max(0, min(ey, ch - len)).toInt();
    if (can(cw - 1, gy, 1, len)) paint(cw - 1, gy, 1, len, 'x');
  } else if (mode == 2) {
    paint(0, ey, mainW, mainH, 'M');
    final fh = min(2, ch - ey).toInt();
    if (can(2, ey, 2, fh)) {
      paint(2, ey, 2, fh, 'x');
    } else if (can(2, ey, 2, 1)) {
      paint(2, ey, 2, 1, 'x');
    }
  } else {
    paint(0, ey, mainW, mainH, 'm');
    if (can(mainW + 1, ey, 2, 1)) paint(mainW + 1, ey, 2, 1, 'x');
    for (var t = 0; t < 20; t++) {
      final cx = rng.nextInt(cw);
      final cy = rng.nextInt(ch);
      if (can(cx, cy, 1, 1)) {
        paint(cx, cy, 1, 1, 'X');
        break;
      }
    }
  }

  for (var i = 0; i < 1 + (band ~/ 2); i++) {
    final bw = rng.nextBool() ? 1 : 2;
    final bh = bw == 1 ? (1 + rng.nextInt(2)) : 1;
    final cx = rng.nextInt(cw);
    final cy = rng.nextInt(ch);
    if (can(cx, cy, bw, bh)) paint(cx, cy, bw, bh, 'x');
  }

  return g.map((r) => r.join()).join('\n');
}

String _yaml(List<_E> levels) {
  final buf = StringBuffer();
  buf.writeln('- name: Adventure');
  buf.writeln('  description: Climb the path — think before you slide');
  buf.writeln('  levels:');
  for (final e in levels) {
    buf.writeln('    - name: "${e.name}"');
    if (e.hint != null && e.hint!.isNotEmpty) {
      buf.writeln('      hint: |-');
      buf.writeln('        ${e.hint}');
    }
    buf.writeln('      map: |-');
    for (final row in e.map.split('\n')) {
      buf.writeln('        $row');
    }
    buf.writeln();
  }
  return buf.toString();
}
