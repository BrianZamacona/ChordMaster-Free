import 'package:chordmaster_free/data/models/note_coordinate.dart';
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

  group('una posición en todas sus octavas', () {
    const open = NoteCoordinate(string: 1, fret: 0, isRoot: false, note: 'E');
    const high = NoteCoordinate(string: 1, fret: 5, isRoot: true, note: 'A');

    test('desde el aire se repite completa en el traste 12', () {
      final all = patternAcrossNeck(const [open, high]);
      expect(all.map((c) => c.fret).toList()..sort(), [0, 5, 12, 17]);
      expect(all.where((c) => c.fret == 17).single.isRoot, isTrue);
      expect(all.where((c) => c.fret == 12).single.note, 'E');
    });

    test('también baja: desde el traste 12 se repite desde el aire', () {
      final frets = patternAcrossNeck(const [
        NoteCoordinate(string: 1, fret: 12, isRoot: false),
        NoteCoordinate(string: 1, fret: 17, isRoot: false),
      ]).map((c) => c.fret).toList()..sort();
      expect(frets, [0, 5, 12, 17]);
    });

    test('una posición que no cabe completa no se recorta', () {
      // De 10 a 14: arriba llegaría al 26 y abajo al -2.
      final frets = patternAcrossNeck(const [
        NoteCoordinate(string: 1, fret: 10, isRoot: false),
        NoteCoordinate(string: 1, fret: 14, isRoot: false),
      ]).map((c) => c.fret).toList()..sort();
      expect(frets, [10, 14]);
    });

    test('cabe tres veces si es corta y empieza en el aire', () {
      final frets = patternAcrossNeck(const [
        NoteCoordinate(string: 2, fret: 0, isRoot: false),
      ]).map((c) => c.fret).toList()..sort();
      expect(frets, [0, 12, 24]);
    });

    test('la copia suena en la misma nota: sigue en la escala', () {
      final scale = scaleNotesOnNeck(rootSemitone: 0, intervals: major).toSet();
      final position = scale.where((n) => n.fret <= 5).toList();
      final copies = patternAcrossNeck(position);
      expect(copies.any((c) => c.fret >= 12), isTrue);
      expect(scale.containsAll(copies), isTrue);
    });

    test('sin notas no hay copias', () {
      expect(patternAcrossNeck(const []), isEmpty);
    });
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
