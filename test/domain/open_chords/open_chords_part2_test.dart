import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/courses/course_songs.dart';
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

  int rootOf(String name) => noteIndex(chord(name)['root'] as String);

  final shapes = {for (final n in openChordsPart2.chords) n: shapeOf(n)};
  final course = buildOpenChordsCourse2(shapes);
  final steps = courseSteps(course);
  OpenChordStep step(String id) => steps.firstWhere((s) => s.id == id);

  group('estructura', () {
    test('orden: cada acorde nuevo y detrás sus cambios; al final, el final', () {
      expect([for (final l in course) l.title.es], [
        'Am', 'Cambio Am – C', 'Cambio Am – Em', 'Cambio Am – G', //
        'E', 'Cambio E – Am', 'Cambio E – D', //
        'A', 'Cambio A – D', 'Cambio A – E', //
        'Final del curso',
      ]);
    });

    test('ids únicos, con su prefijo, y sin chocar con la Parte 1', () {
      final ids = [for (final s in steps) s.id];
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids.every((id) => id.startsWith('oc2_')), isTrue);
      final part1 = {
        for (final s in courseSteps(buildOpenChordsCourse({
          for (final n in openChordsCourseChords) n: shapeOf(n),
        })))
          s.id,
      };
      expect(part1.intersection(ids.toSet()), isEmpty);
      // La Parte 1 conserva sus ids (el progreso guardado y las guías).
      expect(part1, containsAll(['oc_em_howto', 'oc_em_g_practice', 'oc_final_round']));
    });

    test('textos en los dos idiomas; las canciones dicen de dónde son', () {
      for (final s in steps) {
        for (final t in [s.title, s.body, ?s.origin]) {
          expect(t.es.trim(), isNotEmpty, reason: s.id);
          expect(t.en.trim(), isNotEmpty, reason: s.id);
        }
        expect(s.slots.isEmpty, s.kind == CourseStepKind.theory, reason: s.id);
        if (s.kind == CourseStepKind.song) expect(s.origin, isNotNull, reason: s.id);
      }
    });

    test('todo lo que suena es del acorde, entero o a medio armar', () {
      for (final s in steps) {
        for (final shape in [...s.chords, ...s.slots]) {
          for (final m in shape.midi) {
            expect(pitchClasses(shape.name), contains(m % 12), reason: '${s.id} ${shape.name}');
          }
        }
      }
    });

    test('solo se usan acordes ya aprendidos (los de la Parte 1 cuentan)', () {
      final learned = {...openChordsPart2.known};
      for (final level in course) {
        for (final s in level.steps) {
          if (s.content == OpenChordContent.howTo) learned.add(s.chords.single.name);
          for (final shape in s.slots) {
            expect(learned, contains(shape.name), reason: s.id);
          }
        }
      }
    });
  });

  group('cambios', () {
    test('Am → C: índice y medio se quedan; solo el anular viaja', () {
      final c = ChordChange(shapes['Am']!, shapes['C']!);
      expect(c.kept, unorderedEquals([
        (finger: 1, string: 2, fret: 1),
        (finger: 2, string: 4, fret: 2),
      ]));
    });

    test('E → Am: la misma forma, una cuerda más aguda', () {
      final c = ChordChange(shapes['E']!, shapes['Am']!);
      expect(c.kept, isEmpty);
      expect(c.shifted, hasLength(3));
      // (lugar en Am, cuerda en la que estaba en E): una cuerda más grave antes.
      for (final (target, fromString) in c.shifted) {
        expect(fromString, target.string + 1, reason: 'dedo ${target.finger}');
      }
    });
  });

  group('final y canciones', () {
    test('A – D – E – A es I – IV – V – I en A', () {
      final round = step('oc2_final_round');
      expect([for (final c in round.slots.take(4)) c.name], ['A', 'D', 'E', 'A']);
      final a = rootOf('A');
      expect((rootOf('D') - a) % 12, 5);
      expect((rootOf('E') - a) % 12, 7);
    });

    test('Am – G – C – E: el E es la quinta de A (el V que vuelve a Am)', () {
      final round = step('oc2_final_round_2');
      expect([for (final c in round.slots.take(4)) c.name], ['Am', 'G', 'C', 'E']);
      expect((rootOf('E') - rootOf('Am')) % 12, 7);
    });

    test('las canciones: compases, acordes y compás que dice su texto', () {
      for (final (song, chords, beats) in [
        (greensleeves, {'Am', 'G', 'C', 'E'}, 3),
        (wholeWorld, {'A', 'E'}, 4),
        (downInTheValley, {'A', 'E'}, 3),
      ]) {
        final s = step('oc2_song_${song.id}');
        expect({for (final c in s.slots) c.name}, chords, reason: song.id);
        expect(s.beatsPerBar, beats, reason: song.id);
        expect(s.body.es, contains('${song.bars.length} compases en $beats/4'), reason: song.id);
        // Empiezan y terminan en la tónica.
        expect(song.bars.first, song.bars.last, reason: song.id);
      }
    });
  });
}
