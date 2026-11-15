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

/// Qué se practica (inspirado en la configuración de FretMaster): las
/// cuerdas, el tramo de trastes y si solo salen notas naturales. Toda
/// pregunta queda dentro: el lugar marcado, la nota a buscar, la octava y sus
/// dos cuerdas.
class FretQuizFilter {
  const FretQuizFilter({
    this.strings = allStrings,
    this.fromFret = 0,
    this.toFret = fretQuizMaxFret,
    this.naturalsOnly = false,
  });

  /// Lo guardado; si no se entiende o no es válido, todo el mástil.
  factory FretQuizFilter.fromJson(Object? json) {
    if (json is! Map) return const FretQuizFilter();
    try {
      final f = FretQuizFilter(
        strings: {for (final s in json['strings'] as List) s as int},
        fromFret: json['from'] as int,
        toFret: json['to'] as int,
        naturalsOnly: json['naturals'] as bool,
      );
      return f.isValid ? f : const FretQuizFilter();
    } catch (_) {
      return const FretQuizFilter();
    }
  }

  static const allStrings = {1, 2, 3, 4, 5, 6};

  /// Cuerdas (1 = mi aguda); nunca vacío.
  final Set<int> strings;
  final int fromFret;
  final int toFret;
  final bool naturalsOnly;

  /// El mástil entero (del 0 al 12) y todas las notas.
  bool get isAll => strings.length == 6 && fromFret == 0 && toFret == fretQuizMaxFret && !naturalsOnly;

  /// [strings] no vacío y un tramo de al menos [fretQuizMinSpan] + 1 trastes
  /// dentro del 0 al 12: así siempre hay notas naturales y cuatro opciones.
  bool get isValid =>
      strings.isNotEmpty &&
      strings.every((s) => s >= 1 && s <= 6) &&
      fromFret >= 0 &&
      toFret <= fretQuizMaxFret &&
      toFret - fromFret >= fretQuizMinSpan;

  bool _fretIn(int fret) => fret >= fromFret && fret <= toFret;

  bool _noteIn(int pitchClass) => !naturalsOnly || isNaturalNote(pitchClass);

  FretQuizFilter copyWith({Set<int>? strings, int? fromFret, int? toFret, bool? naturalsOnly}) => FretQuizFilter(
    strings: strings ?? this.strings,
    fromFret: fromFret ?? this.fromFret,
    toFret: toFret ?? this.toFret,
    naturalsOnly: naturalsOnly ?? this.naturalsOnly,
  );

  Map<String, Object> toJson() => {
    'strings': (strings.toList()..sort()),
    'from': fromFret,
    'to': toFret,
    'naturals': naturalsOnly,
  };

  @override
  bool operator ==(Object other) =>
      other is FretQuizFilter &&
      other.strings.length == strings.length &&
      other.strings.containsAll(strings) &&
      other.fromFret == fromFret &&
      other.toFret == toFret &&
      other.naturalsOnly == naturalsOnly;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(strings), fromFret, toFret, naturalsOnly);
}

/// Distancia mínima entre el primer y el último traste del filtro: cuatro
/// trastes seguidos siempre tienen notas naturales y tres vecinos.
const fretQuizMinSpan = 3;

/// Las notas sin sostenido (C D E F G A B).
bool isNaturalNote(int pitchClass) => !pitchClassName(pitchClass).contains('#');

/// La pregunta siguiente, dentro de [filter]: un tercio de cada tipo (si en
/// las cuerdas elegidas no cabe ninguna octava, se turnan las otras dos).
FretQuestion nextFretQuestion(Random rng, [FretQuizFilter filter = const FretQuizFilter()]) {
  final octaves = _octaveCandidates(filter);
  return switch (rng.nextInt(octaves.isEmpty ? 2 : 3)) {
    0 => nameNoteQuestion(rng, filter),
    1 => findNoteQuestion(rng, filter),
    _ => _octaveQuestionFrom(rng, octaves, filter),
  };
}

/// Trastes en los que se busca una nota: doce seguidos, donde cada nota sale
/// una vez (en el traste 12 se repite la del aire).
const findNoteMaxFret = 11;

/// Traste de [note] (clase de altura) en [string], entre 0 y 11: los
/// semitonos que hay desde la cuerda al aire.
int fretOfNote(int string, int note) => (note - standardOpenStringMidi[string - 1]) % 12;

/// Los lugares de [filter], de notas naturales si lo pide, con trastes hasta
/// [maxFret].
List<FretSpot> _spots(FretQuizFilter filter, {required int maxFret}) => [
  for (final string in filter.strings)
    for (var fret = filter.fromFret; fret <= maxFret; fret++)
      if (filter._noteIn(pitchClassAt((string: string, fret: fret)))) (string: string, fret: fret),
];

