import 'package:chordmaster_free/domain/theory/neck_notes.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const major = [0, 2, 4, 5, 7, 9, 11];
  const minorPentatonic = [0, 3, 5, 7, 10];
  const naturalMinor = [0, 2, 3, 5, 7, 8, 10];

  test('C mayor: ninguna nota fuera de la escala', () {
    const allowed = {'C', 'D', 'E', 'F', 'G', 'A', 'B'};
    final notes = scaleNotesOnNeck(rootSemitone: 0, intervals: major);
    for (final n in notes) {
      expect(allowed, contains(n.note));
      expect(
        pitchClassName(standardOpenStringMidi[n.string - 1] + n.fret),
        n.note,
      );
    }
  });

  test('C mayor: 15 de las 25 posiciones de cada cuerda', () {
    // Cada octava (12 trastes) trae 7 notas; las seis cuerdas al aire están en
    // C mayor, así que la nota del traste 24 también cuenta.
    final notes = scaleNotesOnNeck(rootSemitone: 0, intervals: major);
    for (var s = 1; s <= 6; s++) {
      expect(notes.where((n) => n.string == s), hasLength(15), reason: '$s');
    }
  });

  test('la raíz está marcada en cada C y solo ahí', () {
    final notes = scaleNotesOnNeck(rootSemitone: 0, intervals: major);
    for (final n in notes) {
      expect(n.isRoot, n.note == 'C');
      if (n.isRoot) expect(n.interval, '1');
    }
    // Dos C en las cuerdas que suman traste 24 sin caer en C al aire.
    expect(notes.where((n) => n.isRoot && n.string == 6), hasLength(2));
  });

  test('E menor pentatónica: las seis cuerdas al aire están en la escala', () {
    final open = scaleNotesOnNeck(
      rootSemitone: 4,
      intervals: minorPentatonic,
    ).where((n) => n.fret == 0).toList();
    expect(open.map((n) => n.string), [1, 2, 3, 4, 5, 6]);
    expect(open.map((n) => n.note), ['E', 'B', 'G', 'D', 'A', 'E']);
    expect(open.first.isRoot, isTrue);
    expect(open.map((n) => n.interval), ['1', '5', 'b3', 'b7', '4', '1']);
  });

  test('los intervalos se nombran como en las posiciones: b6 en la menor', () {
    final notes = scaleNotesOnNeck(rootSemitone: 9, intervals: naturalMinor);
    expect(notes.firstWhere((n) => n.note == 'F').interval, 'b6');
    expect(notes.any((n) => n.interval == '#5'), isFalse);
  });

  test('maxFret limita el mástil', () {
    final notes = scaleNotesOnNeck(
      rootSemitone: 0,
      intervals: major,
      maxFret: 12,
    );
    expect(notes.every((n) => n.fret <= 12), isTrue);
  });
}
