import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/double_stops.dart'
    show noteNames, openStringMidi;
import 'package:chordmaster_free/domain/voicing/barre_detection.dart';
import 'package:chordmaster_free/domain/voicing/ergonomics.dart';
import 'package:chordmaster_free/domain/voicing/voicing_adapter.dart';
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

  group('modo principiante', () {
    Barre? barreOf(ProgressionVoicing v) {
      final i = v.chord.fingerings.indexWhere(
        (f) => f.join(',') == v.jsonFrets.join(','),
      );
      return detectBarre(
        v.fretPositions,
        VoicingAdapter.fingersFromChordJson(v.chord.fingers[i]),
      );
    }

    int grandeWidth(List<ProgressionVoicing> path) => path.fold(0, (sum, v) {
      final b = barreOf(v);
      return b != null && barreKind(b) == BarreKind.grande
          ? sum + barreWidth(b)
          : sum;
    });

    String key(List<ProgressionVoicing> path) =>
        path.map((v) => '${v.chord.name}${v.jsonFrets}').join('|');

    test('beginner: false es idéntico al comportamiento por defecto', () {
      for (final progression in progressions) {
        for (var tonic = 0; tonic < 12; tonic++) {
          final standard = builder.build(progression, tonic);
          expect(key(standard), key(builder.build(progression, tonic)));
          expect(standard.every((v) => v.barre == null), isTrue);
        }
      }
    });

    test('G y C con I-V-vi-IV: no más cejilla grande que el estándar', () {
      final progression = progressions.firstWhere((p) => p.id == 'v1-2');
      for (final tonic in [0, 7]) {
        final standard = builder.build(progression, tonic);
        final beginner = builder.build(progression, tonic, beginner: true);
        expect(
          grandeWidth(beginner),
          lessThanOrEqualTo(grandeWidth(standard)),
          reason: noteNames[tonic],
        );
      }
      final inG = builder.build(progression, 7, beginner: true);
      expect(inG.map((v) => v.chord.name), [
        'G Major',
        'D Major',
        'E Minor',
        'C Major',
      ]);
      expect(grandeWidth(inG), 0);
    });

    test('I-IV-V en D, A, E, G, C: sin cejilla grande', () {
      final progression = progressions.firstWhere((p) => p.id == 'v1-3');
      for (final tonic in [2, 9, 4, 7, 0]) {
        final path = builder.build(progression, tonic, beginner: true);
        expect(grandeWidth(path), 0, reason: noteNames[tonic]);
      }
    });

    test('108 combinaciones: el modo principiante nunca usa más cejilla grande', () {
      var changed = 0;
      var strictViolations = 0;
      for (final progression in progressions) {
        for (var tonic = 0; tonic < 12; tonic++) {
          final layers = builder.layersFor(progression, tonic, beginner: true);
          final standard = builder.build(progression, tonic);
          final path = builder.build(progression, tonic, beginner: true);
          if (key(path) != key(standard)) changed++;
          expect(
            grandeWidth(path),
            lessThanOrEqualTo(grandeWidth(standard)),
            reason: '${progression.label} en ${noteNames[tonic]}',
          );
          // La penalización es blanda: un grado puede conservar una cejilla
          // grande aunque tenga alternativas si el resto del camino sale peor.
          for (var i = 0; i < path.length; i++) {
            final b = path[i].barre;
            final chosenGrande = b != null && barreKind(b) == BarreKind.grande;
            final hasAlternative = layers[i].any(
              (v) => v.barre == null || barreKind(v.barre!) != BarreKind.grande,
            );
            if (chosenGrande && hasAlternative) strictViolations++;
          }
        }
      }
      // ignore: avoid_print
      print('modo principiante cambió $changed de 108; grados con cejilla grande pese a tener alternativa: $strictViolations');
      expect(changed, greaterThan(0));
    });

    test('un grado con solo candidatos con cejilla sigue dando camino', () {
      ChordFingerings onlyBarre(String name) {
        final c = chords.firstWhere((c) => c.name == name);
        final i = c.fingerings.indexWhere((f) => f.join(',') == '1,3,3,2,1,1' || f.join(',') == '8,10,10,9,8,8' || f.join(',') == '3,5,5,4,3,3');
        return ChordFingerings(
          name: c.name,
          root: c.root,
          type: c.type,
          intervals: c.intervals,
          fingerings: [c.fingerings[i]],
          fingers: [c.fingers[i]],
        );
      }

      final f = onlyBarre('F Major');
      final onlyBuilder = ProgressionBuilder([f]);
      final single = Progression('t', 'IV', ['IV']);
      final path = onlyBuilder.build(single, 0, beginner: true);
      expect(path, hasLength(1));
      expect(path.first.barre, isNotNull);
      expect(barreKind(path.first.barre!), BarreKind.grande);
    });
  });
}
