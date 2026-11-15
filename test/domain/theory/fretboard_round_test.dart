import 'dart:math';

import 'package:chordmaster_free/domain/theory/fretboard_quiz.dart';
import 'package:chordmaster_free/domain/theory/fretboard_round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rng = Random(5);

  test('empieza con 60 s y el reloj baja de uno en uno hasta 0, sin pasarse', () {
    var r = const FretRound();
    expect(r.left, 60);
    for (var i = 0; i < 60; i++) {
      expect(r.isOver, isFalse);
      r = r.tick();
    }
    expect(r.left, 0);
    expect(r.isOver, isTrue);
    expect(r.tick().left, 0);
  });

  test('un punto por acierto; el error cuenta como respondida y no resta', () {
    var r = const FretRound();
    final q = nextFretQuestion(rng);
    final wrong = q.choices.firstWhere((c) => c != q.answer);
    r = r.answer(q, q.answer).answer(q, wrong).answer(q, q.answer);
    expect(r.score, 2);
    expect(r.answered, 3);
    expect(r.previous!.choice, q.answer);
  });

  test('con el tiempo acabado, responder no cuenta', () {
    final q = nextFretQuestion(rng);
    final over = const FretRound(left: 1).tick();
    expect(over.answer(q, q.answer).answered, 0);
  });

  test('récord: solo si supera al anterior y con algún acierto', () {
    expect(isRoundRecord(5, 4), isTrue);
    expect(isRoundRecord(4, 4), isFalse);
    expect(isRoundRecord(0, 0), isFalse);
    expect(isRoundRecord(1, 0), isTrue);
  });
}
