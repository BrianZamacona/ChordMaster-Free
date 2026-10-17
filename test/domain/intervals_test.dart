import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:chordmaster_free/domain/theory/intervals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escalas de 7 notas: un número de grado por nota', () {
    expect(scaleDegreeLabels([0, 2, 4, 5, 7, 9, 11]),
        ['1', '2', '3', '4', '5', '6', '7']);
    expect(scaleDegreeLabels([0, 2, 3, 5, 7, 8, 10]),
        ['1', '2', 'b3', '4', '5', 'b6', 'b7']); // menor natural
    expect(scaleDegreeLabels([0, 2, 4, 6, 7, 9, 11]),
        ['1', '2', '3', '#4', '5', '6', '7']); // lidia
    expect(scaleDegreeLabels([0, 1, 3, 5, 6, 8, 10]),
        ['1', 'b2', 'b3', '4', 'b5', 'b6', 'b7']); // locria
    expect(scaleDegreeLabels([0, 2, 3, 6, 7, 8, 11]),
        ['1', '2', 'b3', '#4', '5', 'b6', '7']); // húngara menor
  });

  test('fuera de 7 notas: nombres por defecto', () {
    expect(scaleDegreeLabels([0, 3, 5, 6, 7, 10]),
        ['1', 'b3', '4', 'b5', '5', 'b7']); // blues
    expect(scaleDegreeLabels([0, 2, 4, 6, 8, 10]),
        ['1', '2', '3', 'b5', '#5', 'b7']);
    expect(spellInterval(8), '#5');
    expect(spellInterval(13), 'b2');
  });

  test('diapasón: en cada escala de 7 notas las etiquetas son sus grados', () {
    final data =
        jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final g in ['scales', 'modes']) {
      for (final raw in data[g] as List<dynamic>) {
        final scale = ScaleDefinition.fromJson(raw as Map<String, dynamic>);
        final labels = scaleDegreeLabels(scale.intervals).toSet();
        for (final p in scale.positions) {
          for (final root in [0, 9]) {
            final coords = p.resolveCoordinates(
              root,
              scaleIntervals: scale.intervals,
            );
            for (final c in coords) {
              expect(labels, contains(c.interval), reason: '${scale.id} $c');
            }
          }
        }
        if (scale.id == 'natural_minor') {
          expect(labels, containsAll(['b6', 'b7']));
          expect(labels, isNot(contains('#5')));
        }
      }
    }
  });
}
