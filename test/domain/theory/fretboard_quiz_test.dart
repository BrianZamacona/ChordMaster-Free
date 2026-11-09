import 'dart:math';

import 'package:chordmaster_free/domain/theory/fretboard_quiz.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/theory/octaves.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int midi(FretSpot s) => standardOpenStringMidi[s.string - 1] + s.fret;

  test('la nota de un lugar sale de la afinación', () {
    expect(pitchClassName(pitchClassAt((string: 6, fret: 0))), 'E');
    expect(pitchClassName(pitchClassAt((string: 5, fret: 3))), 'C');
    expect(pitchClassName(pitchClassAt((string: 2, fret: 1))), 'C');
    expect(pitchClassName(pitchClassAt((string: 1, fret: 12))), 'E');
  });

  group('en 2000 preguntas', () {
    final rng = Random(7);
    final questions = [for (var i = 0; i < 2000; i++) nextFretQuestion(rng)];

    test('salen los dos tipos y cuatro opciones distintas con la respuesta', () {
      expect(questions.whereType<NameNoteQuestion>(), isNotEmpty);
      expect(questions.whereType<OctaveQuestion>(), isNotEmpty);
      for (final q in questions) {
        expect(q.choices, hasLength(fretQuizChoices));
        expect(q.choices.toSet(), hasLength(fretQuizChoices));
        expect(q.choices, contains(q.answer));
        expect(q.isRight(q.answer), isTrue);
      }
    });

    test('"¿qué nota es?": la respuesta es la nota y las otras están a 1 o 2 semitonos', () {
      for (final q in questions.whereType<NameNoteQuestion>()) {
        expect(q.spot.fret, inInclusiveRange(0, fretQuizMaxFret));
        expect(q.answer, pitchClassAt(q.spot));
        for (final c in q.choices.where((c) => c != q.answer)) {
          final d = (c - q.answer) % 12;
          expect([1, 2, 10, 11], contains(d));
        }
      }
    });

    test('octava: la respuesta suena una (o dos) octavas arriba, según la forma', () {
      for (final q in questions.whereType<OctaveQuestion>()) {
        expect(octaveShapes(), contains(q.shape));
        expect(q.from.string, q.shape.lowString);
        expect(q.to.string, q.shape.highString);
        expect(midi(q.to) - midi(q.from), 12 * q.shape.octaves);
        expect(q.to.fret - q.from.fret, q.shape.fretShift);
        expect(q.answer, q.to.fret);
        for (final f in [q.from.fret, q.to.fret]) {
          expect(f, inInclusiveRange(0, fretQuizMaxFret));
        }
        // Entre las opciones está el error típico: el mismo traste de partida.
        if (q.from.fret != q.to.fret) expect(q.choices, contains(q.from.fret));
      }
    });

    test('todas las formas de octava aparecen', () {
      final used = {for (final q in questions.whereType<OctaveQuestion>()) q.shape};
      expect(used, octaveShapes().toSet());
    });
  });
}
