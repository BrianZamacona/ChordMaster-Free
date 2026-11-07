import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/scale_workouts.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final data =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  final scales = [
    for (final g in ['scales', 'modes'])
      ...(data[g] as List<dynamic>).cast<Map<String, dynamic>>(),
  ];

  /// Posición en C tal como la da el JSON (los offsets ya están en C).
  List<TabNote> positionOf(Map<String, dynamic> p) => [
    for (final c in (p['coordinates'] as List<dynamic>).cast<Map<String, dynamic>>())
      TabNote(c['string'] as int, c['fret_offset'] as int),
  ];

  /// Ladder de 7 notas ascendentes en la 1ª cuerda: C D E F G A B.
  final simple = [for (final f in [8, 10, 12, 13, 15, 17, 19]) TabNote(1, f)];

  group('patrones', () {
    test('subir y bajar: 2n − 1 notas, sin repetir la de arriba', () {
      final notes = workoutNotes(WorkoutPattern.upDown, simple);
      expect(notes, hasLength(2 * simple.length - 1));
      expect(notes.sublist(0, simple.length), simple);
      expect(notes.last, simple.first);
    });

    test('terceras: cada nota y la que está dos lugares más arriba', () {
      final notes = workoutNotes(WorkoutPattern.thirds, simple);
      expect(notes, hasLength(4 * (simple.length - 2)));
      expect(notes.take(4), [simple[0], simple[2], simple[1], simple[3]]);
      // Al bajar, el mismo dibujo al revés.
      final down = notes.sublist(2 * (simple.length - 2));
      expect(down.take(2), [simple.last, simple[simple.length - 3]]);
    });

    test('grupos de 3 y de 4', () {
      for (final (pattern, size) in [
        (WorkoutPattern.groupsOf3, 3),
        (WorkoutPattern.groupsOf4, 4),
      ]) {
        final notes = workoutNotes(pattern, simple);
        final groups = simple.length - size + 1;
        expect(notes, hasLength(2 * groups * size), reason: '$size');
        expect(notes.take(size), simple.take(size), reason: '$size');
        expect(notes.skip(size).take(size), simple.skip(1).take(size), reason: '$size');
      }
    });

    test('escaleras demasiado cortas no dan patrón', () {
      final two = simple.take(2).toList();
      expect(workoutNotes(WorkoutPattern.thirds, two), isEmpty);
      expect(workoutNotes(WorkoutPattern.groupsOf4, simple.take(3).toList()), isEmpty);
    });

    test('cada nivel tiene patrones y un tempo que sube con el nivel', () {
      for (final level in WorkoutLevel.values) {
        expect(workoutPatterns[level], isNotEmpty);
      }
      expect(workoutBpm[WorkoutLevel.beginner], lessThan(workoutBpm[WorkoutLevel.intermediate]!));
      expect(workoutBpm[WorkoutLevel.intermediate], lessThan(workoutBpm[WorkoutLevel.advanced]!));
    });
  });

  group('sobre los datos reales', () {
    test('la escalera ordena por altura y no repite alturas', () {
      for (final s in scales) {
        for (final p in (s['positions'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          final ladder = positionLadder(positionOf(p));
          final pitches = ladder.map(tabMidi).toList();
          expect(pitches, [...pitches]..sort(), reason: '${s['id']}/${p['id']}');
          expect(pitches.toSet().length, pitches.length, reason: '${s['id']}/${p['id']}');
        }
      }
    });

    test('cada nota de cada rutina pertenece a la escala (en C)', () {
      for (final s in scales) {
        final allowed = {for (final i in (s['intervals'] as List<dynamic>).cast<int>()) i % 12};
        for (final p in (s['positions'] as List<dynamic>).cast<Map<String, dynamic>>()) {
          final ladder = positionLadder(positionOf(p));
          for (final pattern in WorkoutPattern.values) {
            for (final n in workoutNotes(pattern, ladder)) {
              expect(
                allowed,
                contains(tabMidi(n) % 12),
                reason: '${s['id']}/${p['id']}/${pattern.name}',
              );
            }
          }
        }
      }
    });

    test('cada escala tiene posiciones en su sistema de rutinas', () {
      for (final s in scales) {
        final system = workoutSystemFor(
          (s['intervals'] as List<dynamic>).cast<int>(),
          s['id'] as String,
        );
        final positions = (s['positions'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .where((p) => p['system_id'] == system);
        expect(positions, isNotEmpty, reason: '${s['id']} $system');
        // Todas dan al menos cuatro notas: hay patrón en todos los niveles.
        for (final p in positions) {
          expect(positionLadder(positionOf(p)).length, greaterThanOrEqualTo(4));
        }
      }
    });

    test('3NPS en C mayor: 18 notas, tres por cuerda', () {
      final major = scales.firstWhere((s) => s['id'] == 'major');
      final p = (major['positions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['system_id'] == 'three_nps');
      final ladder = positionLadder(positionOf(p));
      expect(ladder, hasLength(18));
      for (var string = 1; string <= 6; string++) {
        expect(ladder.where((n) => n.string == string), hasLength(3));
      }
    });
  });

  group('reproducción', () {
    const tab = [TabNote(1, 0), TabNote(1, 1), TabNote(2, 3)];

    test('una nota por corchea al tempo pedido', () {
      expect(tabEvents(tab, bpm: 60), [
        (midi: 64, at: 0.0),
        (midi: 65, at: 0.5),
        (midi: 62, at: 1.0),
      ]);
      expect(tabStepSeconds(120), 0.25);
    });

    test('dura hasta que se apaga la última nota', () {
      expect(tabDurationSeconds(3, bpm: 60), closeTo(1.0 + tabNoteRingSeconds, 1e-9));
      expect(tabDurationSeconds(0, bpm: 60), 0);
    });

    test('la nota marcada es la que suena en ese instante', () {
      expect(tabIndexAt(-0.1, 3, bpm: 60), isNull);
      expect(tabIndexAt(0, 3, bpm: 60), 0);
      expect(tabIndexAt(0.49, 3, bpm: 60), 0);
      expect(tabIndexAt(0.5, 3, bpm: 60), 1);
      expect(tabIndexAt(1.2, 3, bpm: 60), 2);
      expect(tabIndexAt(1.5, 3, bpm: 60), isNull);
    });

    test('la clave del audio es corta y estable', () {
      final a = stableKey('notes-64@0.0-65@0.5');
      expect(a, stableKey('notes-64@0.0-65@0.5'));
      expect(a, hasLength(8));
      expect(a, isNot(stableKey('notes-64@0.0-65@0.6')));
    });

    test('con ring cada nota suena a lo sumo esos segundos', () {
      final long = renderNotes(const [(midi: 64, at: 0.0)], seconds: 2);
      final short = renderNotes(const [(midi: 64, at: 0.0)], seconds: 2, ring: 0.5);
      expect(short.length, long.length);
      final cut = (0.6 * synthSampleRate).round();
      expect(short.sublist(cut).every((v) => v == 0), isTrue);
      expect(long.sublist(cut).any((v) => v != 0), isTrue);
    });
  });
}
