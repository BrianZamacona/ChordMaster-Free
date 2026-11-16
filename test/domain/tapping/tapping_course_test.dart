import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/tab_notation.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/tapping/tapping_course.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scalesJson =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map<String, dynamic>;
  Set<int> pitchClasses(LessonScale scale) {
    final s = [
      ...scalesJson['scales'] as List,
      ...scalesJson['modes'] as List,
    ].cast<Map<String, dynamic>>().firstWhere((s) => s['id'] == scale.scaleId);
    return {for (final i in (s['intervals'] as List).cast<int>()) (scale.root + i) % 12};
  }

  String noteAt(int string, int fret) => pitchClassName(tabMidi(TabNote(string, fret)));
  TappingStep step(String id) => tappingStepsById[id]!;
  final steps = courseSteps(tappingCourse);
  // La mano derecha golpea el tap y el armónico con tap; lo demás es de la izquierda.
  bool right(TabNote n) => n.technique == TabTechnique.tap || n.technique == TabTechnique.tapHarmonic;
  Iterable<TabNote> taps(TappingStep s) => s.tab.where((n) => n.technique == TabTechnique.tap);
  Iterable<TabNote> left(TappingStep s) => s.tab.where((n) => !right(n));
  Set<int> frets(Iterable<TabNote> notes) => {for (final n in notes) n.fret};
  Set<String> names(Iterable<TabNote> notes) => {for (final n in notes) pitchClassName(tabMidi(n))};

  group('la escritura', () {
    test('ningún tresillo queda partido entre dos renglones (pierde su llave «3»)', () {
      var cutBefore = 0;
      for (final s in steps) {
        final starts = tabLineStarts(s.tab);
        for (final g in tabTripletGroups(s.tab)) {
          expect(tabLineOf(starts, g.first), tabLineOf(starts, g.last), reason: s.id);
          // Con renglones de 8 justas, este grupo se partía.
          if (g.first ~/ tabNotesPerLine != g.last ~/ tabNotesPerLine) cutBefore++;
        }
      }
      expect(cutBefore, greaterThan(0));
    });

    test('ids únicos; teoría sin notas; ejercicios con tablatura bien escrita', () {
      expect(tappingStepsById, hasLength(steps.length));
      for (final s in steps) {
        if (s.kind == CourseStepKind.theory) {
          expect(s.tab, isEmpty, reason: s.id);
        } else {
          expect(s.kind, CourseStepKind.exercise, reason: s.id);
          expect(s.tab.length, greaterThanOrEqualTo(8), reason: s.id);
          expect(tabNotationProblems(s.tab), isEmpty, reason: s.id);
        }
        for (final t in [s.title, s.body]) {
          expect(t.es, isNotEmpty, reason: s.id);
          expect(t.en, isNotEmpty, reason: s.id);
        }
      }
    });

    test('cada ejercicio dura dos compases de 4/4 y empieza con un tapping (el de armónicos, con la nota pisada)', () {
      for (final s in steps.where((s) => s.tab.isNotEmpty)) {
        expect(tabLength(s.tab), 8 * tabTicksPerBeat, reason: s.id);
        final harmonics = s.tab.any((n) => n.technique == TabTechnique.tapHarmonic);
        expect(s.tab.first.technique, harmonics ? TabTechnique.none : TabTechnique.tap, reason: s.id);
      }
    });

    test('cada nota de cada nivel pertenece a su escala', () {
      for (final level in tappingCourse) {
        final allowed = pitchClasses(level.scale);
        for (final s in level.steps) {
          for (final n in s.tab) {
            expect(allowed, contains(tabMidi(n) % 12), reason: '${s.id}: $n');
          }
        }
      }
    });

    test('la izquierda: cada grupo cabe en cuatro trastes y nunca más de cinco; el tap, más arriba', () {
      int span(Iterable<int> f) => f.reduce((a, b) => a > b ? a : b) - f.reduce((a, b) => a < b ? a : b) + 1;
      for (final s in steps.where((s) => s.tab.isNotEmpty)) {
        final fretted = frets(left(s));
        expect(span(fretted), lessThanOrEqualTo(5), reason: s.id);
        // Lo que pisa la izquierda entre un tap y el siguiente: cabe en la
        // mano y queda más abajo que ese tap.
        var group = <int>[];
        var tap = 25; // antes del primer golpe de la derecha, sin límite
        for (final n in [...s.tab, tapEnd(1, 24)]) {
          if (!right(n)) {
            group.add(n.fret);
            expect(n.fret, lessThan(tap), reason: '${s.id}: $n');
          } else {
            if (group.isNotEmpty) {
              expect(span(group), lessThanOrEqualTo(handSpanFrets), reason: '${s.id}: $group');
            }
            group = [];
            tap = n.fret;
          }
        }
      }
    });

    test('el orden: tap y pull-off → arpegio → una mano se mueve → cuerdas → trino', () {
      expect([for (final s in steps) s.id], [
        'tp1_intro',
        'tp1_tap_pull',
        'tp1_arpeggio',
        'tp1_down',
        'tp2_mute',
        'tp2_left_moves',
        'tp2_right_moves',
        'tp3_nowhere',
        'tp3_two_strings',
        'tp3_down_strings',
        'tp4_trill_idea',
        'tp4_trill',
        'tp4_trill_climb',
        'tp4_final',
        'tp4_harmonics',
      ]);
      // El hammer-on desde la nada aparece después de explicarlo.
      final first = steps.indexWhere((s) => s.tab.any((n) => n.technique == TabTechnique.hammerFromNowhere));
      expect(first, steps.indexWhere((s) => s.id == 'tp3_nowhere') + 2);
    });
  });

  group('en el mapa', () {
    test('última unidad del nivel 2 de líder, después de Double stops', () {
      final unit = unitOfCourse(LessonCourse.tapping);
      expect((unit.track, unit.level), (LessonTrack.lead, 2));
      final lead2 = unitsOf(LessonTrack.lead, level: 2);
      expect(lead2.last, unit);
      expect(lead2[lead2.length - 2].id, 'l_double_stops');
    });
  });

  group('los armónicos con tap', () {
    test('cada uno, 12 trastes arriba de la nota pisada justo antes; suena su octava', () {
      final tab = step('tp4_harmonics').tab;
      final harmonics = [for (final (i, n) in tab.indexed) if (n.technique == TabTechnique.tapHarmonic) i];
      expect(harmonics, hasLength(7));
      for (final i in harmonics) {
        expect((tab[i].string, tab[i].fret), (tab[i - 1].string, tab[i - 1].fret + 12));
        expect(tabMidi(tab[i]), tabMidi(tab[i - 1]) + 12);
      }
    });

    test('lo que dice el texto: las notas y sus trastes, y el cierre en A', () {
      final tab = step('tp4_harmonics').tab;
      final pairs = [
        for (final (i, n) in tab.indexed)
          if (n.technique == TabTechnique.tapHarmonic) (noteAt(n.string, tab[i - 1].fret), tab[i - 1].fret, n.fret),
      ];
      expect(pairs, [('A', 2, 14), ('C', 1, 13), ('E', 5, 17), ('A', 5, 17), ('B', 4, 16), ('G#', 1, 13), ('E', 5, 17)]);
      // A en la 1ª: el cuarto par es de la 1ª cuerda.
      expect(tab[6].string, 1);
      expect(noteAt(tab.last.string, tab.last.fret), 'A');
      // Am y luego E: los cuatro primeros son de Am (A C E), los otros tres de E (E G# B).
      expect({for (final p in pairs.take(4)) p.$1}, {'A', 'C', 'E'});
      expect({for (final p in pairs.skip(4)) p.$1}, {'B', 'G#', 'E'});
    });
  });

  group('lo que dicen los textos', () {
    test('tap y pull-off: 2ª cuerda, índice en el 10 (A) y tapping en el 17 (E)', () {
      final s = step('tp1_tap_pull');
      expect({for (final n in s.tab) n.string}, {2});
      expect(frets(left(s)), {10});
      expect(frets(taps(s)), {17});
      expect((noteAt(2, 10), noteAt(2, 17)), ('A', 'E'));
    });

    test('arpegio de Am: 17, 10 y 13 son E, A y C, en tresillos', () {
      final s = step('tp1_arpeggio');
      expect(s.tab.take(3).map((n) => (n.fret, n.technique)), [
        (17, TabTechnique.tap),
        (10, TabTechnique.pullOff),
        (13, TabTechnique.hammerOn),
      ]);
      expect(noteAt(2, 13), 'C');
      expect(names(s.tab), {'A', 'C', 'E'});
      expect(s.tab.take(21).every((n) => n.length == tabTripletEighth), isTrue);
    });

    test('al revés: tapping en el 17 y dos pull-offs, al 13 y al 10', () {
      final s = step('tp1_down');
      expect(s.tab.take(3).map((n) => (n.fret, n.technique)), [
        (17, TabTechnique.tap),
        (13, TabTechnique.pullOff),
        (10, TabTechnique.pullOff),
      ]);
    });

    test('cambia la izquierda: el tap se queda en el 17; Am (10, 13) y E (9, 12: G# y B)', () {
      final s = step('tp2_left_moves');
      expect(frets(taps(s)), {17});
      expect(frets(left(s)), {9, 10, 12, 13});
      expect((noteAt(2, 9), noteAt(2, 12)), ('G#', 'B'));
      expect(names(s.tab), {'A', 'C', 'E', 'G#', 'B'});
      // E, G# y B: el V de A menor, con la G# de la menor armónica.
      expect((noteIndex('E') - 9) % 12, 7);
      expect(pitchClasses(const LessonScale(scaleId: 'natural_minor', root: 9)), isNot(contains(noteIndex('G#'))));
      expect(pitchClasses(const LessonScale(scaleId: 'harmonic_minor', root: 9)), contains(noteIndex('G#')));
    });

    test('mueve la derecha: la izquierda en 10 y 13; el tap en 17 (E), 18 (F) y 15 (D)', () {
      final s = step('tp2_right_moves');
      expect(frets(left(s)), {10, 13});
      expect(frets(taps(s)), {15, 17, 18});
      expect((noteAt(2, 18), noteAt(2, 15)), ('F', 'D'));
    });

    test('dos cuerdas: tap en el 17; 1ª 17-12-15 (A E G), 2ª 17-13-15 (E C D)', () {
      final s = step('tp3_two_strings');
      expect(frets(taps(s)), {17});
      expect(frets(left(s)), {12, 13, 15});
      expect([noteAt(1, 17), noteAt(1, 12), noteAt(1, 15)], ['A', 'E', 'G']);
      expect([noteAt(2, 17), noteAt(2, 13), noteAt(2, 15)], ['E', 'C', 'D']);
      expect({for (final n in s.tab) n.string}, {1, 2});
    });

    test('bajando de cuerda: tap y pull-off, y en la cuerda de abajo desde la nada y hammer-on', () {
      final s = step('tp3_down_strings');
      expect(frets(taps(s)), {17});
      expect({for (final n in s.tab) n.string}, {1, 2, 3, 4});
      for (var i = 0; i + 4 < s.tab.length; i += 4) {
        final g = s.tab.sublist(i, i + 4);
        expect([for (final n in g) n.technique], [
          TabTechnique.tap,
          TabTechnique.pullOff,
          TabTechnique.hammerFromNowhere,
          TabTechnique.hammerOn,
        ]);
        expect(g[2].string, g[0].string + 1);
        expect(g.every((n) => n.length == tabSixteenth), isTrue);
      }
    });

    test('trino: 2ª cuerda, tapping en el 17 (E) y pull-off al 13 (C), en semicorcheas', () {
      final s = step('tp4_trill');
      expect(frets(taps(s)), {17});
      expect(frets(left(s)), {13});
      expect(s.tab.take(28).every((n) => n.length == tabSixteenth), isTrue);
    });

    test('el trino sube: 15-12 (D B), 17-13 (E C), 18-15 (F D)', () {
      final s = step('tp4_trill_climb');
      final pairs = <(int, int)>[];
      for (var i = 0; i + 1 < s.tab.length; i += 2) {
        final pair = (s.tab[i].fret, s.tab[i + 1].fret);
        if (pairs.isEmpty || pairs.last != pair) pairs.add(pair);
      }
      expect(pairs.take(3), [(15, 12), (17, 13), (18, 15)]);
      expect([noteAt(2, 15), noteAt(2, 12), noteAt(2, 18)], ['D', 'B', 'F']);
    });

    test('todo junto: Am y E en tresillos, el trino de E y C y el A del traste 10', () {
      final s = step('tp4_final');
      expect(s.tab.take(12).every((n) => n.length == tabTripletEighth), isTrue);
      expect(names(s.tab.take(6)), {'A', 'C', 'E'});
      expect(names(s.tab.skip(6).take(6)), {'E', 'G#', 'B'});
      expect(names(s.tab.skip(12).take(12)), {'E', 'C'});
      expect((s.tab.last.fret, noteAt(2, s.tab.last.fret)), (10, 'A'));
    });

    test('los niveles 1 y 3: A menor natural y pentatónica de A menor', () {
      expect(tappingCourse[0].scale.scaleId, 'natural_minor');
      expect(tappingCourse[2].scale.scaleId, 'pentatonic_minor');
      expect([for (final l in tappingCourse) l.scale.root], everyElement(9));
    });
  });
}
