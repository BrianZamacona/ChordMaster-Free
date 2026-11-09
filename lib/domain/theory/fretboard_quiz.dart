/// Quiz del diapasón (inspirado en el "Note Finder" de Gibson, por reglas):
/// nombrar la nota de un lugar del mástil y encontrar su octava con las
/// formas de [octaveShapes]. Todo sale de la afinación; las preguntas se
/// arman con un generador que se pasa (así se pueden probar).
library;

import 'dart:math';

import 'notes.dart';
import 'octaves.dart';

/// Un lugar del mástil (cuerda 1 = mi aguda).
typedef FretSpot = ({int string, int fret});

/// Trastes en los que se pregunta (del 0, al aire, al 12).
const fretQuizMaxFret = 12;

/// Opciones por pregunta.
const fretQuizChoices = 4;

/// Clase de altura (C = 0) de un lugar del mástil.
int pitchClassAt(FretSpot spot) => (standardOpenStringMidi[spot.string - 1] + spot.fret) % 12;

/// Una pregunta del quiz: [choices] tiene la respuesta en [answer].
sealed class FretQuestion {
  const FretQuestion({required this.choices, required this.answer});

  final List<int> choices;
  final int answer;

  bool isRight(int choice) => choice == answer;
}

/// "¿Qué nota es?": [spot] marcado en el mástil; las opciones son clases
/// de altura (C = 0).
class NameNoteQuestion extends FretQuestion {
  const NameNoteQuestion({required this.spot, required super.choices, required super.answer});

  final FretSpot spot;
}

/// "¿En qué traste de la cuerda [OctaveShape.highString] está su octava?":
/// [from] marcado; las opciones son trastes y [to] es la respuesta.
class OctaveQuestion extends FretQuestion {
  const OctaveQuestion({
    required this.shape,
    required this.from,
    required this.to,
    required super.choices,
    required super.answer,
  });

  final OctaveShape shape;
  final FretSpot from;
  final FretSpot to;
}

/// La pregunta siguiente: mitad de cada tipo.
FretQuestion nextFretQuestion(Random rng) =>
    rng.nextBool() ? nameNoteQuestion(rng) : octaveQuestion(rng);

/// Una nota en cualquier cuerda, del traste 0 al 12. Las opciones
/// equivocadas son vecinas (a uno o dos semitonos): las que se confunden.
NameNoteQuestion nameNoteQuestion(Random rng) {
  final spot = (string: rng.nextInt(6) + 1, fret: rng.nextInt(fretQuizMaxFret + 1));
  final answer = pitchClassAt(spot);
  final near = [for (final d in [-2, -1, 1, 2]) (answer + d) % 12]..shuffle(rng);
  final choices = [answer, ...near.take(fretQuizChoices - 1)]..shuffle(rng);
  return NameNoteQuestion(spot: spot, choices: choices, answer: answer);
}

/// Una forma de octava y una nota que quepa entera entre los trastes 0 y
/// 12. Las opciones equivocadas son el traste de al lado y el de partida
/// (el error más común: buscarla en el mismo traste).
OctaveQuestion octaveQuestion(Random rng) {
  final shapes = octaveShapes();
  while (true) {
    final shape = shapes[rng.nextInt(shapes.length)];
    // octavePairs ya se queda en los trastes 0 a 12 (= fretQuizMaxFret).
    final pairs = octavePairs(rng.nextInt(12), shape);
    if (pairs.isEmpty) continue;
    final (from, to) = pairs[rng.nextInt(pairs.length)];
    // En orden de preferencia, sin repetir ni la respuesta (en la forma de
    // dos octavas 6 → 1 el traste de partida ES la respuesta).
    final wrong = {
      for (final f in [from.fret, to.fret - 1, to.fret + 1, to.fret + 2, to.fret - 2, to.fret + 3])
        if (f != to.fret && f >= 0 && f <= fretQuizMaxFret + 2) f,
    };
    final choices = [to.fret, ...wrong.take(fretQuizChoices - 1)]..shuffle(rng);
    return OctaveQuestion(shape: shape, from: from, to: to, choices: choices, answer: to.fret);
  }
}
