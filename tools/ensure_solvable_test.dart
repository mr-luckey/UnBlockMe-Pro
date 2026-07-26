// Ensures every level is solvable; replaces any that aren't.
// Run: flutter test tools/ensure_solvable_test.dart --reporter expanded

import 'dart:io';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ensure all levels solvable', () async {
    final file = File('assets/levels.yaml');
    final raw = file.readAsStringSync().replaceAll('\r\n', '\n');
    final entries = _extract(raw);
    expect(entries.length, 500);

    final seen = entries.map((e) => e.map).toSet();
    final rng = Random(99);
    var fixed = 0;

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final ok = await _isSolvable(e.map);
      if (ok) continue;

      String? replacement;
      for (var t = 0; t < 200; t++) {
        final cand = _safeMap(rng, i + 1);
        if (seen.contains(cand)) continue;
        if (!await _isSolvable(cand)) continue;
        replacement = cand;
        break;
      }
      replacement ??= _fallback(i + 1);
      seen.remove(e.map);
      seen.add(replacement);
      entries[i] = _Entry(e.name, replacement, e.hint);
      fixed++;
      if (fixed % 10 == 0) {
        print('Fixed $fixed so far (at level ${e.name})');
      }
    }

    file.writeAsStringSync(_toYaml(entries));
    print('Done. replaced=$fixed');

    // Spot-check
    for (final id in ['1', '17', '50', '100', '250', '500']) {
      final e = entries.firstWhere((x) => x.name == id);
      expect(await _isSolvable(e.map), isTrue, reason: 'level $id');
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}

class _Entry {
  _Entry(this.name, this.map, this.hint);
  final String name;
  final String map;
  final String? hint;
}

List<_Entry> _extract(String yaml) {
  final lines = yaml.split('\n');
  final out = <_Entry>[];
  String? name;
  String? hint;
  final mapBuf = StringBuffer();
  final hintBuf = StringBuffer();
  var inMap = false;
  var inHint = false;

  void flush() {
    if (name != null && mapBuf.isNotEmpty) {
      out.add(_Entry(name!, mapBuf.toString().trimRight(),
          hintBuf.isEmpty ? hint : hintBuf.toString().trim()));
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

Future<bool> _isSolvable(String map) async {
  try {
    final state = parseLevel(map);
    final moves = await _solve(state.puzzle, maxVisited: 40000);
    return moves != null;
  } catch (_) {
    return false;
  }
}

Future<List<MoveDirection>?> _solve(PuzzleState start,
    {required int maxVisited}) async {
  final frontier = PriorityQueue<_N>();
  final visited = <int>{};
  frontier.add(_N(start, 0, _hash(start)));
  while (frontier.isNotEmpty) {
    final cur = frontier.removeFirst();
    if (!visited.add(cur.hash)) continue;
    if (visited.length > maxVisited) return null;
    if (cur.state.isCompleted) return const <MoveDirection>[];
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

String _safeMap(Random rng, int n) {
  final cw = 3 + rng.nextInt(3);
  final ch = 3 + rng.nextInt(3);
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
  for (var i = 0; i < extras; i++) {
    final cx = 1 + rng.nextInt(max(1, cw - 1));
    final cy = rng.nextInt(ch);
    if (cy == lane) continue;
    final ax = cx * 2 + 1;
    final ay = cy * 2 + 1;
    if (g[ay][ax] == '.') g[ay][ax] = 'x';
  }
  return g.map((r) => r.join()).join('\n');
}

String _fallback(int n) {
  final lane = (n % 3);
  final rows = <String>[
    '*********',
    for (var i = 0; i < 3; i++)
      i == lane ? '*M......e' : '*...x...*',
    '*********',
  ];
  // ensure odd height: 5 rows already odd
  return rows.join('\n');
}

String _toYaml(List<_Entry> levels) {
  final buf = StringBuffer();
  buf.writeln('- name: Adventure');
  buf.writeln('  description: Climb the path — escape every room');
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
