import 'dart:math';

import 'package:chordmaster_free/domain/theory/circle_harmony.dart';
import 'package:chordmaster_free/domain/theory/circle_of_fifths.dart';
import 'package:chordmaster_free/domain/theory/circle_quiz.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rng = Random(11);
  final questions = [for (var i = 0; i < 3000; i++) nextCircleQuestion(rng)];

  test('salen los tres tipos, con cuatro opciones distintas y la respuesta', () {
    expect(questions.whereType<DominantQuestion>(), isNotEmpty);
    expect(questions.whereType<SignatureQuestion>(), isNotEmpty);
    expect(questions.whereType<MissingChordQuestion>(), isNotEmpty);
    for (final q in questions) {
      expect(q.choices, hasLength(circleQuizChoices));
      expect(q.choices.toSet(), hasLength(circleQuizChoices));
      expect(q.choices, contains(q.answer));
    }
  });

  test('el V es una quinta arriba: el vecino de la derecha (el V de E es B)', () {
    for (final q in questions.whereType<DominantQuestion>()) {
      final tonic = circleOrder[q.index];
      expect((q.answer - tonic) % 12, 7);
      expect(q.answer, dominantOf(tonic));
    }
    final e = circleIndexOf(noteIndex('E'));
    expect(pitchClassName(circleOrder[(e + 1) % 12]), 'B');
  });

  test('la armadura: la respuesta es la de su posición, y no se repite entre las opciones', () {
    for (final q in questions.whereType<SignatureQuestion>()) {
      expect(q.answer, q.index);
      final shorts = {for (final c in q.choices) keySignatureAt(c).short};
      expect(shorts, hasLength(circleQuizChoices));
    }
    // A tiene 3 ♯.
    expect(keySignatureAt(circleIndexOf(noteIndex('A'))).short, '3 ♯');
  });

  test('el acorde que falta es de la ventana y las otras opciones no', () {
    for (final q in questions.whereType<MissingChordQuestion>()) {
      final window = {for (final c in diatonicByDegree(circleOrder[q.index])) (c.root, c.type)};
      expect(q.shown, hasLength(6));
      for (final c in q.shown) {
        expect(window, contains((c.root, c.type)));
      }
      final missing = q.chordChoices[q.answer];
      expect(window, contains((missing.root, missing.type)));
      expect(q.shown.any((c) => c.root == missing.root && c.type == missing.type), isFalse);
      for (final (k, c) in q.chordChoices.indexed) {
        if (k != q.answer) expect(window.contains((c.root, c.type)), isFalse);
      }
    }
  });
}