/// Una nota y una cuerda: hay que dar el traste. Las opciones equivocadas son
/// los trastes vecinos (a uno, dos o tres): los que se confunden al contar.
/// Se busca en doce trastes desde el primero del filtro, donde cada nota sale
/// una sola vez.
FindNoteQuestion findNoteQuestion(Random rng, [FretQuizFilter filter = const FretQuizFilter()]) {
  final last = min(filter.toFret, filter.fromFret + findNoteMaxFret);
  final spots = _spots(filter, maxFret: last);
  final spot = spots[rng.nextInt(spots.length)];
  final answer = spot.fret;
  final wrong = [
    for (final d in [-1, 1, -2, 2, 3, -3])
      if (answer + d >= filter.fromFret && answer + d <= last) answer + d,
  ];
  final near = wrong.take(4).toList()..shuffle(rng);
  final choices = [answer, ...near.take(fretQuizChoices - 1)]..shuffle(rng);
  return FindNoteQuestion(string: spot.string, note: pitchClassAt(spot), choices: choices, answer: answer);
}

/// Una nota dentro de [filter]. Las opciones equivocadas son vecinas (a uno
/// o dos semitonos, o las naturales de al lado si solo hay naturales): las
/// que se confunden.
NameNoteQuestion nameNoteQuestion(Random rng, [FretQuizFilter filter = const FretQuizFilter()]) {
  final spots = _spots(filter, maxFret: filter.toFret);
  final spot = spots[rng.nextInt(spots.length)];
  final answer = pitchClassAt(spot);
  final List<int> near;
  if (filter.naturalsOnly) {
    final naturals = [for (var pc = 0; pc < 12; pc++) if (isNaturalNote(pc)) pc];
    final i = naturals.indexOf(answer);
    near = [for (final d in [-2, -1, 1, 2]) naturals[(i + d) % naturals.length]];
  } else {
    near = [for (final d in [-2, -1, 1, 2]) (answer + d) % 12];
  }
  near.shuffle(rng);
  final choices = [answer, ...near.take(fretQuizChoices - 1)]..shuffle(rng);
  return NameNoteQuestion(spot: spot, choices: choices, answer: answer);
}

typedef _OctavePair = (OctaveShape, FretSpot, FretSpot);

/// Las octavas de [filter]: sus dos cuerdas elegidas y sus dos trastes en el
/// tramo.
List<_OctavePair> _octaveCandidates(FretQuizFilter filter) => [
  for (final shape in octaveShapes())
    if (filter.strings.contains(shape.lowString) && filter.strings.contains(shape.highString))
      for (var pc = 0; pc < 12; pc++)
        if (filter._noteIn(pc))
          for (final (from, to) in octavePairs(pc, shape))
            if (filter._fretIn(from.fret) && filter._fretIn(to.fret)) (shape, from, to),
];

/// Una forma de octava y una nota que quepa entera en [filter] (si no cabe
/// ninguna, falla: [nextFretQuestion] ya lo evita).
OctaveQuestion octaveQuestion(Random rng, [FretQuizFilter filter = const FretQuizFilter()]) =>
    _octaveQuestionFrom(rng, _octaveCandidates(filter), filter);

/// Las opciones equivocadas son el traste de partida (el error más común:
/// buscarla en el mismo traste) y los de al lado, dentro del tramo.
OctaveQuestion _octaveQuestionFrom(Random rng, List<_OctavePair> candidates, FretQuizFilter filter) {
  // Una forma al azar y luego una de sus notas: así las formas salen
  // parejas aunque unas tengan más lugares que otras.
  final shapes = {for (final (shape, _, _) in candidates) shape}.toList();
  final shape = shapes[rng.nextInt(shapes.length)];
  final pairs = [for (final c in candidates) if (c.$1 == shape) c];
  final (_, from, to) = pairs[rng.nextInt(pairs.length)];
  // En orden de preferencia, sin repetir ni la respuesta (en la forma de
  // dos octavas 6 → 1 el traste de partida ES la respuesta).
  final wrong = {
    for (final f in [from.fret, to.fret - 1, to.fret + 1, to.fret + 2, to.fret - 2, to.fret + 3, to.fret - 3])
      if (f != to.fret && filter._fretIn(f)) f,
  };
  final choices = [to.fret, ...wrong.take(fretQuizChoices - 1)]..shuffle(rng);
  return OctaveQuestion(shape: shape, from: from, to: to, choices: choices, answer: to.fret);
}

/// Si en [filter] cabe alguna octava (sus dos cuerdas elegidas y sus trastes
/// en el tramo); si no, la pregunta de la octava no sale.
bool fretQuizHasOctaves(FretQuizFilter filter) => _octaveCandidates(filter).isNotEmpty;
