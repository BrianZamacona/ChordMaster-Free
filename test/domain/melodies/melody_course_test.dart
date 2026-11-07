import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scalesJson =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  Set<int> pitchClasses(LessonScale scale) {
    final s = [
      ...scalesJson['scales'] as List,
      ...scalesJson['modes'] as List,
    ].cast<Map<String, dynamic>>().firstWhere((s) => s['id'] == scale.scaleId);
    return {for (final i in (s['intervals'] as List).cast<int>()) (scale.root + i) % 12};
  }

  MelodyStep step(String id) => melodyStepsById[id]!;
  (int, int) at(String pitch, {int min = 0, int max = 3}) {
    final n = tabForPitches([pitch], minFret: min, maxFret: max).single;
    return (n.string, n.fret);
  }

  group('alturas y tablatura', () {
    test('C4 = 60, G3 = 55, C#5 = 73', () {
      expect(pitchMidi('C4'), 60);
      expect(pitchMidi('G3'), 55);
      expect(pitchMidi('C#5'), 73);
    });

    test('cada nota suena lo que pide y cae en su ventana', () {
      for (final s in melodyStepsById.values) {
        final tab = tabForPitches(s.pitches, minFret: s.minFret, maxFret: s.maxFret);
        expect([for (final n in tab) tabMidi(n)], [for (final p in s.pitches) pitchMidi(p)],
            reason: s.id);
        for (final n in tab) {
          expect(n.fret, inInclusiveRange(s.minFret, s.maxFret), reason: s.id);
        }
      }
    });

    test('una nota fuera de la ventana es un error del curso', () {
      expect(() => tabForPitches(['C6']), throwsArgumentError);
    });

    test('cada nota de cada nivel pertenece a su escala', () {
      for (final level in melodyCourse) {
        final allowed = pitchClasses(level.scale);
        for (final s in level.steps) {
          for (final n in s.tab) {
            expect(allowed, contains(tabMidi(n) % 12), reason: s.id);
          }
        }
      }
    });
  });

  group('estructura', () {
    test('ids únicos; teoría sin notas; ejercicios y canciones con notas', () {
      final ids = [for (final l in melodyCourse) for (final s in l.steps) s.id];
      expect(ids.toSet(), hasLength(ids.length));
      for (final s in melodyStepsById.values) {
        if (s.kind == MelodyStepKind.theory) {
          expect(s.pitches, isEmpty, reason: s.id);
        } else {
          expect(s.pitches.length, greaterThanOrEqualTo(8), reason: s.id);
        }
        if (s.kind == MelodyStepKind.song) expect(s.origin, isNotNull, reason: s.id);
        for (final t in [s.title, s.body, ?s.origin]) {
          expect(t.es.trim(), isNotEmpty);
          expect(t.en.trim(), isNotEmpty);
        }
      }
    });

    test('estrellas: 60, 80 y 100 BPM', () {
      expect(starsFor(null), 0);
      expect(starsFor(55), 0);
      expect(starsFor(60), 1);
      expect(starsFor(95), 2);
      expect(starsFor(120), 3);
    });
  });

  group('lo que afirman los textos', () {
    test('nivel 1: dónde está cada nota de C mayor', () {
      expect(at('G3'), (3, 0));
      expect(at('A3'), (3, 2));
      expect(at('B3'), (2, 0));
      expect(at('C4'), (2, 1));
      expect(at('D4'), (2, 3));
      expect(at('E4'), (1, 0));
      expect(at('F4'), (1, 1));
      expect(at('G4'), (1, 3));
    });

    test('la escalera va de G a G y de la 3ª cuerda a la 1ª', () {
      final tab = step('m1_ladder').tab;
      expect(tab, hasLength(8));
      expect(tab.first.string, 3);
      expect(tab.last.string, 1);
      expect(tabMidi(tab.last) - tabMidi(tab.first), 12);
    });

    test('Estrellita empieza en el traste 1 de la 2ª y su A está en el 5 de la 1ª', () {
      final tab = step('m1_twinkle').tab;
      expect((tab.first.string, tab.first.fret), (2, 1));
      final a = tab.where((n) => pitchClassName(tabMidi(n)) == 'A').toSet();
      expect({for (final n in a) (n.string, n.fret)}, {(1, 5)});
    });

    test('terceras: de C a E y de D a F hay dos notas de la escala', () {
      const scale = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
      expect(scale.indexOf('E') - scale.indexOf('C'), 2);
      expect(scale.indexOf('F') - scale.indexOf('D'), 2);
      final tab = step('m2_thirds').tab;
      // G-B, A-C, B-D…: cada par sube dos notas de la escalera.
      expect([for (final n in tab.take(4)) pitchClassName(tabMidi(n))], ['G', 'B', 'A', 'C']);
    });

    test('Martinillo baja al G al aire de la 3ª cuerda', () {
      final tab = step('m2_frere').tab;
      expect(tab.any((n) => n.string == 3 && n.fret == 0), isTrue);
    });

    test('posición V: el C del traste 5 de la 3ª es el del traste 1 de la 2ª', () {
      expect(tabMidi(const TabNote(3, 5)), tabMidi(const TabNote(2, 1)));
      final tab = step('m3_ladder').tab;
      expect(tab.first.string, 3);
      expect(tab.last.string, 1);
      expect(step('m3_ode').tab.every((n) => n.fret >= 5 && n.fret <= 8), isTrue);
    });

    test('el Himno arriba es la misma melodía de la lección al aire', () {
      final ode = step('m3_ode');
      expect(ode.pitches.take(8), ['E4', 'E4', 'F4', 'G4', 'G4', 'F4', 'E4', 'D4']);
    });

    test('María usa solo C, D, E y G', () {
      expect(
        {for (final n in step('m4_mary').tab) pitchClassName(tabMidi(n))},
        {'C', 'D', 'E', 'G'},
      );
    });

    test('El puente de Londres baja de G a E y vuelve a subir', () {
      final p = step('m4_london').pitches;
      expect(p.sublist(2, 7), ['G4', 'F4', 'E4', 'F4', 'G4']);
    });
  });
}
