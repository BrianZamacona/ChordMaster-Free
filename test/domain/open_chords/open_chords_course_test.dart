import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/open_chords/open_chords_course.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  Map<String, dynamic> chord(String name) => json.firstWhere((c) => c['displayName'] == name);
  ChordShape shapeOf(String name) {
    final c = chord(name);
    return ChordShape(
      name: name,
      frets: (c['fretPositions'] as List).cast<int>(),
      fingers: (c['fingerPositions'] as List).cast<int>(),
    );
  }

  Set<int> pitchClasses(String name) {
    final c = chord(name);
    final root = noteIndex(c['root'] as String);
    return {for (final i in (c['intervals'] as List).cast<int>()) (root + i) % 12};
  }

  final shapes = {for (final n in openChordsCourseChords) n: shapeOf(n)};
  final course = buildOpenChordsCourse(shapes);
  final steps = courseSteps(course);
  OpenChordStep step(String id) => steps.firstWhere((s) => s.id == id);

  group('formas', () {
    test('todo lo que suena, entero o a medio armar, es del acorde', () {
      for (final s in steps) {
        for (final shape in [...s.chords, ...s.slots]) {
          final allowed = pitchClasses(shape.name);
          for (final m in shape.midi) {
            expect(allowed, contains(m % 12), reason: '${s.id} ${shape.name}');
          }
        }
      }
    });

    test('a medio armar solo quita cuerdas, no las cambia', () {
      for (final name in openChordsCourseChords) {
        final full = shapes[name]!;
        for (var c = 1; c <= full.fingerOrder.length; c++) {
          final part = full.partial(c);
          for (var i = 0; i < 6; i++) {
            expect(part.frets[i] == -1 || part.frets[i] == full.frets[i], isTrue);
          }
          expect(part.fingerOrder, full.fingerOrder.take(c));
        }
        expect(full.partial(full.fingerOrder.length).frets, full.frets);
      }
    });

    test('Em: medio y anular en el traste 2 de la 5ª y la 4ª', () {
      final em = shapes['Em']!;
      expect(em.placements, [
        (finger: 2, string: 5, fret: 2),
        (finger: 3, string: 4, fret: 2),
      ]);
      expect(em.muted, isEmpty);
      // Solo el medio: la 4ª no se toca todavía.
      expect(em.partial(1).muted, [4]);
    });

    test('D no toca la 6ª ni la 5ª; C no toca la 6ª', () {
      expect(shapes['D']!.muted, [6, 5]);
      expect(shapes['D']!.strumFrom, 4);
      expect(shapes['C']!.muted, [6]);
      expect(shapes['C']!.openNextToFretted, [3, 1]);
    });

    test('C se arma índice, medio y anular', () {
      expect(shapes['C']!.fingerOrder, [1, 2, 3]);
    });
  });

  group('cambios', () {
    test('Em → G: el medio se queda en la 5ª, traste 2', () {
      final c = ChordChange(shapes['Em']!, shapes['G']!);
      expect(c.kept, [(finger: 2, string: 5, fret: 2)]);
    });

    test('C → G: medio y anular bajan una cuerda en su traste', () {
      final c = ChordChange(shapes['C']!, shapes['G']!);
      expect(c.kept, isEmpty);
      expect(c.shifted, [
        ((finger: 2, string: 5, fret: 2), 4),
        ((finger: 3, string: 6, fret: 3), 5),
      ]);
    });

    test('C → Em: la 4ª en el traste 2 se repite con otro dedo', () {
      final c = ChordChange(shapes['C']!, shapes['Em']!);
      expect(c.swapped, [((finger: 3, string: 4, fret: 2), 2)]);
    });

    test('D → G y C → D: ningún dedo se queda (se mueve en bloque)', () {
      for (final (a, b) in [('D', 'G'), ('C', 'D')]) {
        final c = ChordChange(shapes[a]!, shapes[b]!);
        expect([...c.kept, ...c.slid, ...c.shifted], isEmpty, reason: '$a → $b');
        expect(changeText(c).es, contains('como un bloque'));
      }
    });
  });

  group('curso', () {
    test('orden de los niveles', () {
      expect([for (final l in course) l.title.es], [
        'Em', 'G', 'Cambio Em – G', 'D', 'Cambio D – G', 'Cambio D – Em', //
        'C', 'Cambio C – Em', 'Cambio C – G', 'Cambio C – D', 'Final del curso',
      ]);
    });

    test('ids únicos y textos en los dos idiomas', () {
      final ids = [for (final s in steps) s.id];
      expect(ids.toSet(), hasLength(ids.length));
      for (final s in steps) {
        for (final t in [s.title, s.body, ?s.origin]) {
          expect(t.es.trim(), isNotEmpty, reason: s.id);
          expect(t.en.trim(), isNotEmpty, reason: s.id);
        }
        expect(s.slots.isEmpty, s.kind == CourseStepKind.theory, reason: s.id);
        if (s.kind == CourseStepKind.song) expect(s.origin, isNotNull, reason: s.id);
      }
    });

    test('cada canción y ejercicio usa solo acordes ya aprendidos', () {
      final learned = <String>{};
      for (final level in course) {
        for (final s in level.steps) {
          if (s.content == OpenChordContent.howTo) learned.add(s.chords.single.name);
          for (final shape in s.slots) {
            expect(learned, contains(shape.name), reason: s.id);
          }
        }
      }
    });

    test('el final: canciones con G, C y D, y la ronda con los cuatro', () {
      for (final s in course.last.steps.where((s) => s.kind == CourseStepKind.song)) {
        expect({for (final c in s.slots) c.name}, {'G', 'C', 'D'}, reason: s.id);
      }
      expect(
        [for (final c in step('oc_final_round').slots.take(4)) c.name],
        ['G', 'D', 'Em', 'C'],
      );
    });

    test('el cambio a dos pulsos alterna los dos acordes', () {
      final s = step('oc_em_g_finale');
      expect(s.beatsPerSlot, 2);
      expect([for (final c in s.slots.take(4)) c.name], ['Em', 'G', 'Em', 'G']);
    });

    test('Amazing Grace va en 3/4', () {
      final s = step('oc_song_amazing_grace');
      expect(s.beatsPerBar, 3);
      expect(s.beatsPerSlot, 3);
      expect(s.body.es, contains('en 3/4'));
    });

    test('pasos dedo a dedo: uno menos que los dedos del acorde', () {
      for (final name in openChordsCourseChords) {
        final n = shapes[name]!.fingerOrder.length;
        final k = name.toLowerCase();
        expect(steps.where((s) => RegExp('^oc_${k}_f\\d+\$').hasMatch(s.id)), hasLength(n - 1));
      }
      expect(step('oc_em_f1').title.es, 'Solo el dedo medio');
      expect(step('oc_c_f2').title.en, 'Add the middle finger');
    });

    test('textos generados de la forma', () {
      expect(howToPlayText(shapes['D']!).es, contains('no toques la 6ª ni la 5ª'));
      expect(howToPlayText(shapes['Em']!).es, contains('suenan las seis'));
      expect(tipsText(shapes['C']!).es, contains('La 3ª y la 1ª van al aire'));
      expect(
        changeText(ChordChange(shapes['Em']!, shapes['G']!)).es,
        contains('no lo levantes'),
      );
      expect(
        fingerStepText(shapes['Em']!, 1).es,
        contains('sin tocar la 4ª'),
      );
    });
  });

  group('audio', () {
    test('un golpe por pulso; cada cuerda separada', () {
      final em = shapes['Em']!;
      final events = strumEvents([em, em], bpm: 60, beatsPerSlot: 2);
      expect(events, hasLength(4 * 6));
      expect(events.first.at, 0);
      expect(events[6].at, closeTo(1.0, 1e-9)); // segundo pulso a 60 BPM
      expect(events[1].at - events[0].at, closeTo(0.035, 1e-9));
      expect([for (final e in events.take(6)) e.midi], em.midi);
    });

    test('qué forma suena en cada instante', () {
      expect(strumSlotAt(0, 3, bpm: 60, beatsPerSlot: 4), 0);
      expect(strumSlotAt(4.1, 3, bpm: 60, beatsPerSlot: 4), 1);
      expect(strumSlotAt(12.1, 3, bpm: 60, beatsPerSlot: 4), isNull);
      expect(strumSlotAt(-1, 3, bpm: 60, beatsPerSlot: 4), isNull);
    });
  });
}
