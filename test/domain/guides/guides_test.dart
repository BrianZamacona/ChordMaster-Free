import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/melodies/basics_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/open_chords/open_chords_course.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:chordmaster_free/domain/strumming/strum_pattern.dart';
import 'package:chordmaster_free/domain/strumming/strumming_course.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/chord_data.dart';

void main() {
  final chords = {for (final c in loadChordJson()) c['displayName'] as String: c};
  ChordShape shapeOf(String name) => ChordShape(
    name: name,
    frets: (chords[name]!['fretPositions'] as List).cast<int>(),
    fingers: (chords[name]!['fingerPositions'] as List).cast<int>(),
  );
  final courseStepIds = <LessonCourse, Set<String>>{
    LessonCourse.basics: basicsStepsById.keys.toSet(),
    LessonCourse.melodies: melodyStepsById.keys.toSet(),
    LessonCourse.openChords: {
      for (final s in courseSteps(buildOpenChordsCourse(
        {for (final n in openChordsCourseChords) n: shapeOf(n)},
      )))
        s.id,
    },
    LessonCourse.strumming: {
      for (final s in courseSteps(buildStrummingCourse(
        {for (final n in strummingCourseChords) n: shapeOf(n)},
      )))
        s.id,
    },
  };
  final scalesJson =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  final scales = {
    for (final s in [
      ...scalesJson['scales'] as List<dynamic>,
      ...scalesJson['modes'] as List<dynamic>,
    ])
      (s as Map<String, dynamic>)['id'] as String: s,
  };
  List<int> intervals(String id) =>
      (scales[id]!['intervals'] as List<dynamic>).cast<int>();
  Set<String> notesOf(String id, int root) =>
      {for (final i in intervals(id)) pitchClassName(root + i)};
  List<int> frets(String chord) =>
      (chords[chord]!['fretPositions'] as List<dynamic>).cast<int>();

  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  group('estructura', () {
    test('ids únicos y cada fila con al menos dos guías', () {
      expect(guidesById.length, guides.length);
      for (final c in GuideCategory.values) {
        expect(guidesIn(c).length, greaterThanOrEqualTo(2), reason: c.name);
        expect(guideCategoryTitle(c).es, isNotEmpty);
        expect(guideCategoryTitle(c).en, isNotEmpty);
      }
    });

    test('cada guía tiene al menos dos capítulos y todo en los dos idiomas', () {
      for (final g in guides) {
        expect(g.chapters.length, greaterThanOrEqualTo(2), reason: g.id);
        for (final t in [
          g.title,
          g.subtitle,
          for (final c in g.chapters) ...[c.title, c.body],
        ]) {
          expect(t.es.trim(), isNotEmpty, reason: g.id);
          expect(t.en.trim(), isNotEmpty, reason: g.id);
        }
      }
    });

    test('cada capítulo lleva a algo que existe', () {
      for (final g in guides) {
        for (final c in g.chapters) {
          switch (c.target) {
            case LessonLink(:final lessonId):
              expect(lessonsById.keys, contains(lessonId), reason: g.id);
            case ChordLink(:final chord):
              expect(chords.keys, contains(chord), reason: g.id);
            case ScaleLink(:final scale):
              expect(scales.keys, contains(scale.scaleId), reason: g.id);
              expect(scale.root, inInclusiveRange(0, 11), reason: g.id);
            case WorkoutLink(:final scale):
              expect(scales.keys, contains(scale.scaleId), reason: g.id);
              expect(scale.root, inInclusiveRange(0, 11), reason: g.id);
            case CourseLink(:final course, :final stepId):
              expect(courseStepIds[course], contains(stepId), reason: g.id);
            case ModuleLink():
              break;
          }
        }
      }
    });

    test('el dibujo de cada guía apunta a datos que existen', () {
      for (final g in guides) {
        switch (g.art) {
          case ChordArt(:final chord):
            expect(chords.keys, contains(chord), reason: g.id);
          case ScaleArt(:final scale):
            expect(scales.keys, contains(scale.scaleId), reason: g.id);
          case StrumArt(:final pattern):
            expect(pattern, matches(RegExp(r'^[DU ]+$')), reason: g.id);
          case NotesArt(:final notes):
            expect(noteNames, containsAll(notes), reason: g.id);
        }
      }
    });

    test('ninguna nota con bemol en los textos', () {
      final flatNote = RegExp(r'\b[A-G]b\b');
      for (final g in guides) {
        for (final c in g.chapters) {
          expect(c.body.es, isNot(matches(flatNote)), reason: g.id);
          expect(c.body.en, isNot(matches(flatNote)), reason: g.id);
        }
      }
    });
  });

  group('lo que afirman las guías', () {
    test('calentamientos: araña 1-3-2-4 y diagonal un traste más por cuerda', () {
      expect(techniqueFingers(TechniqueExercise.spider), [1, 3, 2, 4]);
      final diagonal = techniqueNotes(TechniqueExercise.diagonal);
      final starts = [for (var i = 0; i < diagonal.length; i += 4) diagonal[i]];
      for (var i = 1; i < starts.length; i++) {
        expect(starts[i].string, starts[i - 1].string - 1);
        expect(starts[i].fret, starts[i - 1].fret + 1);
      }
    });

    test('Asus2: la 3ª se cambia por la 2ª', () {
      expect((chords['Asus2']!['intervals'] as List).cast<int>(), [0, 2, 7]);
    });

    test('blues en A: A7, D7 y E7 son I, IV y V', () {
      expect(pitchClassName(noteIndex('A') + 5), 'D');
      expect(pitchClassName(noteIndex('A') + 7), 'E');
      for (final c in ['A7', 'D7', 'E7']) {
        expect(chords.keys, contains(c));
      }
    });

    test('acordes de una tonalidad mayor: I ii iii IV V vi vii°', () {
      final major = intervals('major');
      String quality(int degree) {
        int at(int step) {
          final i = degree + step;
          return major[i % 7] + 12 * (i ~/ 7);
        }

        final third = at(2) - at(0);
        final fifth = at(4) - at(0);
        if (third == 4 && fifth == 7) return 'major';
        if (third == 3 && fifth == 7) return 'minor';
        if (third == 3 && fifth == 6) return 'dim';
        return '?';
      }

      expect(
        [for (var d = 0; d < 7; d++) quality(d)],
        ['major', 'minor', 'minor', 'major', 'major', 'minor', 'dim'],
      );
    });

    test('CAGED: las formas suben por el mástil en el orden C, A, G, E, D', () {
      final positions = (scales['major']!['positions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((p) => p['system_id'] == 'caged')
          .toList();
      int lowest(Map<String, dynamic> p) => (p['coordinates'] as List<dynamic>)
          .map((c) => (c as Map<String, dynamic>)['fret_offset'] as int)
          .reduce((a, b) => a < b ? a : b);
      positions.sort((a, b) => lowest(a).compareTo(lowest(b)));
      expect(
        positions.map((p) => (p['name'] as String).split(' ').last).toList(),
        ['C', 'A', 'G', 'E', 'D'],
      );
    });

    test('F con cejilla es la forma de E un traste más arriba', () {
      expect(frets('F'), [for (final f in frets('E')) f + 1]);
    });

    test('modos: siete, cada uno la escala mayor desde uno de sus grados', () {
      final modes = (scalesJson['modes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(modes, hasLength(7));
      final major = intervals('major');
      for (final (degree, mode) in modes.indexed) {
        final rotated = [
          for (var i = 0; i < 7; i++)
            (major[(degree + i) % 7] - major[degree]) % 12,
        ];
        expect(
          (mode['intervals'] as List<dynamic>).cast<int>(),
          rotated,
          reason: mode['id'] as String,
        );
      }
    });

    test('D dórico y G mixolidio usan las notas de C mayor', () {
      final c = notesOf('major', 0);
      expect(notesOf('dorian', noteIndex('D')), c);
      expect(notesOf('mixolydian', noteIndex('G')), c);
    });

    test('4/4: cuatro negras o, en corcheas, ocho golpes por compás', () {
      expect(strummingPatterns.first.replaceAll(' ', ''), 'DDDD');
      expect(strummingPatterns[1], 'DUDUDUDU');
    });

    test('los capítulos que enlazan un curso dicen lo que hace el paso', () {
      // «Las cuerdas al aire: E, A, D, G, B y E» → Conoce tu guitarra.
      expect(basicsStepsById['b_meet']!.body.es, contains('E, A, D, G, B y E'));
      // «Negras: un golpe por pulso» → Patrón 1, con un acorde.
      expect(strummingPatterns.first, 'D D D D ');
      // «Corcheas: abajo en los números, arriba en las y» → Patrón 2.
      expect(followsPendulum(strummingPatterns[1]), isTrue);
      // «El rasgueo pop: huecos donde la mano pasa sin tocar» → Patrón 4.
      expect(strummingPatterns[3], contains(' '));
    });
  });

  group('búsqueda', () {
    test('sin texto devuelve todas', () {
      expect(searchGuides(''), guides);
      expect(searchGuides('   '), guides);
    });

    test('sin tildes ni mayúsculas: "ARMONIA" encuentra Armonía', () {
      expect(searchGuides('ARMONIA').map((g) => g.id), contains('theory_harmony'));
      expect(foldForSearch('Pentatónica Ñ'), 'pentatonica n');
    });

    test('todas las palabras deben aparecer', () {
      final both = searchGuides('pentatonica menor').map((g) => g.id).toSet();
      expect(both, contains('minor_pentatonic'));
      expect(both, isNot(contains('major_pentatonic')));
    });

    test('busca también en los títulos de capítulo', () {
      expect(searchGuides('boogie').map((g) => g.id), contains('intro_blues'));
    });

    test('en inglés busca en inglés', () {
      CurrentLanguage.value = AppLanguage.en;
      expect(searchGuides('capo').map((g) => g.id), contains('capo'));
      expect(searchGuides('acustica'), isEmpty);
    });

    test('sin coincidencias, lista vacía', () {
      expect(searchGuides('zzzz'), isEmpty);
    });
  });
}
