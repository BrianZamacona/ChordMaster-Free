import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/strumming/strum_pattern.dart';
import 'package:chordmaster_free/domain/strumming/strumming_course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  ChordShape shapeOf(String name) {
    final c = json.firstWhere((c) => c['displayName'] == name);
    return ChordShape(
      name: name,
      frets: (c['fretPositions'] as List).cast<int>(),
      fingers: (c['fingerPositions'] as List).cast<int>(),
    );
  }

  final shapes = {for (final n in strummingCourseChords) n: shapeOf(n)};
  final course = buildStrummingCourse(shapes);
  final steps = courseSteps(course);
  StrumStep step(String id) => steps.firstWhere((s) => s.id == id);

  group('patrones', () {
    test('cinco compases de 4/4 (8 corcheas) con solo D, U o espacio', () {
      expect(strummingPatterns, hasLength(5));
      for (final p in strummingPatterns) {
        expect(p, hasLength(8));
        expect(RegExp(r'^[DU ]+$').hasMatch(p), isTrue, reason: p);
      }
    });

    test('todos siguen el péndulo: abajo en los números, arriba en las «y»', () {
      for (final p in strummingPatterns) {
        expect(followsPendulum(p), isTrue, reason: p);
      }
      expect(followsPendulum('UD      '), isFalse);
    });

    test('golpes por compás', () {
      expect([for (final p in strummingPatterns) strokeCount(p)], [4, 8, 6, 6, 6]);
    });

    test('el conteo de 4/4 y de 6/8', () {
      expect([for (var i = 0; i < 8; i++) strumCountAt('DUDUDUDU', i, 'y')],
          ['1', 'y', '2', 'y', '3', 'y', '4', 'y']);
      expect(strumCountAt('DUUDUU', 4, 'y'), '5');
    });
  });

  group('textos generados', () {
    test('patrón 1: abajo en los cuatro números, nada arriba', () {
      final t = patternText(strummingPatterns[0]).es;
      expect(t, contains('Abajo en 1, 2, 3 y 4'));
      expect(t, contains('ningún golpe hacia arriba'));
      expect(t, contains('4 golpes por compás'));
    });

    test('patrón 4 (pop): el 3 sin tocar', () {
      final p = strummingPatterns[3];
      expect(patternText(p).es, contains('arriba en la «y» del 2, la «y» del 3 y la «y» del 4'));
      expect(hintsText(p).es, contains('En el 3 la mano baja sin tocar'));
      expect(hintsText(strummingPatterns[1]).es, isNot(contains('baja sin tocar')));
    });

    test('patrón 3: las «y» del 1 y del 3 pasan sin tocar', () {
      expect(
        patternText(strummingPatterns[2]).es,
        contains('En la «y» del 1 y la «y» del 3 la mano pasa sin tocar'),
      );
    });
  });

  group('curso', () {
    test('orden de los niveles', () {
      expect([for (final l in course) l.title.es], [
        'Patrón 1', 'El patrón 1 en canciones', //
        'Patrón 2', 'El patrón 2 en canciones',
        'Patrón 3', 'El patrón 3 en canciones',
        'Patrón 4', 'El patrón 4 en canciones',
        'Combina los patrones 3 y 4',
        'Patrón 5', 'El patrón 5 en canciones',
        'Final del curso',
      ]);
    });

    test('ids únicos, textos en los dos idiomas y un patrón por compás', () {
      final ids = [for (final s in steps) s.id];
      expect(ids.toSet(), hasLength(ids.length));
      for (final s in steps) {
        for (final t in [s.title, s.body, ?s.origin]) {
          expect(t.es.trim(), isNotEmpty, reason: s.id);
          expect(t.en.trim(), isNotEmpty, reason: s.id);
        }
        if (s.kind == CourseStepKind.theory) {
          expect(s.slots, isEmpty, reason: s.id);
        } else {
          expect(s.slots, isNotEmpty, reason: s.id);
          expect(s.patterns, hasLength(s.slots.length), reason: s.id);
          for (final p in s.patterns) {
            expect(strummingPatterns, contains(p), reason: s.id);
          }
        }
        if (s.kind == CourseStepKind.song) expect(s.origin, isNotNull, reason: s.id);
      }
    });

    test('cada nivel de patrón y sus canciones usan ese patrón', () {
      for (var p = 0; p < strummingPatterns.length; p++) {
        final level = course.firstWhere((l) => l.title.es == 'Patrón ${p + 1}');
        final songs = course.firstWhere((l) => l.title.es == 'El patrón ${p + 1} en canciones');
        for (final s in [...level.steps, ...songs.steps]) {
          for (final used in s.patterns) {
            expect(used, strummingPatterns[p], reason: s.id);
          }
        }
        expect(songs.steps, isNotEmpty);
      }
    });

    test('combinar 3 y 4 alterna los dos patrones compás a compás', () {
      final s = step('sp34_practice');
      expect(s.patterns, [
        strummingPatterns[2], strummingPatterns[3], //
        strummingPatterns[2], strummingPatterns[3],
      ]);
    });

    test('las canciones son de 4/4 y solo con Em, G, D y C', () {
      for (final s in steps.where((s) => s.kind == CourseStepKind.song)) {
        for (final c in s.slots) {
          expect(strummingCourseChords, contains(c.name), reason: s.id);
        }
      }
    });

    test('el tempo y las «y» se explican antes de usarlos', () {
      expect(steps.first.id, 'sp_tempo_beat');
      final ands = steps.indexWhere((s) => s.id == 'sp_count_ands');
      final firstAndOnly = steps.indexWhere((s) => s.patterns.contains(strummingPatterns[2]));
      expect(ands, lessThan(firstAndOnly));
    });
  });

  group('audio', () {
    test('arriba suenan las 4 cuerdas más agudas, de aguda a grave', () {
      final g = shapes['G']!;
      expect(strokeMidi(g, 'D'), g.midi);
      expect(strokeMidi(g, 'U'), g.midi.sublist(2).reversed.toList());
      // D suena en 4 cuerdas: arriba son las mismas cuatro.
      expect(strokeMidi(shapes['D']!, 'U'), shapes['D']!.midi.reversed.toList());
    });

    test('un compás del patrón 4 suena en sus 6 corcheas', () {
      final em = shapes['Em']!;
      final events = strumEvents(
        [em],
        bpm: 60,
        beatsPerSlot: 4,
        patterns: [strummingPatterns[3]],
      );
      final starts = {for (final e in events) (e.at * 2).floor()};
      // A 60 BPM cada corchea dura medio segundo: 0, 2, 3, 5, 6 y 7.
      expect(starts, {0, 2, 3, 5, 6, 7});
      expect(events, hasLength(3 * 6 + 3 * upStrumStrings));
    });

    test('rasgueo apagado: minúscula, mismo sentido y solo el golpe', () {
      const pattern = 'DuduDUdU';
      expect(followsPendulum(pattern), isTrue);
      expect(followsPendulum('uD      '), isFalse);
      expect(strokesAt(pattern, 'D'), [0, 2, 4, 6]);
      expect([for (final s in pattern.split('')) isMutedStroke(s)], [false, true, true, true, false, false, true, false]);
      final em = shapes['Em']!;
      final events = strumEvents([em], bpm: 60, beatsPerSlot: 4, patterns: [pattern]);
      final muted = events.where((e) => e.touch == StringTouch.dead).toList();
      // Dos golpes apagados abajo (6 cuerdas: 2 y 6) y dos arriba (4: 1 y 3).
      expect(muted, hasLength(2 * 6 + 2 * upStrumStrings));
      expect(muted.every((e) => e.seconds < 0.2), isTrue);
      expect({for (final e in muted) (e.at * 2).floor()}, {1, 2, 3, 6});
    });

    test('qué corchea suena', () {
      expect(strumEighthAt(0.6, 2, bpm: 60, beatsPerSlot: 4), 1);
      expect(strumEighthAt(4.2, 2, bpm: 60, beatsPerSlot: 4), 8);
      expect(strumEighthAt(8.1, 2, bpm: 60, beatsPerSlot: 4), isNull);
    });
  });
}
