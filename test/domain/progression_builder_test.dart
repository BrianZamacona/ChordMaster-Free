import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/double_stops.dart'
    show noteNames, openStringMidi;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw =
      jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>;
  final chords = [
    for (final c in raw) ChordFingerings.fromJson(c as Map<String, dynamic>),
  ];
  final builder = ProgressionBuilder(chords);

  String degreeRoot(int tonic, ProgressionDegree d) =>
      noteNames[(tonic + d.semitones) % 12];

  Set<int> allowedPitchClasses(ChordFingerings c) {
    final root = noteNames.indexOf(c.root);
    return {for (final i in c.intervals) (root + i) % 12};
  }

  test('9 progresiones × 12 tónicas: un acorde por grado y notas del acorde', () {
    final noPath = <String>[];
    var combos = 0;
    for (final progression in progressions) {
      for (var tonic = 0; tonic < 12; tonic++) {
        combos++;
        final path = builder.build(progression, tonic);
        if (path.isEmpty) {
          noPath.add('${progression.label} en ${noteNames[tonic]}');
          continue;
        }
        expect(path, hasLength(progression.degrees.length));
        for (var i = 0; i < path.length; i++) {
          final degree = progression.degrees[i];
          final chord = path[i].chord;
          final label = '${progression.label} en ${noteNames[tonic]} / ${chord.name}';
          expect(chord.root, degreeRoot(tonic, degree), reason: label);
          expect(chord.type, degree.type, reason: label);
          final allowed = allowedPitchClasses(chord);
          for (var s = 0; s < 6; s++) {
            final fret = path[i].fretPositions[s];
            if (fret == null) continue;
            expect(
              allowed,
              contains((openStringMidi[s] + fret) % 12),
              reason: '$label ${path[i].fretPositions}',
            );
          }
        }
      }
    }
    // ignore: avoid_print
    print('combinaciones: $combos, sin camino: ${noPath.length} $noPath');
    expect(noPath, isEmpty);
  });

  test('es determinista', () {
    for (final progression in progressions) {
      for (var tonic = 0; tonic < 12; tonic++) {
        List<String> run() => [
          for (final v in builder.build(progression, tonic))
            '${v.chord.name} ${v.fretPositions}',
        ];
        expect(run(), run());
      }
    }
  });

  test('el camino óptimo cuesta ≤ elegir siempre el primer candidato', () {
    for (final progression in progressions) {
      for (var tonic = 0; tonic < 12; tonic++) {
        final layers = builder.layersFor(progression, tonic);
        final best = builder.build(progression, tonic);
        if (best.isEmpty) continue;
        final firstPick = [for (final l in layers) l.first];
        expect(
          progressionPathCost(best),
          lessThanOrEqualTo(progressionPathCost(firstPick) + 1e-9),
          reason: '${progression.label} en ${noteNames[tonic]}',
        );
      }
    }
  });

  test('I-IV-V en C usa solo digitaciones que existen en el JSON', () {
    final progression = progressions.firstWhere((p) => p.id == 'v1-3');
    final path = builder.build(progression, 0);
    expect(path.map((v) => v.chord.name), ['C Major', 'F Major', 'G Major']);

    for (final voicing in path) {
      final fromJson = {
        for (final f in voicing.chord.fingerings) f.join(','),
      };
      final chosen = voicing.fretPositions.reversed
          .map((f) => f ?? -1)
          .join(',');
      expect(fromJson, contains(chosen), reason: voicing.chord.name);
    }
  });
}
