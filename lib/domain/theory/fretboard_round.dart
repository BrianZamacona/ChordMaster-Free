/// Ronda con reloj de Notas del mástil (inspirada en el desafío de 60 s de
/// FretMaster, por reglas): las mismas preguntas, una tras otra sin pausa,
/// hasta que se acaba el tiempo. Un punto por acierto; el error no resta.
library;

import 'dart:math';

import 'fretboard_quiz.dart';

/// Duración de la ronda.
const fretRoundSeconds = 60;

/// Una ronda en curso o terminada. Inmutable: el reloj la avanza con [tick]
/// y cada respuesta con [answer].
class FretRound {
  const FretRound({this.left = fretRoundSeconds, this.right = 0, this.answered = 0, this.previous});

  /// Segundos que quedan.
  final int left;
  final int right;
  final int answered;

  /// La última pregunta respondida y lo que se eligió (para decir si estuvo
  /// bien mientras ya se ve la siguiente).
  final ({FretQuestion question, int choice})? previous;

  bool get isOver => left <= 0;

  /// Los puntos: uno por acierto.
  int get score => right;

  /// Un segundo menos (nunca baja de 0).
  FretRound tick() => FretRound(left: max(0, left - 1), right: right, answered: answered, previous: previous);

  /// Responder [question] con [choice]; con el tiempo acabado no cuenta.
  FretRound answer(FretQuestion question, int choice) => isOver
      ? this
      : FretRound(
          left: left,
          right: right + (question.isRight(choice) ? 1 : 0),
          answered: answered + 1,
          previous: (question: question, choice: choice),
        );
}

/// Si [score] supera el récord [best] (una ronda sin aciertos nunca lo es).
bool isRoundRecord(int score, int best) => score > 0 && score > best;
