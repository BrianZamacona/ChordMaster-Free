import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:flutter_test/flutter_test.dart';

const _openHighToLow = [4, 11, 7, 2, 9, 4];

void main() {
  final data =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  final scales = [
    for (final g in ['scales', 'modes'])
      for (final s in (data[g] as List<dynamic>))
        ScaleDefinition.fromJson(s as Map<String, dynamic>),
  ];

  // C=0, E=4, A=9, B=11
  for (final root in [0, 4, 9, 11]) {
    test('raíz $root: posiciones completas, en 0..24 y con notas de la escala', () {
      for (final scale in scales) {
        final allowed = {for (final i in scale.intervals) (root + i) % 12};
        for (final p in scale.positions) {
          final coords = p.resolveCoordinates(root);
          final label = '${scale.id}/${p.id}';
          expect(coords, hasLength(p.coordinates.length), reason: label);
          for (final c in coords) {
            expect(c.fret, inInclusiveRange(0, 24), reason: '$label $c');
            final pc = (_openHighToLow[c.string - 1] + c.fret) % 12;
            expect(allowed, contains(pc), reason: '$label cuerda ${c.string}');
          }
        }
      }
    });
  }
}
