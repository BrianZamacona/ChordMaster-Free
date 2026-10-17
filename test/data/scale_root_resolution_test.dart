import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:chordmaster_free/domain/fingering_systems/fingering_systems_registry.dart';
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

  group('chips de sistema', () {
    List<String> chips(ScaleDefinition s) => [
          for (final sys in s.systems)
            FingeringSystemsRegistry.theoryFor(sys.id)?.name ?? sys.name,
        ];

    test('pentatónicas y blues muestran Pentatonic Box (2NPS)', () {
      for (final id in ['pentatonic_minor', 'pentatonic_major', 'blues_minor']) {
        final scale = scales.firstWhere((s) => s.id == id);
        expect(chips(scale), contains('Pentatonic Box (2NPS)'), reason: id);
        expect(chips(scale), isNot(contains('Linear (4NPS)')), reason: id);
      }
    });

    test('escalas de 7 notas y modos muestran Linear (4NPS)', () {
      final sevenNote = scales.where((s) => s.intervals.length == 7);
      expect(sevenNote, isNotEmpty);
      for (final scale in sevenNote) {
        expect(chips(scale), contains('Linear (4NPS)'), reason: scale.id);
      }
    });

    test('ningún chip es Berklee y cada sistema tiene posiciones', () {
      expect(
        FingeringSystemsRegistry.displayOrder,
        isNot(contains('berklee')),
      );
      for (final scale in scales) {
        expect(chips(scale).join(), isNot(contains('Berklee')));
        for (final sys in scale.systems) {
          expect(
            scale.positions.where((p) => p.systemId == sys.id),
            isNotEmpty,
            reason: '${scale.id}/${sys.id}',
          );
        }
      }
    });
  });
}
