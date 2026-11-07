import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Las notas partidas en grupos de cuatro (una cuerda cada uno).
  List<List<TabNote>> groups(List<TabNote> notes) => [
    for (var i = 0; i < notes.length; i += 4) notes.sublist(i, i + 4),
  ];

  test('cada grupo es una cuerda y un dedo por traste en cuatro trastes', () {
    for (final e in TechniqueExercise.values) {
      for (final start in techniqueStartFrets) {
        final notes = techniqueNotes(e, startFret: start);
        expect(notes.length % 4, 0, reason: e.name);
        for (final g in groups(notes)) {
          expect(g.map((n) => n.string).toSet(), hasLength(1), reason: e.name);
          final frets = g.map((n) => n.fret).toList()..sort();
          expect(frets.last - frets.first, 3, reason: e.name);
          expect(frets.toSet(), hasLength(4), reason: e.name);
        }
        for (final n in notes) {
          expect(n.string, inInclusiveRange(1, 6));
          expect(n.fret, inInclusiveRange(1, 24));
        }
      }
    }
  });

  test('el orden de los trastes sigue a los dedos', () {
    for (final e in TechniqueExercise.values) {
      final fingers = techniqueFingers(e);
      final g = groups(techniqueNotes(e, startFret: 5)).first;
      final low = g.map((n) => n.fret).reduce((a, b) => a < b ? a : b);
      expect([for (final n in g) n.fret - low + 1], fingers, reason: e.name);
    }
    expect(techniqueFingers(TechniqueExercise.spider), [1, 3, 2, 4]);
  });

  test('cromático y araña: de la 6ª a la 1ª y de vuelta, 48 notas', () {
    for (final e in [TechniqueExercise.chromatic, TechniqueExercise.spider]) {
      final notes = techniqueNotes(e);
      expect(notes, hasLength(48));
      final strings = [for (final g in groups(notes)) g.first.string];
      expect(strings, [6, 5, 4, 3, 2, 1, 1, 2, 3, 4, 5, 6]);
      // La vuelta es la ida al revés.
      expect(
        [for (final n in notes.sublist(24)) (n.string, n.fret)],
        [for (final n in notes.sublist(0, 24).reversed) (n.string, n.fret)],
      );
      expect({for (final n in notes) n.fret}, {1, 2, 3, 4});
    }
  });

  test('diagonal: cada cuerda empieza un traste más arriba', () {
    final gs = groups(techniqueNotes(TechniqueExercise.diagonal, startFret: 5));
    expect([for (final g in gs) g.first.string], [6, 5, 4, 3, 2, 1]);
    expect([for (final g in gs) g.first.fret], [5, 6, 7, 8, 9, 10]);
  });

  test('salto de cuerda: 6, 4, 5, 3, 4, 2, 3, 1', () {
    final gs = groups(techniqueNotes(TechniqueExercise.stringSkip));
    expect([for (final g in gs) g.first.string], [6, 4, 5, 3, 4, 2, 3, 1]);
  });

  test('el próximo tempo es el récord más 5, dentro de los límites', () {
    expect(techniqueNextBpm(null), techniqueDefaultBpm);
    expect(techniqueNextBpm(80), 85);
    expect(techniqueNextBpm(techniqueMaxBpm), techniqueMaxBpm);
  });

  test('nombres y explicaciones en los dos idiomas', () {
    for (final e in TechniqueExercise.values) {
      for (final t in [techniqueName(e), techniqueHint(e)]) {
        expect(t.es.trim(), isNotEmpty);
        expect(t.en.trim(), isNotEmpty);
      }
    }
  });
}
