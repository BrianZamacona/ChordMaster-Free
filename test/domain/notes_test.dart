import 'package:chordmaster_free/domain/theory/intervals.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('las 12 notas, con sostenidos y sin repetir', () {
    expect(noteNames, hasLength(12));
    expect(noteNames.toSet(), hasLength(12));
    expect(noteNames.any((n) => n.contains('b')), isFalse);
  });

  test('pitchClassName reduce cualquier entero módulo 12', () {
    expect(pitchClassName(0), 'C');
    expect(pitchClassName(69), 'A'); // La 440
    expect(pitchClassName(11 + 2), 'C#');
    expect(pitchClassName(-1), 'B');
    for (var pc = 0; pc < 12; pc++) {
      expect(noteIndex(pitchClassName(pc)), pc);
    }
  });

  test('noteIndex da -1 para lo que no es una nota con sostenido', () {
    expect(noteIndex('Db'), -1);
    expect(noteIndex('H'), -1);
  });

  test('afinación estándar: 1ª cuerda E4 … 6ª cuerda E2', () {
    expect(standardOpenStringMidi.first, 64);
    expect(standardOpenStringMidi.last, 40);
    expect([for (final m in standardOpenStringMidi) pitchClassName(m)],
        ['E', 'B', 'G', 'D', 'A', 'E']);
  });

  test('chordToneLabel: un nombre por tono, tensiones con su número', () {
    expect([0, 3, 6].map(chordToneLabel), ['1', 'b3', 'b5']);
    expect([0, 4, 8].map(chordToneLabel), ['1', '3', '#5']);
    expect([13, 14, 15, 17, 18, 21].map(chordToneLabel),
        ['b9', '9', '#9', '11', '#11', '13']);
  });
}
