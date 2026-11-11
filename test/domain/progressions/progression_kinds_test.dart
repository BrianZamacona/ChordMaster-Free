import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/theory/harmony.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/theory/scale_insights.dart';
import 'package:flutter_test/flutter_test.dart';

/// Blues, progresiones en menor y vamps modales: lo que afirman, por regla.
void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final scaleIntervals = {
    for (final s in [...master['scales'] as List, ...master['modes'] as List])
      (s as Map)['id'] as String: (s['intervals'] as List).cast<int>(),
  };
  Progression byId(String id) => progressions.firstWhere((p) => p.id == id);
  Set<int> tonesOf(Progression p) => {for (final d in p.degrees) ...degreeChordTones(d)};
  List<int> barsOf(Progression p, String numeral) => [
    for (final (i, d) in p.degrees.indexed)
      if (d.numeral == numeral) i + 1,
  ];

  test('ids únicos y cada familia con lo suyo', () {
    expect({for (final p in progressions) p.id}, hasLength(progressions.length));
    for (final kind in ProgressionKind.values) {
      expect(progressions.where((p) => p.kind == kind), isNotEmpty, reason: kind.name);
    }
    // El capo solo gira las de la tonalidad mayor.
    expect(majorProgressions.every((p) => p.kind == ProgressionKind.major), isTrue);
    expect(majorProgressions.map((p) => p.id), contains('v1-1'));
  });

  test('cada grado tiene su papel en una frase que empieza por él', () {
    for (final n in allDegreeNumerals) {
      expect(degreeRole(n).es, startsWith('$n:'), reason: n);
      expect(degreeRole(n).en, startsWith('$n:'), reason: n);
    }
  });

  test('lo que dice cada grado nuevo, por intervalos', () {
    ProgressionDegree d(String n) => Progression('t', n, [n]).degrees.single;
    // V7: su 7ª es la 4ª de la escala (5 semitonos sobre la tónica).
    expect(degreeChordTones(d('V7')), contains(5));
    // II: su 3ª es la #4 (6 semitonos).
    expect(degreeChordTones(d('II')), contains(6));
    // ♭II: medio tono sobre la tónica; i°: su 5ª es la b5.
    expect(d('♭II').semitones, 1);
    expect(degreeChordTones(d('i°')), contains(6));
    // ♭VII: un tono debajo; v: su 3ª queda un tono debajo de la tónica.
    expect(d('♭VII').semitones, 10);
    expect(degreeChordTones(d('v')), contains(10));
    expect(degreeChordTones(d('v')), isNot(contains(11)));
    // ♭III: la tónica de la relativa mayor, tres semitonos arriba.
    expect(d('♭III').semitones, 3);
    expect(d('♭VI').semitones, 8);
  });

  group('blues de 12 compases', () {
    test('un grado por compás; el I7, el IV7 y el V7 donde van', () {
      final b = byId('blues-12');
      expect(b.degrees, hasLength(12));
      expect(barsOf(b, 'I7'), [1, 2, 3, 4, 7, 8, 11]);
      expect(barsOf(b, 'IV7'), [5, 6, 10]);
      expect(barsOf(b, 'V7'), [9, 12]);
      final lines = [for (final l in explainProgression(b, 0)) l.es].join('\n');
      expect(lines, contains('I7 en 1–4, 7–8 y 11'));
      expect(lines, contains('IV7 en 5–6 y 10'));
      expect(lines, contains('compás 12 es la vuelta'));
      expect(lines, isNot(contains('Cambio rápido')));
      // El recorrido nombra una vez cada grado repetido en compases seguidos.
      expect(lines, contains('Recorrido: I7 (reposo) → IV7 (preparación) → I7 (reposo) → V7 (tensión) → IV7 (preparación) → I7 (reposo) → V7 (tensión).'));
    });

    test('el cambio rápido lleva el IV7 al compás 2; el lento va en 12/8', () {
      final q = byId('blues-12-quick');
      expect(barsOf(q, 'IV7'), [2, 5, 6, 10]);
      expect([for (final l in explainProgression(q, 0)) l.es].join(), contains('Cambio rápido: el IV7 ya llega en el compás 2'));
      final slow = byId('blues-12-slow');
      expect(slow.feel, ProgressionFeel.triplet);
      expect([for (final d in slow.degrees) d.numeral], [for (final d in byId('blues-12').degrees) d.numeral]);
      expect([for (final l in explainProgression(slow, 0)) l.en].join(), contains('12/8'));
    });

    test('el blues menor: i7 y iv7, el ♭VI en el 9 y el V7 de la menor armónica', () {
      final m = byId('blues-12-minor');
      expect(m.degrees, hasLength(12));
      expect(barsOf(m, 'i7'), [1, 2, 3, 4, 7, 8, 11]);
      expect(barsOf(m, 'iv7'), [5, 6]);
      expect(barsOf(m, '♭VI'), [9]);
      // La 3ª del V7 es la sensible, la 7ª de la menor armónica.
      expect(degreeChordTones(m.degrees[9]), contains(11));
      expect(scaleIntervals['harmonic_minor'], contains(11));
    });
  });

  test('en menor: los acordes son de la menor natural, salvo el V7 de la armónica', () {
    for (final p in progressions.where((p) => p.kind == ProgressionKind.minor)) {
      expect(p.degrees.first.numeral, 'i', reason: p.id);
      for (final d in p.degrees) {
        final scale = d.numeral == 'V7' ? scaleIntervals['harmonic_minor']! : naturalMinorScale;
        // El V7 de la armónica no trae su 7ª (la 4ª): se mira la tríada.
        final tones = d.numeral == 'V7' ? degreeChordTones(d).difference({5}) : degreeChordTones(d);
        expect(scale, containsAll(tones), reason: '${p.id} ${d.numeral}');
      }
    }
  });

  group('vamps modales', () {
    final vamps = progressions.where((p) => p.kind == ProgressionKind.modal).toList();

    test('cada uno es un modo de scales_master.json, con acordes del modo', () {
      expect(vamps, hasLength(5));
      for (final p in vamps) {
        final id = modeScaleIds[p.mode!];
        expect(p.id, 'mode-$id');
        expect(modeIntervals(p.mode!), scaleIntervals[id], reason: id);
        expect(modeIntervals(p.mode!), containsAll(tonesOf(p)), reason: id);
        // El nombre dice el modo y sus grados.
        expect(p.name!.en, '${id[0].toUpperCase()}${id.substring(1)} (${p.label.replaceAll(' - ', '–')})');
      }
    });

    test('hacen oír lo que distingue a su modo, y el texto lo dice con la nota', () {
      for (final p in vamps) {
        final added = compareScale(modeIntervals(p.mode!))!.added;
        expect(tonesOf(p), containsAll(added), reason: p.id);
        expect([for (final t in modeColorTones(p)) t.semitones], added, reason: p.id);
      }
      String line(String id, int tonic) =>
          explainProgression(byId(id), tonic).firstWhere((l) => l.es.startsWith('El vamp')).es;
      expect(line('mode-dorian', noteIndex('D')), contains('el grado 6 (B) en el IV'));
      expect(line('mode-lydian', noteIndex('F')), contains('el grado #4 (B) en el II'));
      expect(line('mode-mixolydian', noteIndex('G')), contains('el grado b7 (F) en el ♭VII'));
      expect(line('mode-phrygian', noteIndex('E')), contains('el grado b2 (F) en el ♭II'));
      expect(line('mode-locrian', noteIndex('B')), allOf(contains('b2 (C)'), contains('b5 (F)')));
    });
  });

  test('la explicación sale para todas, en las 12 tónicas, sin grados desconocidos', () {
    for (final p in progressions) {
      for (var t = 0; t < 12; t++) {
        final lines = explainProgression(p, t);
        expect(lines, isNotEmpty, reason: '${p.id} ${pitchClassName(t)}');
        expect(lines.first.es, startsWith('Recorrido:'));
      }
    }
  });
}
