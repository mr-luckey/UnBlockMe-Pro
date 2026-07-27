// Append Hard 3 + Hard 4 from proven Hard 1/2 style maps (existing untouched).
// dart run tools/append_hard_chapters.dart
// flutter test tools/verify_new_hard_test.dart --reporter expanded

import 'dart:io';

void main() {
  final file = File('assets/levels.yaml');
  var yaml = file.readAsStringSync();
  if (yaml.contains('- name: Hard 3')) {
    stderr.writeln('Hard 3 already present — aborting.');
    exit(1);
  }

  final all = [..._hard3(), ..._hard4()];
  for (final l in all) {
    final err = _validate(l.map);
    if (err != null) {
      stderr.writeln('${l.name}: $err\n${l.map}');
      exit(1);
    }
  }

  if (!yaml.endsWith('\n')) yaml = '$yaml\n';
  file.writeAsStringSync(
      '$yaml\n${_chapter('Hard 3', 'squeeze & transfer', _hard3())}\n'
      '${_chapter('Hard 4', 'interlock', _hard4())}\n');
  stdout.writeln('Appended Hard 3 (${_hard3().length}) + Hard 4 (${_hard4().length})');
}

String? _validate(String map) {
  final rows = map.trim().split('\n');
  final w = rows.first.length;
  if (w.isEven || rows.length.isEven) {
    return 'odd size required (${w}x${rows.length})';
  }
  for (final r in rows) {
    if (r.length != w) return 'row width ${r.length} != $w ($r)';
  }
  final j = rows.join();
  if (!j.contains('e')) return 'no exit';
  if (!j.toLowerCase().contains('m')) return 'no main';
  if (!j.contains('M') && !j.contains('X')) return 'no control';
  return null;
}

String _chapter(String name, String desc, List<_L> levels) {
  final buf = StringBuffer();
  buf.writeln('- name: $name');
  buf.writeln('  description: $desc');
  buf.writeln('  levels:');
  for (final l in levels) {
    buf.writeln('    - name: ${l.name}');
    if (l.hint != null) {
      buf.writeln('      hint: |-');
      buf.writeln('        ${l.hint}');
    }
    buf.writeln('      map: |-');
    for (final row in l.map.trim().split('\n')) {
      buf.writeln('        $row');
    }
    buf.writeln();
  }
  return buf.toString().trimRight();
}

class _L {
  _L(this.name, this.map, {this.hint});
  final String name;
  final String map;
  final String? hint;
}

/// Hard 3 — Hard 2 top-right transfers, extra bars / tighter parking.
List<_L> _hard3() => [
      _L(
        'H_3-1',
        _m([
          '*********ee',
          '*x.xxx...Xe',
          '*.....*...*',
          '*x....x...*',
          '*.*...*.*.*',
          '*x...xxx.x*',
          '*.***.....*',
          '*m...xxx..*',
          '***********',
        ]),
        hint: 'Park the long bar before the main can climb.',
      ),
      // Harder H_2-2
      _L(
        'H_3-2',
        _m([
          '*********ee',
          '*x.xxx...Xe',
          '*.....***.*',
          '*x....*.*.*',
          '*x....***.*',
          '*x...x...x*',
          '*.***....x*',
          '*.*.*....x*',
          '*.***.....*',
          '*m...xxx.x*',
          '***********',
        ]),
      ),
      _L(
        'H_3-3',
        _m([
          '***********ee',
          '*x.xxxxx...Xe',
          '*x....*.....*',
          '*x..xxx.....*',
          '*.*...*.....*',
          '*...x...xxx.*',
          '*...*.......*',
          '*mmm....xxx.*',
          '*************',
        ]),
      ),
      // Variant of H_3-1 with mid clutter
      _L(
        'H_3-4',
        _m([
          '*********ee',
          '*x.xxx...Xe',
          '*..x..*...*',
          '*x....x...*',
          '*.*...*.*.*',
          '*x...xxx.x*',
          '*.***.....*',
          '*m...xxx..*',
          '***********',
        ]),
      ),
      // Variant of H_3-2 — extra mid bar
      _L(
        'H_3-5',
        _m([
          '*********ee',
          '*x.xxx...Xe',
          '*.....***.*',
          '*x.x..*.*.*',
          '*x....***.*',
          '*x...x...x*',
          '*.***....x*',
          '*.*.*....x*',
          '*.***.....*',
          '*m...xxx.x*',
          '***********',
        ]),
      ),
      // Variant of H_3-3 — extra vertical guard
      _L(
        'H_3-6',
        _m([
          '***********ee',
          '*x.xxxxx...Xe',
          '*x....*.....*',
          '*x..xxx...x.*',
          '*.*...*.....*',
          '*...x...xxx.*',
          '*...*.......*',
          '*mmm....xxx.*',
          '*************',
        ]),
      ),
      _L(
        'H_3-7',
        _m([
          '***********ee',
          '*xx......XXXe',
          '*x..*.......*',
          '*x.x..xxx...*',
          '*..x*.***.*.*',
          '*..x........*',
          '*.....xxx...*',
          '*........mmm*',
          '*************',
        ]),
      ),
      // Variant of H_3-7 — longer parking bar
      _L(
        'H_3-8',
        _m([
          '***********ee',
          '*x.......XXXe',
          '*x..*.......*',
          '*x.x..xxxxx.*',
          '*..x*.***.*.*',
          '*..x........*',
          '*.....xxx...*',
          '*........mmm*',
          '*************',
        ]),
      ),
      // Variant of H_3-10
      _L(
        'H_3-9',
        _m([
          '*********ee',
          '*x.xxxxx.Xe',
          '*..x..*...*',
          '*..xxx....*',
          '*.*...*...*',
          '*..x...xxx*',
          '*..x*.....*',
          '*m.x...xxx*',
          '***********',
        ]),
      ),
      _L(
        'H_3-10',
        _m([
          '*********ee',
          '*x.xxxxx.Xe',
          '*.....*...*',
          '*..xxx....*',
          '*.*...*...*',
          '*..x...xxx*',
          '*..x*.....*',
          '*m.x...xxx*',
          '***********',
        ]),
      ),
    ];

