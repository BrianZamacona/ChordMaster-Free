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

    test('ocho lecciones por camino, sin unidades vacías', () {
      for (final track in LessonTrack.values) {
        expect(lessonsOf(track), hasLength(8), reason: '$track');
      }
    });

    test('cada lección tiene texto en los dos idiomas y al menos dos pasos', () {
      for (final l in curriculum) {
        for (final t in [l.unit, l.title, l.body, ...l.steps]) {
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
