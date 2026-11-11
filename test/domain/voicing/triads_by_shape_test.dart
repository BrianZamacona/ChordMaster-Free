import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/voicing/triads_by_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chords = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List).cast<Map>();
  List<({String shape, List<int> frets})> shapesOf(Map c) => [
    for (final p in (c['cagedPositions'] as List? ?? const []).cast<Map>())
      (shape: p['shape'] as String, frets: (p['fretPositions'] as List).cast<int>()),
  ];
  List<List<int>> triadsOf(Map c) => [
    for (final t in (c['triadInversions'] as List? ?? const []).cast<Map>()) (t['fretPositions'] as List).cast<int>(),
  ];
  // Clases de nota de unos trastes (6ª → 1ª).
  Set<int> pcs(List<int> frets) => {
    for (var s = 0; s < 6; s++)
      if (frets[s] >= 0) (standardOpenStringMidi[5 - s] + frets[s]) % 12,
  };

  test('C mayor: cada forma con sus tríadas, dentro de sus trastes', () {
    final c = chords.firstWhere((x) => x['root'] == 'C' && x['type'] == 'major');
    final groups = triadsByShape(shapesOf(c), triadsOf(c));
    expect([for (final g in groups) (g.window.shape, g.window.lowest, g.window.highest, g.triads.length)], [
      ('C', 0, 3, 1),
      ('A', 3, 5, 2),
      ('G', 5, 8, 3),
      ('E', 8, 10, 3),
      ('D', 10, 13, 2),
    ]);
  });

  test('en todos los acordes: cada tríada agrupada cae en su forma, suena igual y las demás quedan entre formas', () {
    var placed = 0;
    var between = 0;
    for (final c in chords) {
      final shapes = shapesOf(c);
      final triads = triadsOf(c);
      if (shapes.isEmpty || triads.isEmpty) continue;
      final seen = <int>{};
      for (final g in triadsByShape(shapes, triads)) {
        for (final t in g.triads) {
          final played = [for (final f in t.frets) if (f >= 0) f];
          final why = '${c['name']} ${g.window.shape} #${t.index}';
          expect(played.every((f) => f >= g.window.lowest && f <= g.window.highest && f >= 1), isTrue, reason: why);
          // Corrida de a octavas: las mismas notas en las mismas cuerdas.
          expect(pcs(t.frets), pcs(triads[t.index]), reason: why);
          for (var s = 0; s < 6; s++) {
            expect(t.frets[s] < 0, triads[t.index][s] < 0, reason: why);
            if (t.frets[s] >= 0) expect((t.frets[s] - triads[t.index][s]) % 12, 0, reason: why);
          }
          seen.add(t.index);
        }
      }
      final outside = triadsBetweenShapes(shapes, triads);
      expect(outside.toSet().intersection(seen), isEmpty, reason: '${c['name']}');
      expect(outside.length + seen.length, triads.length, reason: '${c['name']}');
      placed += seen.length;
      between += outside.length;
    }
    // Lo que se midió al decidir la regla: la mayoría cae en una forma.
    expect(placed, greaterThan(between * 4));
  });

  test('una tríada que no cabe tal cual cabe una octava arriba', () {
    const window = (shape: 'D', lowest: 10, highest: 13);
    // 2ª inversión en 6-5-4 de C (3 3 2) → 15 15 14 no cabe; tal cual tampoco.
    expect(triadInWindow(const [3, 3, 2, -1, -1, -1], window), isNull);
    // 3-2-1 en la raíz de C (5 5 3) no cabe en D; en G (5–8) sí, tal cual.
    expect(triadInWindow(const [-1, -1, -1, 5, 5, 3], (shape: 'G', lowest: 5, highest: 8)), isNull);
    expect(triadInWindow(const [-1, -1, -1, 5, 5, 3], (shape: 'A', lowest: 3, highest: 5)), [-1, -1, -1, 5, 5, 3]);
    expect(triadInWindow(const [-1, -1, -1, 5, 5, 3], (shape: 'x', lowest: 15, highest: 17)), [-1, -1, -1, 17, 17, 15]);
  });
}
