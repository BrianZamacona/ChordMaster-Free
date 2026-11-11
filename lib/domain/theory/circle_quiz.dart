/// Quiz del círculo de quintas (fase 3): "¿cuál es el V de E?", "¿cuántas
/// alteraciones tiene A?" y "¿qué acorde falta en la ventana?". Todo sale de
/// [circleOrder], [keySignatureAt] y [diatonicWindow]; el generador se pasa
/// para poder probarlo.
library;

import 'dart:math';

import 'circle_harmony.dart';
import 'circle_of_fifths.dart';

/// Opciones por pregunta.
const circleQuizChoices = 4;

/// Una pregunta: [choices] tiene la respuesta en [answer].
sealed class CircleQuestion {
  const CircleQuestion({required this.index, required this.choices, required this.answer});

  /// Posición del círculo de la tonalidad que se pregunta.
  final int index;
  final List<int> choices;
  final int answer;

  bool isRight(int choice) => choice == answer;
}

/// "¿Cuál es el V de …?": opciones = clases de altura. Las equivocadas son
/// las que se confunden: el IV (el vecino de la izquierda), dos pasos a la
/// derecha y la relativa menor.
class DominantQuestion extends CircleQuestion {
  const DominantQuestion({required super.index, required super.choices, required super.answer});
}

/// "¿Cuántas alteraciones tiene …?": opciones = posiciones del círculo (su
/// armadura). Las equivocadas son las vecinas y la del otro lado con la
/// misma cantidad (3 ♯ y 3 ♭).
class SignatureQuestion extends CircleQuestion {
  const SignatureQuestion({required super.index, required super.choices, required super.answer});
}

/// "¿Qué acorde falta en la ventana de …?": [shown] son los otros seis
/// acordes diatónicos; opciones = índices en [chordChoices].
class MissingChordQuestion extends CircleQuestion {
  const MissingChordQuestion({
    required super.index,
    required super.choices,
    required super.answer,
    required this.shown,
    required this.chordChoices,
  });

  final List<CircleChord> shown;
  final List<CircleChord> chordChoices;
}

/// La pregunta siguiente: un tercio de cada tipo.
CircleQuestion nextCircleQuestion(Random rng) => switch (rng.nextInt(3)) {
  0 => dominantQuestion(rng),
  1 => signatureQuestion(rng),
  _ => missingChordQuestion(rng),
};

DominantQuestion dominantQuestion(Random rng) {
  final i = rng.nextInt(circleLength);
  int at(int step) => circleOrder[(i + step) % circleLength];
  final answer = at(1);
  final wrong = [at(-1), at(2), relativeMinorOf(at(0))];
  return DominantQuestion(index: i, choices: [answer, ...wrong]..shuffle(rng), answer: answer);
}

SignatureQuestion signatureQuestion(Random rng) {
  final i = rng.nextInt(circleLength);
  // La misma cantidad del otro lado; en C (0) y F# (6) es ella misma: se
  // usan las de dos pasos.
  final mirror = (circleLength - i) % circleLength;
  final wrong = <int>{
    (i + 1) % circleLength,
    (i - 1) % circleLength,
    if (mirror != i) mirror else (i + 2) % circleLength,
  };
  return SignatureQuestion(index: i, choices: [i, ...wrong]..shuffle(rng), answer: i);
}

MissingChordQuestion missingChordQuestion(Random rng) {
  final i = rng.nextInt(circleLength);
  final tonic = circleOrder[i];
  final window = [
    for (final c in diatonicByDegree(tonic)) (numeral: c.numeral, root: c.root, type: c.type),
  ];
  final missing = window[rng.nextInt(window.length)];
  // Equivocadas: la misma raíz con otra calidad (la trampa típica) y los
  // mayores de dos pasos a cada lado, que ya no son de la tonalidad.
  final otherQuality = missing.type == 'major' ? 'minor' : 'major';
  final candidates = <CircleChord>[
    (numeral: '', root: missing.root, type: otherQuality),
    (numeral: '', root: circleOrder[(i + 2) % circleLength], type: 'major'),
    (numeral: '', root: circleOrder[(i - 2) % circleLength], type: 'major'),
    (numeral: '', root: relativeMinorOf(circleOrder[(i + 2) % circleLength]), type: 'minor'),
  ];
  final inKey = {for (final c in window) (c.root, c.type)};
  final wrong = [
    for (final c in candidates)
      if (!inKey.contains((c.root, c.type))) c,
  ].take(circleQuizChoices - 1);
  final chordChoices = [missing, ...wrong]..shuffle(rng);
  final answer = chordChoices.indexOf(missing);
  return MissingChordQuestion(
    index: i,
    choices: [for (var k = 0; k < chordChoices.length; k++) k],
    answer: answer,
    shown: [for (final c in window) if (c != missing) c],
    chordChoices: chordChoices,
  );
}
