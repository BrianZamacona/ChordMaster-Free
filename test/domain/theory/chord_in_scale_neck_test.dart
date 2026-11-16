import 'package:chordmaster_free/domain/theory/neck_notes.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const major = [0, 2, 4, 5, 7, 9, 11];
  int pc(int string, int fret) => (standardOpenStringMidi[string - 1] + fret) % 12;

  test('G7 en C mayor: la escala en todo el mástil y resaltadas G B D F', () {
    final r = chordInScaleOnNeck(rootSemitone: 0, scale: major, chordTones: {7, 11, 2, 5});
    expect(r.neck, scaleNotesOnNeck(rootSemitone: 0, intervals: major));
    expect(r.chord, isNotEmpty);
    for (final c in r.neck) {
      expect(r.chord.contains(c), {7, 11, 2, 5}.contains(pc(c.string, c.fret)), reason: '${c.string}:${c.fret}');
    }
  });

  test('una nota del acorde fuera de la escala también está (la C# de A7 en C)', () {
    final r = chordInScaleOnNeck(rootSemitone: 0, scale: major, chordTones: {9, 1, 4, 7});
    final sharp = [for (final c in r.neck) if (pc(c.string, c.fret) == 1) c];
    expect(sharp, isNotEmpty);
    expect(r.chord.containsAll(sharp), isTrue);
  });

  test('sin escala: solo las notas del acorde, todas resaltadas', () {
    final r = chordInScaleOnNeck(rootSemitone: 2, scale: const [], chordTones: {0, 4, 7});
    expect(r.neck.toSet(), r.chord);
    expect({for (final c in r.neck) pc(c.string, c.fret)}, {2, 6, 9}); // D F# A
  });
}