/// Hard 4 — Hard 1 symmetry / fat mains, tighter.
List<_L> _hard4() => [
      _L(
        'H_4-1',
        _m([
          '*********',
          '*....xxx*',
          '*....xxx*',
          '*..M.xxx*',
          '*...*...*',
          '*xxx.x.x*',
          '*xxx....*',
          '*xxx....e',
          '*********',
        ]),
        hint: 'Clear a bay for the fat block, then slide out.',
      ),
      _L(
        'H_4-2',
        _m([
          '*************',
          '*...........*',
          '*...........*',
          '*...........*',
          '*.*.*.*.*.*.*',
          '*MMM.x.x.x.xe',
          '*MMM.x.x.x.xe',
          '*MMM.x.x.x.xe',
          '*.*.*.*.*.*.*',
          '*...........*',
          '*...........*',
          '*...........*',
          '*************',
        ]),
      ),
      _L(
        'H_4-3',
        _m([
          '***********',
          '*.........*',
          '*.*.*.*...*',
          '*mmm*x*xxxe',
          '*...*.*...*',
          '*....xxxxx*',
          '*...*x....*',
          '*X...x...x*',
          '***********',
        ]),
      ),
      // Variant of H_4-1 — extra side pin
      _L(
        'H_4-4',
        _m([
          '*********',
          '*x...xxx*',
          '*....xxx*',
          '*..M.xxx*',
          '*...*...*',
          '*xxx.x.x*',
          '*xxx....*',
          '*xxx....e',
          '*********',
        ]),
      ),
      _L(
        'H_4-5',
        _m([
          '*******',
          '*x.x..e',
          '*..x***',
          '*..x..*',
          '*.....*',
          '*..x..*',
          '*..x***',
          '*M.x..*',
          '*******',
        ]),
      ),
      _L(
        'H_4-6',
        _m([
          '*********',
          '*......x*',
          '***.....*',
          '*..mmm.Xe',
          '*..mmm.Xe',
          '*..mmm.Xe',
          '***.....*',
          '*......x*',
          '*********',
        ]),
      ),
      _L(
        'H_4-7',
        _m([
          '*********',
          '*...x.x.*',
          '*.*...*.*',
          '*..MMM.xe',
          '*..MMM..e',
          '*..MMM.xe',
          '*.*...*.*',
          '*x...x..*',
          '*********',
        ]),
      ),
      _L(
        'H_4-8',
        _m([
          '*******',
          '*x...x*',
          '*x..*x*',
          '*x.x.x*',
          '*.*...*',
          '*..x..*',
          '*...*.*',
          '*X...m*',
          '*X***m*',
          '*X...m*',
          '*...*.*',
          '*..x..*',
          '***e***',
        ]),
      ),
      // Variant of H_4-3 — longer top bar
      _L(
        'H_4-9',
        _m([
          '***********',
          '*.........*',
          '*.*.*.*...*',
          '*mmm*x*xxxe',
          '*...*.*...*',
          '*..x.xxxxx*',
          '*...*x....*',
          '*X...x...x*',
          '***********',
        ]),
      ),
      // Variant of H_4-8 — extra mid lock
      _L(
        'H_4-10',
        _m([
          '*******',
          '*x...x*',
          '*x..*x*',
          '*x.x.x*',
          '*.*...*',
          '*..x.x*',
          '*...*.*',
          '*X...m*',
          '*X***m*',
          '*X...m*',
          '*...*.*',
          '*..x..*',
          '***e***',
        ]),
      ),
    ];

String _m(List<String> rows) => rows.join('\n');
