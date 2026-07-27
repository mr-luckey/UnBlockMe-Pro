// Expand levels.yaml to 500 without modifying existing maps.
// flutter test tools/expand_to_500_test.dart --reporter expanded

import 'dart:io';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expand to 500 levels keeping existing', () async {
    final file = File('assets/levels.yaml');
    final existing = _readAll(file.readAsStringSync());
    expect(existing.length, greaterThanOrEqualTo(100));
    print('existing=${existing.length}');

    final seen = existing.map((e) => e.map).toSet();
    final rng = Random(20260726);
    final seeds = existing
        .where((e) =>
            e.chapter.startsWith('Hard') ||
            e.chapter.startsWith('Normal') ||
            e.chapter.startsWith('Easy'))
        .map((e) => e.map)
        .toList();
    expect(seeds.length, greaterThan(20));

    final added = <_Lev>[];
    var attempts = 0;
    final need = 500 - existing.length;
    print('need $need more');

    while (added.length < need && attempts < need * 80) {
      attempts++;
      final band = added.length / need; // 0..1 difficulty ramp
      final base = seeds[rng.nextInt(seeds.length)];
      final cand = _mutate(base, rng, band);
      if (cand == null || seen.contains(cand)) continue;

      final moves = await _solveMoves(cand);
      final minM = band < 0.25
          ? 3
          : band < 0.5
              ? 5
              : band < 0.75
                  ? 7
                  : 8;
      if (moves == null || moves < minM || moves > 90) continue;

      seen.add(cand);
      final n = existing.length + added.length + 1;
      added.add(_Lev('Challenge', 'C_$n', cand));
      if (added.length % 25 == 0) {
        print('added ${added.length}/$need (last $moves moves)');
        File('tools/expand_progress.txt')
            .writeAsStringSync('added ${added.length}/$need');
      }
    }

    expect(added.length, need,
        reason: 'only generated ${added.length}/$need after $attempts tries');

    // Group new levels into Challenge chapters of 20
    final chapters = <String, List<_Lev>>{};
    for (var i = 0; i < added.length; i++) {
      final pack = 1 + (i ~/ 20);
      final name = 'Challenge $pack';
      chapters.putIfAbsent(name, () => []);
      final local = (i % 20) + 1;
      chapters[name]!.add(_Lev(name, 'C_${pack}-$local', added[i].map));
    }

    final buf = StringBuffer(file.readAsStringSync().trimRight());
    buf.writeln();
    for (final entry in chapters.entries) {
      buf.writeln();
      buf.writeln('- name: ${entry.key}');
      buf.writeln('  description: climb higher');
      buf.writeln('  levels:');
      for (final l in entry.value) {
        buf.writeln('    - name: ${l.name}');
        buf.writeln('      map: |-');
        for (final row in l.map.split('\n')) {
          buf.writeln('        $row');
        }
        buf.writeln();
      }
    }
    file.writeAsStringSync(buf.toString());
    print('DONE total=${existing.length + added.length}');
    File('tools/expand_progress.txt').writeAsStringSync(
        'DONE ${existing.length + added.length}');
  }, timeout: const Timeout(Duration(minutes: 45)));
}

class _Lev {
  _Lev(this.chapter, this.name, this.map);
  final String chapter;
  final String name;
  final String map;
}

List<_Lev> _readAll(String yaml) {
  final lines = yaml.replaceAll('\r\n', '\n').split('\n');
  final out = <_Lev>[];
  String? chapter;
  String? name;
  final mapBuf = StringBuffer();
  var inMap = false;

  void flush() {
    if (chapter != null && name != null && mapBuf.isNotEmpty) {
      out.add(_Lev(chapter!, name!, mapBuf.toString().trimRight()));
    }
    mapBuf.clear();
    inMap = false;
  }

  for (final line in lines) {
    final ch = RegExp(r'^- name:\s*(.+)$').firstMatch(line);
    if (ch != null) {
      flush();
      chapter = ch.group(1)!.trim();
      name = null;
      continue;
    }
    final nm = RegExp(r'^    - name:\s*(\S+)').firstMatch(line);
    if (nm != null) {
      flush();
      name = nm.group(1);
      continue;
    }
    if (RegExp(r'^      map:').hasMatch(line)) {
      inMap = true;
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

String? _mutate(String map, Random rng, double band) {
  final rows = map.trim().split('\n').map((r) => r.split('')).toList();
  if (rows.length < 3 || rows.first.length < 5) return null;
  final h = rows.length;
  final w = rows.first.length;
  if (w.isEven || h.isEven) return null;

  final salts = 1 + (band * 3).floor() + rng.nextInt(2);
  for (var s = 0; s < salts; s++) {
    final y = 1 + rng.nextInt(max(1, h - 2));
    final x = 1 + rng.nextInt(max(1, w - 2));
    // Prefer even cells (between block centers) for walls
    if (x.isOdd && y.isOdd) {
      if (rows[y][x] == '.' && rng.nextDouble() < 0.35) {
        rows[y][x] = 'x';
      }
      continue;
    }
    if (rows[y][x] == '.') rows[y][x] = '*';
  }

  // Occasional mirror
  if (rng.nextDouble() < 0.2) {
    for (final row in rows) {
      final mid = row.length ~/ 2;
      for (var i = 1; i < mid; i++) {
        final j = row.length - 1 - i;
        final a = row[i];
        final b = row[j];
        // Don't mirror exits awkwardly — skip if either is e
        if (a == 'e' || b == 'e') continue;
        row[i] = b;
        row[j] = a;
      }
    }
  }

  final out = rows.map((r) => r.join()).join('\n');
  // Basic sanity
  final j = out;
  if (!j.contains('e')) return null;
  if (!j.toLowerCase().contains('m')) return null;
  if (!j.contains('M') && !j.contains('X')) return null;
  return out;
}

Future<int?> _solveMoves(String map) async {
  try {
    final state = parseLevel(map);
    return await _solve(state.puzzle, maxVisited: 45000);
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
      if (!visited.contains(h)) frontier.add(_N(next, cur.g + 1, h));
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
