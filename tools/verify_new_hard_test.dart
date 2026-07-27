// Verify newly appended Hard 3 / Hard 4 levels parse + are solvable.
// flutter test tools/verify_new_hard_test.dart --reporter expanded

import 'dart:io';
import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hard 3 and Hard 4 are solvable', () async {
    final yaml = File('assets/levels.yaml').readAsStringSync();
    final levels = <MapEntry<String, String>>[];

    String? chapter;
    String? name;
    final mapBuf = StringBuffer();
    var inMap = false;

    void flush() {
      if (chapter != null &&
          name != null &&
          mapBuf.isNotEmpty &&
          (chapter == 'Hard 3' || chapter == 'Hard 4')) {
        levels.add(MapEntry(name!, mapBuf.toString().trimRight()));
      }
      mapBuf.clear();
      inMap = false;
    }

    for (final line in yaml.replaceAll('\r\n', '\n').split('\n')) {
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

    expect(levels.length, greaterThanOrEqualTo(18),
        reason: 'expected Hard 3+4 levels');

    final bad = <String>[];
    for (final e in levels) {
      try {
        final state = parseLevel(e.value);
        final moves = await _solve(state.puzzle, maxVisited: 200000);
        if (moves == null) {
          bad.add('${e.key}: unsolvable/timeout');
        } else if (moves < 3) {
          bad.add('${e.key}: too easy ($moves moves)');
        } else {
          print('${e.key}: OK ($moves moves)');
        }
      } catch (err) {
        bad.add('${e.key}: parse error $err');
      }
    }

    expect(bad, isEmpty, reason: bad.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 15)));
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
