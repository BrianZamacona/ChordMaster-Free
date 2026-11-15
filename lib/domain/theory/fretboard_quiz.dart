/// Quiz del diapasón (inspirado en el "Note Finder" de Gibson, por reglas):
/// nombrar la nota de un lugar del mástil, encontrar una nota en una cuerda
/// (la pregunta al revés) y encontrar su octava con las formas de
/// [octaveShapes]. Todo sale de la afinación; las preguntas se
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

/// "¿En qué traste de la cuerda [string] está [note]?" (la pregunta al
/// revés): las opciones son trastes del 0 al 11, donde cada nota está una sola
/// vez, y [answer] es el suyo.
class FindNoteQuestion extends FretQuestion {
  const FindNoteQuestion({required this.string, required this.note, required super.choices, required super.answer});

  final int string;

  /// Clase de altura (C = 0).
  final int note;

  /// Dónde está la respuesta.
  FretSpot get spot => (string: string, fret: answer);
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

/// La pregunta siguiente: un tercio de cada tipo.
FretQuestion nextFretQuestion(Random rng) => switch (rng.nextInt(3)) {
  0 => nameNoteQuestion(rng),
  1 => findNoteQuestion(rng),
  _ => octaveQuestion(rng),
};

/// Trastes en los que se busca una nota: del 0 al 11 cada nota sale una vez
/// (en el 12 se repite la del aire).
const findNoteMaxFret = 11;

/// Traste de [note] (clase de altura) en [string], entre 0 y 11: los
/// semitonos que hay desde la cuerda al aire.
int fretOfNote(int string, int note) => (note - standardOpenStringMidi[string - 1]) % 12;

/// Una nota y una cuerda: hay que dar el traste. Las opciones equivocadas son
/// los trastes vecinos (a uno o dos): los que se confunden al contar.
FindNoteQuestion findNoteQuestion(Random rng) {
  final string = rng.nextInt(6) + 1;
  final note = rng.nextInt(12);
  final answer = fretOfNote(string, note);
  final wrong = [
    for (final d in [-1, 1, -2, 2, 3, -3])
      if (answer + d >= 0 && answer + d <= findNoteMaxFret) answer + d,
  ];
  final near = wrong.take(4).toList()..shuffle(rng);
  final choices = [answer, ...near.take(fretQuizChoices - 1)]..shuffle(rng);
  return FindNoteQuestion(string: string, note: note, choices: choices, answer: answer);
}

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
