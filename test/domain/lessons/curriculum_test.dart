import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/chord_data.dart';

void main() {
  final chords = {for (final c in loadChordJson()) c['displayName'] as String: c};
  final scalesJson =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  final scaleIntervals = {
    for (final s in [
      ...scalesJson['scales'] as List<dynamic>,
      ...scalesJson['modes'] as List<dynamic>,
    ])
      (s as Map<String, dynamic>)['id'] as String:
          (s['intervals'] as List<dynamic>).cast<int>(),
  };

  // fretPositions van de 6ª a 1ª cuerda: índice 0 = 6ª.
  List<int> frets(String name) =>
      (chords[name]!['fretPositions'] as List<dynamic>).cast<int>();
  List<int> fingers(String name) =>
      (chords[name]!['fingerPositions'] as List<dynamic>).cast<int>();
  int stringOfFinger(String chord, int finger) =>
      6 - fingers(chord).indexOf(finger);
  Set<String> notesOf(String scaleId, int root) =>
      {for (final i in scaleIntervals[scaleId]!) pitchClassName(root + i)};

  group('estructura', () {
    test('ids únicos', () {
      final ids = curriculum.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('Fundamentos con 8 lecciones; rítmica y líder con 10', () {
      expect(lessonsOf(LessonTrack.foundations), hasLength(8));
      expect(lessonsOf(LessonTrack.rhythm), hasLength(10));
      expect(lessonsOf(LessonTrack.lead), hasLength(10));
    });

    test('unidades: ids únicos, al menos dos lecciones y contiguas en el orden', () {
      final units = [for (final t in LessonTrack.values) ...unitsOf(t)];
      expect(units.map((u) => u.id).toSet().length, units.length);
      expect(unitsById.length, units.length);
      for (final u in units) {
        final lessons = lessonsOfUnit(u);
        expect(lessons.length, greaterThanOrEqualTo(2), reason: u.id);
        // Las lecciones de una unidad van seguidas en el currículo.
        final first = curriculum.indexOf(lessons.first);
        expect(curriculum.sublist(first, first + lessons.length), lessons, reason: u.id);
      }
    });

    test('el arte de cada unidad apunta a datos que existen', () {
      for (final u in unitsById.values) {
        switch (u.art) {
          case ChordArt(:final chord):
            expect(chords.keys, contains(chord), reason: u.id);
          case ScaleArt(:final scale):
            expect(scaleIntervals.keys, contains(scale.scaleId), reason: u.id);
          case StrumArt(:final pattern):
            expect(pattern, matches(RegExp(r'^[DU ]+$')), reason: u.id);
          case NotesArt(:final notes):
            expect(noteNames, containsAll(notes), reason: u.id);
        }
      }
    });

    test('un reto al final de rítmica y otro de líder; Fundamentos no tiene', () {
      expect(challengesOf(LessonTrack.foundations), isEmpty);
      expect(challengesOf(LessonTrack.rhythm), hasLength(1));
      expect(challengesOf(LessonTrack.lead), hasLength(1));
      final ids = challenges.map((c) => c.id).toSet();
      expect(ids.length, challenges.length);
      expect(ids.intersection(lessonsById.keys.toSet()), isEmpty);
      for (final c in challenges) {
        expect(c.goal, greaterThan(0), reason: c.id);
        expect(c.isPassed(c.goal), isTrue);
        expect(c.isPassed(c.goal - 1), isFalse);
      }
    });

    test('cada lección tiene texto en los dos idiomas y al menos dos pasos', () {
      for (final l in curriculum) {
        for (final t in [l.unit.title, l.title, l.body, ...l.steps]) {
          expect(t.es.trim(), isNotEmpty, reason: l.id);
          expect(t.en.trim(), isNotEmpty, reason: l.id);
        }
        expect(l.steps.length, greaterThanOrEqualTo(2), reason: l.id);
        expect(l.minutes, inInclusiveRange(1, 30), reason: l.id);
      }
    });

    test('todos los acordes existen en chords.json', () {
      for (final l in curriculum) {
        for (final c in l.chords) {
          expect(chords.keys, contains(c), reason: '${l.id}: $c');
        }
      }
    });

    test('todas las escalas existen en scales_master.json', () {
      for (final l in curriculum) {
        if (l.scale case final s?) {
          expect(scaleIntervals.keys, contains(s.scaleId), reason: l.id);
          expect(s.root, inInclusiveRange(0, 11), reason: l.id);
        }
      }
    });

    test('rasgueos: solo D, U o espacio, en compases completos', () {
      for (final l in curriculum) {
        if (l.strumPattern case final p?) {
          expect(p, matches(RegExp(r'^[DU ]+$')), reason: l.id);
          expect([6, 8], contains(p.length), reason: l.id);
        }
      }
    });

    test('el tempo sugerido solo va con el metrónomo', () {
      for (final l in curriculum) {
        if (l.bpm != null) {
          expect(l.tool, LessonTool.metronome, reason: l.id);
          expect(l.bpm, inInclusiveRange(40, 200), reason: l.id);
        }
      }
    });

    test('notas con sostenidos: ningún bemol de nota en los textos', () {
      final flatNote = RegExp(r'\b[A-G]b\b');
      for (final l in curriculum) {
        for (final t in [l.title, l.body, ...l.steps]) {
          expect(t.es, isNot(matches(flatNote)), reason: l.id);
          expect(t.en, isNot(matches(flatNote)), reason: l.id);
        }
      }
    });
  });

  group('lo que afirman las lecciones', () {
    test('f1: las cuerdas al aire, de la 6ª a la 1ª, son E A D G B E', () {
      expect(
        standardOpenStringMidi.reversed.map(pitchClassName).toList(),
        ['E', 'A', 'D', 'G', 'B', 'E'],
      );
    });

    test('f3: en Em suenan las seis cuerdas; Am no toca la 6ª', () {
      expect(frets('Em').every((f) => f >= 0), isTrue);
      expect(frets('Am').first, -1);
      expect(frets('Am').skip(1).every((f) => f >= 0), isTrue);
    });

    test('f4: de Em a Am los dedos 2 y 3 bajan una cuerda y el 1 entra en la 2ª', () {
      expect(stringOfFinger('Em', 2), 5);
      expect(stringOfFinger('Em', 3), 4);
      expect(stringOfFinger('Am', 2), 4);
      expect(stringOfFinger('Am', 3), 3);
      expect(stringOfFinger('Am', 1), 2);
    });

    test('f5: D desde la 4ª cuerda, A desde la 5ª, E con las seis', () {
      expect(frets('D').take(2), [-1, -1]);
      expect(frets('D').skip(2).every((f) => f >= 0), isTrue);
      expect(frets('A').first, -1);
      expect(frets('A').skip(1).every((f) => f >= 0), isTrue);
      expect(frets('E').every((f) => f >= 0), isTrue);
    });

    test('f5: E tiene la forma de Am una cuerda más arriba', () {
      // Am desde la 5ª = E desde la 6ª con los mismos trastes y dedos.
      expect(frets('E').take(5), frets('Am').skip(1));
      expect(fingers('E').take(5), fingers('Am').skip(1));
    });

    test('f5: A con los tres dedos en el traste 2', () {
      expect(frets('A').where((f) => f > 0).toSet(), {2});
    });

    test('f6: en G el meñique va en la 1ª cuerda, traste 3', () {
      expect(fingers('G').last, 4);
      expect(frets('G').last, 3);
    });

    test('r5: F cubre las seis cuerdas en el traste 1; Bm de la 5ª a la 1ª en el 2', () {
      expect(frets('F').every((f) => f >= 1), isTrue);
      expect(frets('F').reduce((a, b) => a < b ? a : b), 1);
      expect(fingers('F').first, 1);
      expect(fingers('F').last, 1);
      expect(frets('Bm').first, -1);
      expect(frets('Bm').skip(1).reduce((a, b) => a < b ? a : b), 2);
      expect(fingers('Bm')[1], 1);
      expect(fingers('Bm').last, 1);
    });

    test('r6: un power chord tiene solo tónica y quinta, tónica en la 6ª', () {
      for (final name in ['E5', 'A5', 'G5']) {
        expect((chords[name]!['intervals'] as List).cast<int>(), [0, 7], reason: name);
      }
      expect(frets('G5').first, isNot(-1));
      expect(
        pitchClassName(standardOpenStringMidi.last + frets('G5').first),
        'G',
      );
    });

    test('r9: en Am y en C el bajo está en la 5ª cuerda', () {
      for (final name in ['Am', 'C']) {
        // Primera cuerda que suena, contando desde la 6ª.
        expect(6 - frets(name).indexWhere((f) => f >= 0), 5, reason: name);
      }
    });

    test('r10: bajo alterno en C (5ª = C, 4ª = E) y en G (6ª = G, 4ª = D)', () {
      String noteOn(String chord, int string) => pitchClassName(
            standardOpenStringMidi[string - 1] + frets(chord)[6 - string],
          );
      expect(noteOn('C', 5), 'C');
      expect(noteOn('C', 4), 'E');
      expect(noteOn('G', 6), 'G');
      expect(noteOn('G', 4), 'D');
    });

    test('l9: notas de la 6ª y la 5ª cuerda, y el traste 12 repite la cuerda al aire', () {
      final low = standardOpenStringMidi[5];
      final a = standardOpenStringMidi[4];
      expect(
        {for (final f in [0, 1, 3, 5, 7, 8, 10]) pitchClassName(low + f)}.toList(),
        ['E', 'F', 'G', 'A', 'B', 'C', 'D'],
      );
      expect(
        {for (final f in [0, 2, 3, 5, 7, 8, 10]) pitchClassName(a + f)}.toList(),
        ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
      );
      for (final open in standardOpenStringMidi) {
        expect(pitchClassName(open + 12), pitchClassName(open));
      }
    });

    test('l10: la 2ª caja de A pentatónica menor empieza en el traste 8 de la 6ª, sobre C', () {
      final positions = ((scalesJson['scales'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .firstWhere((s) => s['id'] == 'pentatonic_minor')['positions']
          as List<dynamic>)
          .cast<Map<String, dynamic>>();
      List<int> lowStringOffsets(String id) => [
            for (final c in (positions.firstWhere((p) => p['id'] == id)['coordinates']
                    as List<dynamic>)
                .cast<Map<String, dynamic>>())
              if (c['string'] == 6) c['fret_offset'] as int,
          ];
      // Los offsets están en C; la caja 1 empieza en su tónica.
      final box1Root = lowStringOffsets('box_1').reduce((a, b) => a < b ? a : b);
      final box2Start = lowStringOffsets('box_2').reduce((a, b) => a < b ? a : b);
      const aRootFret = 5; // A en la 6ª cuerda (test de l1).
      final fret = aRootFret + box2Start - box1Root;
      expect(fret, 8);
      expect(pitchClassName(standardOpenStringMidi.last + fret), 'C');
      expect(notesOf('pentatonic_minor', noteIndex('A')), contains('C'));
    });

    test('l1: A pentatónica menor = A C D E G', () {
      expect(notesOf('pentatonic_minor', noteIndex('A')), {'A', 'C', 'D', 'E', 'G'});
    });

    test('l1: la primera caja de A pentatónica menor empieza en el traste 5 de la 6ª', () {
      // 6ª cuerda al aire = E; A está 5 semitonos arriba.
      expect(pitchClassName(standardOpenStringMidi.last + 5), 'A');
    });

    test('l6: blues = pentatónica menor + b5; en A esa nota es D#', () {
      final penta = scaleIntervals['pentatonic_minor']!.toSet();
      final blues = scaleIntervals['blues_minor']!.toSet();
      expect(blues.difference(penta), {6});
      expect(penta.difference(blues), isEmpty);
      expect(pitchClassName(noteIndex('A') + 6), 'D#');
    });

    test('l7: C pentatónica mayor tiene las mismas notas que A pentatónica menor', () {
      expect(
        notesOf('pentatonic_major', noteIndex('C')),
        notesOf('pentatonic_minor', noteIndex('A')),
      );
    });
  });

  test('los textos cambian de idioma con CurrentLanguage', () {
    final lesson = curriculum.first;
    addTearDown(() => CurrentLanguage.value = AppLanguage.es);
    CurrentLanguage.value = AppLanguage.en;
    expect(lesson.title.text, lesson.title.en);
    CurrentLanguage.value = AppLanguage.es;
    expect(lesson.title.text, lesson.title.es);
  });
}
