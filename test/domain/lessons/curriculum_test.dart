import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/tab_notation.dart';
import 'package:chordmaster_free/domain/theory/circle_of_fifths.dart';
import 'package:chordmaster_free/domain/theory/double_stops.dart';
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
  String tabNote(TabNote n) =>
      pitchClassName(standardOpenStringMidi[n.string - 1] + n.fret);
  List<String> tabOf(String lessonId) =>
      [for (final n in lessonsById[lessonId]!.tab) tabNote(n)];
  // Cuerdas que cambian entre dos acordes (6 = 6ª … 1 = 1ª) y su traste nuevo.
  Map<int, int> changed(String from, String to) => {
        for (var i = 0; i < 6; i++)
          if (frets(from)[i] != frets(to)[i]) 6 - i: frets(to)[i],
      };
  List<int> intervalsOf(String chord) =>
      (chords[chord]!['intervals'] as List<dynamic>).cast<int>();

  group('estructura', () {
    test('ids únicos', () {
      final ids = curriculum.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('"Parte N" lleva espacio duro: el número no queda solo en un renglón', () {
      final plain = RegExp(r'\bPart(e)? \d');
      for (final u in lessonUnits) {
        expect(u.title.es, isNot(matches(plain)), reason: u.id);
        expect(u.title.en, isNot(matches(plain)), reason: u.id);
      }
    });
    test('Fundamentos son dos cursos; rítmica con 14 lecciones y líder con 18', () {
      expect(lessonsOf(LessonTrack.foundations), isEmpty);
      expect(
        [for (final u in unitsOf(LessonTrack.foundations)) u.course],
        [LessonCourse.basics, LessonCourse.melodies],
      );
      expect(lessonsOf(LessonTrack.rhythm), hasLength(14));
      expect(lessonsOf(LessonTrack.lead), hasLength(18));
    });

    test('niveles: Fundamentos solo el 1; cada camino, el 1 y el 2 en orden', () {
      expect(
        unitsOf(LessonTrack.foundations).map((u) => u.level).toSet(),
        {1},
      );
      for (final track in [LessonTrack.rhythm, LessonTrack.lead]) {
        final levels = unitsOf(track).map((u) => u.level).toList();
        expect(levels, [...levels]..sort(), reason: track.name);
        expect(levels.toSet(), {1, 2}, reason: track.name);
        expect(levelsOf(track), [1, 2], reason: track.name);
      }
    });

    test('cada nivel de cada camino cierra con un reto', () {
      for (final track in [LessonTrack.rhythm, LessonTrack.lead]) {
        for (final level in levelsOf(track)) {
          expect(
            challengesOf(track, level: level),
            hasLength(1),
            reason: '${track.name} $level',
          );
        }
      }
      for (final c in challenges) {
        expect(levelsOf(c.track), contains(c.level), reason: c.id);
      }
    });

    test('el mapa va por filas: los dos caminos tienen los mismos niveles y retos', () {
      for (final level in levelsOf(LessonTrack.rhythm)) {
        expect(
          challengesOf(LessonTrack.rhythm, level: level).length,
          challengesOf(LessonTrack.lead, level: level).length,
          reason: 'nivel $level',
        );
      }
      expect(levelsOf(LessonTrack.rhythm), levelsOf(LessonTrack.lead));
    });

    test('cursos en el mapa: cada uno una vez; rítmica empieza por Acordes abiertos y Rasgueo', () {
      for (final c in LessonCourse.values) {
        expect(lessonUnits.where((u) => u.course == c), hasLength(1), reason: c.name);
      }
      expect(
        [for (final u in unitsOf(LessonTrack.rhythm, level: 1).take(2)) u.course],
        [LessonCourse.openChords, LessonCourse.strumming],
      );
      expect(unitOfCourse(LessonCourse.melodies).track, LessonTrack.foundations);
    });

    test('en el nivel 2 los retos piden más que en el 1', () {
      for (final track in [LessonTrack.rhythm, LessonTrack.lead]) {
        final one = challengesOf(track, level: 1).single;
        final two = challengesOf(track, level: 2).single;
        expect(two.kind, one.kind, reason: track.name);
        expect(two.goal, greaterThan(one.goal), reason: track.name);
      }
      // La precisión es un porcentaje: 95 % se puede conseguir.
      for (final c in challenges.where(
        (c) => c.kind == ChallengeKind.rhythmAccuracy,
      )) {
        expect(c.goal, lessThanOrEqualTo(100), reason: c.id);
      }
    });

    test('los retos de oído nombran el módulo como se llama (en inglés, Ear Training)', () {
      for (final c in challenges.where((c) => c.kind == ChallengeKind.earStreak)) {
        CurrentLanguage.value = AppLanguage.es;
        expect(c.body.es, contains(AppStrings.hubEar), reason: c.id);
        CurrentLanguage.value = AppLanguage.en;
        expect(c.body.en, contains(AppStrings.hubEar), reason: c.id);
        expect(c.body.en, isNot(endsWith('in Ear.')), reason: c.id);
      }
      CurrentLanguage.value = AppLanguage.es;
    });

    test('cada unidad tiene resumen en los dos idiomas', () {
      for (final u in unitsById.values) {
        expect(u.summary.es.trim(), isNotEmpty, reason: u.id);
        expect(u.summary.en.trim(), isNotEmpty, reason: u.id);
      }
    });

    test('tablaturas: cuerdas 1–6, trastes 0–24 y cada nota en su escala', () {
      for (final l in curriculum.where((l) => l.tab.isNotEmpty)) {
        final scale = l.scale;
        expect(scale, isNotNull, reason: '${l.id}: la tablatura pide escala');
        final allowed = notesOf(scale!.scaleId, scale.root);
        for (final n in l.tab) {
          expect(n.string, inInclusiveRange(1, 6), reason: l.id);
          expect(n.fret, inInclusiveRange(0, 24), reason: l.id);
          expect(allowed, contains(tabNote(n)), reason: '${l.id}: ${n.string}/${n.fret}');
        }
      }
    });

    test('unidades: ids únicos, al menos dos lecciones y contiguas en el orden', () {
      final units = [for (final t in LessonTrack.values) ...unitsOf(t)];
      expect(units.map((u) => u.id).toSet().length, units.length);
      expect(unitsById.length, units.length);
      // Toda lección pertenece a una unidad del mapa.
      for (final l in curriculum) {
        expect(lessonUnits, contains(l.unit), reason: l.id);
      }
      for (final u in units) {
        final lessons = lessonsOfUnit(u);
        if (u.course != null) {
          // Un curso ocupa el nodo entero: no tiene lecciones.
          expect(lessons, isEmpty, reason: u.id);
          continue;
        }
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

    test('dos retos en rítmica y dos en líder; Fundamentos no tiene', () {
      expect(challengesOf(LessonTrack.foundations), isEmpty);
      expect(challengesOf(LessonTrack.rhythm), hasLength(2));
      expect(challengesOf(LessonTrack.lead), hasLength(2));
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

    test('los módulos que abre una lección existen como herramienta', () {
      expect(
        {for (final l in curriculum) ?l.tool},
        containsAll([
          LessonTool.tuner,
          LessonTool.metronome,
          LessonTool.progressions,
          LessonTool.doubleStops,
          LessonTool.circle,
        ]),
      );
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

    test('r11: de D a Dm solo cambia la 1ª cuerda, del traste 2 (F#) al 1 (F)', () {
      expect(changed('D', 'Dm'), {1: 1});
      expect(frets('D').last, 2);
      expect(pitchClassName(standardOpenStringMidi.first + 2), 'F#');
      expect(pitchClassName(standardOpenStringMidi.first + 1), 'F');
      // Mayor y menor difieren solo en la 3ª.
      expect(intervalsOf('D'), [0, 4, 7]);
      expect(intervalsOf('Dm'), [0, 3, 7]);
    });

    test('r12: E7 = E con la 4ª al aire (D); A7 = A con la 3ª al aire (G)', () {
      expect(changed('E', 'E7'), {4: 0});
      expect(pitchClassName(standardOpenStringMidi[3]), 'D');
      expect((noteIndex('D') - noteIndex('E')) % 12, 10);
      expect(changed('A', 'A7'), {3: 0});
      expect(pitchClassName(standardOpenStringMidi[2]), 'G');
      expect((noteIndex('G') - noteIndex('A')) % 12, 10);
      for (final c in ['E7', 'A7', 'B7']) {
        expect(intervalsOf(c), [0, 4, 7, 10], reason: c);
      }
    });

    test('r12: B7 lleva a Em porque B es la quinta de E', () {
      expect(pitchClassName(noteIndex('E') + 7), 'B');
    });

    test('r13: Cmaj7 = C sin el dedo 1 (2ª al aire, B); Am7 = Am con la 3ª al aire', () {
      expect(changed('C', 'Cmaj7'), {2: 0});
      expect(fingers('C')[4], 1);
      expect(pitchClassName(standardOpenStringMidi[1]), 'B');
      expect((noteIndex('B') - noteIndex('C')) % 12, 11);
      expect(changed('Am', 'Am7'), {3: 0});
      expect((noteIndex('G') - noteIndex('A')) % 12, 10);
    });

    test('r13: Fmaj7 sin cejilla, solo en las cuatro cuerdas agudas', () {
      expect(frets('Fmaj7').take(2), [-1, -1]);
      expect(frets('Fmaj7').skip(2).every((f) => f >= 0), isTrue);
      expect(fingers('Fmaj7').where((f) => f == 1), hasLength(1));
      expect(intervalsOf('Fmaj7'), [0, 4, 7, 11]);
    });

    test('r14: 6/8 = seis corcheas en dos grupos de tres', () {
      final pattern = lessonsById['r14_six_eight']!.strumPattern!;
      expect(pattern.length, 6);
      expect(pattern[0], 'D');
      expect(pattern[3], 'D');
    });

    test('r16: tónicas E, G y A, de E pentatónica menor; E5 y G5 en la 6ª, A5 en la 5ª', () {
      expect(tabOf('r16_power_riff'), ['E', 'G', 'A', 'E']);
      expect(notesOf('pentatonic_minor', noteIndex('E')), containsAll(['E', 'G', 'A']));
      expect(frets('E5').first, 0);
      expect(frets('G5').first, 3);
      expect(frets('A5').take(2), [-1, 0]);
    });

    test('r17: boogie en A, 4ª cuerda traste 2 = E (5ª) y traste 4 = F# (6ª)', () {
      expect(tabOf('r17_boogie'), ['A', 'E', 'A', 'E', 'A', 'F#', 'A', 'F#']);
      expect(pitchClassName(noteIndex('A') + 7), 'E');
      expect(pitchClassName(noteIndex('A') + 9), 'F#');
      // Llevado a D (4ª al aire + 3ª) y a E (6ª al aire + 5ª): misma 5ª y 6ª.
      String on(int string, int fret) =>
          pitchClassName(standardOpenStringMidi[string - 1] + fret);
      expect([on(4, 0), on(3, 2), on(3, 4)], ['D', 'A', 'B']);
      expect([pitchClassName(noteIndex('D') + 7), pitchClassName(noteIndex('D') + 9)], ['A', 'B']);
      expect([on(6, 0), on(5, 2), on(5, 4)], ['E', 'B', 'C#']);
      expect([pitchClassName(noteIndex('E') + 7), pitchClassName(noteIndex('E') + 9)], ['B', 'C#']);
    });

    test('l11: A G E D en la 1ª caja y el bend de un tono lleva D a E', () {
      expect(tabOf('l11_bend_lick'), ['A', 'G', 'E', 'D']);
      final last = lessonsById['l11_bend_lick']!.tab.last;
      expect((last.string, last.fret), (3, 7));
      // La tablatura lo marca: bend de un tono (2 semitonos), solo en la última.
      expect((last.technique, last.bend), (TabTechnique.bend, 2));
      expect(
        lessonsById['l11_bend_lick']!.tab.where((n) => n.technique == TabTechnique.bend),
        hasLength(1),
      );
      expect(pitchClassName(noteIndex('D') + 2), 'E');
      expect(notesOf('pentatonic_minor', noteIndex('A')), contains('E'));
    });

    test('l12: ligados de 5 a 7: C a D en la 3ª, G a A en la 4ª', () {
      expect(tabOf('l12_legato_lick'), ['C', 'D', 'G', 'A']);
      // La púa toca la primera de cada par; la segunda es un hammer-on.
      expect([for (final n in lessonsById['l12_legato_lick']!.tab) n.technique], [
        TabTechnique.none,
        TabTechnique.hammerOn,
        TabTechnique.none,
        TabTechnique.hammerOn,
      ]);
    });

    test('toda tablatura de lección está bien escrita (ligados, bends, silencios)', () {
      for (final l in curriculum) {
        expect(tabNotationProblems(l.tab), isEmpty, reason: l.id);
      }
    });

    test('l13: la pregunta acaba en G y la respuesta en A, la tónica', () {
      final notes = tabOf('l13_call_response');
      expect(notes[1], 'G');
      expect(notes.last, 'A');
      expect(lessonsById['l13_call_response']!.scale!.root, noteIndex('A'));
    });

    test('l14: fórmula T T S T T T S; G mayor = G A B C D E F#, desde el traste 3 de la 6ª', () {
      final intervals = [...scaleIntervals['major']!, 12];
      expect(
        [for (var i = 1; i < intervals.length; i++) intervals[i] - intervals[i - 1]],
        [2, 2, 1, 2, 2, 2, 1],
      );
      expect(
        [for (final i in scaleIntervals['major']!) pitchClassName(noteIndex('G') + i)],
        ['G', 'A', 'B', 'C', 'D', 'E', 'F#'],
      );
      expect(pitchClassName(standardOpenStringMidi.last + 3), 'G');
    });

    test('l15: E menor natural = notas de G mayor; la relativa está 3 semitonos abajo', () {
      expect(
        notesOf('natural_minor', noteIndex('E')),
        notesOf('major', noteIndex('G')),
      );
      expect((noteIndex('G') - noteIndex('E')) % 12, 3);
    });

    test('l16: G a la derecha de C, un ♯ (F#) y 6 notas en común', () {
      expect(circleOrder[1], noteIndex('G'));
      expect(keySignatureAt(1).count, 1);
      expect(keySignatureAt(1).accidental, Accidental.sharp);
      expect(addedAccidentalAt(1)!.pitchClass, noteIndex('F#'));
      expect(commonNoteCount(noteIndex('C'), noteIndex('G')), 6);
    });

    Map<int, int> distanceByDegree(DiatonicDoubleStopInterval interval) => {
          for (final g in findDiatonicDoubleStopPairs('C', interval, const FretRange(0, 12)))
            for (final p in g.pairs) p.degree!: p.distance,
        };

    test('l17: en C, terceras mayores en I, IV y V; menores en II, III, VI y VII', () {
      expect(distanceByDegree(DiatonicDoubleStopInterval.third), {
        1: 4, 2: 3, 3: 3, 4: 4, 5: 4, 6: 3, 7: 3, //
      });
      // Las cuerdas 1 y 2 tienen terceras.
      expect(
        findDiatonicDoubleStopPairs('C', DiatonicDoubleStopInterval.third, const FretRange(0, 12))
            .firstWhere((g) => g.stringPair == (0, 1))
            .pairs,
        isNotEmpty,
      );
    });

    test('l18: en C, sextas mayores en I, II, IV y V; menores en III, VI y VII; saltando una cuerda', () {
      expect(distanceByDegree(DiatonicDoubleStopInterval.sixth), {
        1: 9, 2: 9, 3: 8, 4: 9, 5: 9, 6: 8, 7: 8, //
      });
      final groups = findDiatonicDoubleStopPairs(
        'C',
        DiatonicDoubleStopInterval.sixth,
        const FretRange(0, 12),
      );
      expect(groups.every((g) => g.stringPair.$2 - g.stringPair.$1 == 2), isTrue);
      expect(groups.firstWhere((g) => g.stringPair == (0, 2)).pairs, isNotEmpty);
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
