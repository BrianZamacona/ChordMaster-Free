import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/melodies/basics_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/practice/scale_workouts.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
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

  String noteAt(int string, int fret) => pitchClassName(tabMidi(TabNote(string, fret)));
  final courses = {'Primeros pasos': basicsCourse, 'Melodías': melodyCourse};
  MelodyStep basics(String id) => basicsStepsById[id]!;
  MelodyStep melody(String id) => melodyStepsById[id]!;

  group('alturas y tablatura', () {
    test('C4 = 60, G3 = 55, C#5 = 73', () {
      expect(pitchMidi('C4'), 60);
      expect(pitchMidi('G3'), 55);
      expect(pitchMidi('C#5'), 73);
    });

    test('una nota fuera de la ventana o de sus cuerdas es un error del curso', () {
      expect(() => tabForPitches(['C6']), throwsArgumentError);
      expect(() => tabForPitches(['E4'], strings: {3}), throwsArgumentError);
    });

    for (final MapEntry(key: name, value: levels) in courses.entries) {
      test('$name: cada nota suena lo pedido, en su ventana y en sus cuerdas', () {
        for (final s in courseSteps(levels)) {
          final tab = tabForPitches(
            s.pitches,
            minFret: s.minFret,
            maxFret: s.maxFret,
            strings: s.strings,
          );
          expect([for (final n in tab) tabMidi(n)], [for (final p in s.pitches) pitchMidi(p)],
              reason: s.id);
          for (final n in s.tab) {
            expect(n.fret, inInclusiveRange(s.minFret, s.maxFret), reason: s.id);
            if (s.strings case final allowed?) expect(allowed, contains(n.string), reason: s.id);
          }
        }
      });

      test('$name: cada nota de cada nivel pertenece a su escala', () {
        for (final level in levels) {
          final allowed = pitchClasses(level.scale);
          for (final s in level.steps) {
            for (final n in s.tab) {
              expect(allowed, contains(tabMidi(n) % 12), reason: s.id);
            }
          }
        }
      });

      test('$name: teoría sin notas, ejercicios y canciones con al menos 8', () {
        for (final s in courseSteps(levels)) {
          if (s.kind == CourseStepKind.theory) {
            expect(s.pitches, isEmpty, reason: s.id);
          } else {
            expect(s.tab.length, greaterThanOrEqualTo(8), reason: s.id);
          }
          if (s.kind == CourseStepKind.song) expect(s.origin, isNotNull, reason: s.id);
          for (final t in [s.title, s.body, ?s.origin]) {
            expect(t.es.trim(), isNotEmpty, reason: s.id);
            expect(t.en.trim(), isNotEmpty, reason: s.id);
          }
        }
      });
    }

    test('ids únicos entre los dos cursos', () {
      final ids = [for (final l in courses.values) ...courseSteps(l).map((s) => s.id)];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('Primeros pasos: lo que afirman los textos', () {
    test('cuerdas al aire: E, A, D, G, B y E de la 6ª a la 1ª', () {
      expect([for (var s = 6; s >= 1; s--) noteAt(s, 0)], ['E', 'A', 'D', 'G', 'B', 'E']);
      expect(basics('b_meet').body.es, contains('E, A, D, G, B y E'));
      final open = basics('b_open').tab;
      expect([for (final n in open) n.string], [6, 5, 4, 3, 2, 1, 1, 2, 3, 4, 5, 6]);
      expect(open.every((n) => n.fret == 0), isTrue);
    });

    test('1ª cuerda: F en el traste 1 y G en el 3', () {
      expect(noteAt(1, 1), 'F');
      expect(noteAt(1, 3), 'G');
      expect(basics('b_fret_index').tab.every((n) => n.string == 1), isTrue);
      expect({for (final n in basics('b_fret_two').tab) n.fret}, {0, 1, 3});
    });

    test('2ª cuerda: B al aire, C en el 1 y D en el 3; de D a E hay un paso', () {
      expect(noteAt(2, 0), 'B');
      expect(noteAt(2, 1), 'C');
      expect(noteAt(2, 3), 'D');
      const scale = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
      expect(scale.indexOf('E') - scale.indexOf('D'), 1);
    });

    test('3ª cuerda: G al aire y A en el traste 2 (dedo medio), vecinas', () {
      expect(noteAt(3, 0), 'G');
      expect(noteAt(3, 2), 'A');
      expect(basics('b_mid_ga').tab.any((n) => n.string == 3 && n.fret == 2), isTrue);
    });

    test('Hot Cross Buns y Au clair de la lune usan solo E, D y C', () {
      for (final id in ['b_two_buns', 'b_two_lune']) {
        expect(
          {for (final n in basics(id).tab) pitchClassName(tabMidi(n))},
          {'C', 'D', 'E'},
          reason: id,
        );
      }
      final first = basics('b_two_lune').tab.first;
      expect((first.string, first.fret), (2, 1));
    });

    test('cada nivel solo usa las cuerdas que ya se presentaron', () {
      const all = {1, 2, 3, 4, 5, 6}; // el nivel 1 toca las seis al aire
      // Los niveles 2 y 3 solo la 1ª; el 4 suma la 2ª; el 5, la 3ª.
      const allowed = [all, {1}, {1}, {1, 2}, {1, 2, 3}, all];
      for (final (i, level) in basicsCourse.indexed) {
        for (final s in level.steps) {
          for (final n in s.tab) {
            expect(allowed[i], contains(n.string), reason: s.id);
          }
        }
      }
    });
  });

  group('Melodías: lo que afirman los textos', () {
    test('una cuerda: F, G y A en los trastes 1, 3 y 5 de la 1ª', () {
      expect([noteAt(1, 1), noteAt(1, 3), noteAt(1, 5)], ['F', 'G', 'A']);
      for (final (id, string) in [('mo_first', 1), ('mo_second', 2), ('mo_third', 3)]) {
        expect(melody(id).tab.every((n) => n.string == string), isTrue, reason: id);
      }
    });

    test('Himno en la 2ª cuerda: C 1, D 3, E 5, F 6 y G 8', () {
      final tab = melody('mo_ode').tab;
      expect(tab.every((n) => n.string == 2), isTrue);
      expect(
        {for (final n in tab) pitchClassName(tabMidi(n)): n.fret},
        {'C': 1, 'D': 3, 'E': 5, 'F': 6, 'G': 8},
      );
    });

    test('combinar: D del traste 3 de la 2ª y E al aire de la 1ª son vecinas', () {
      expect(noteAt(2, 3), 'D');
      expect(noteAt(1, 0), 'E');
      expect({for (final n in melody('mc_12').tab) n.string}, {1, 2});
      expect({for (final n in melody('mc_23').tab) n.string}, {2, 3});
    });

    test('Estrellita: su A está en el traste 5 de la 1ª', () {
      final a = melody('mc_twinkle').tab.where((n) => pitchClassName(tabMidi(n)) == 'A');
      expect({for (final n in a) (n.string, n.fret)}, {(1, 5)});
    });

    test('Martinillo baja al G al aire de la 3ª cuerda', () {
      expect(melody('mc_frere').tab.any((n) => n.string == 3 && n.fret == 0), isTrue);
    });

    test('de G a G hay ocho notas; ida y vuelta repite la de arriba una vez', () {
      expect(melody('mu_theory').body.es, contains('ocho notas'));
      final ladder = melody('mu_ladder').tab;
      expect(ladder, hasLength(15));
      expect(tabMidi(ladder[7]) - tabMidi(ladder.first), 12);
    });

    test('El puente de Londres baja de G a E y vuelve a subir', () {
      expect(melody('mu_london').pitches.sublist(2, 7), ['G4', 'F4', 'E4', 'F4', 'G4']);
    });

    test('la misma nota en otro lugar: traste 5 de la 3ª = traste 1 de la 2ª', () {
      expect(tabMidi(const TabNote(3, 5)), tabMidi(const TabNote(2, 1)));
      expect(melody('mn_ode').tab.every((n) => n.fret >= 5 && n.fret <= 8), isTrue);
      expect(melody('mn_ode').pitches, melody('mo_ode').pitches);
    });

    test('patrones: grupos de 3 y de 4 como en las rutinas', () {
      expect(melody('mp_groups3').pattern, WorkoutPattern.groupsOf3);
      expect(melody('mp_groups4').pattern, WorkoutPattern.groupsOf4);
      final g3 = melody('mp_groups3').tab.take(6).map((n) => pitchClassName(tabMidi(n)));
      expect(g3, ['G', 'A', 'B', 'A', 'B', 'C']);
    });

    test('velocidad: el tempo sube de 5 en 5, como en Técnica', () {
      expect(techniqueBpmStep, 5);
      expect(melody('ms_theory').body.es, contains('de 5 en 5'));
    });

    test('María usa solo C, D, E y G', () {
      expect(
        {for (final n in melody('mm_mary').tab) pitchClassName(tabMidi(n))},
        {'C', 'D', 'E', 'G'},
      );
    });

    test('el final repite canciones de los niveles 2 y 3 en la posición V', () {
      expect(melody('mf_part1').pitches, melody('mc_twinkle').pitches);
      expect(melody('mf_part2').pitches, melody('mu_london').pitches);
      for (final id in ['mf_part1', 'mf_part2', 'mf_part3']) {
        expect(melody(id).tab.every((n) => n.fret >= 5 && n.fret <= 8), isTrue, reason: id);
      }
    });
  });
}
