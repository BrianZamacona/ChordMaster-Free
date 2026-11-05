import 'dart:math' as math;

import '../../core/i18n/tr.dart';
import '../progressions/progression_data.dart';
import 'notes.dart';
import 'scale_insights.dart';

/// Círculo de quintas, todo calculado por regla.
///
/// Las tonalidades se nombran con sostenidos, como el resto de la app (A#,
/// D#…): la armadura se da como cantidad ("2 ♯", "3 ♭") y ninguna nota se
/// nombra con bemol. Una posición es el índice en [circleOrder] (0 = C, y
/// sube en el sentido de las agujas del reloj).

/// Posiciones del círculo.
const circleLength = 12;

/// Semitonos de una quinta justa: un paso a la derecha en el círculo.
const perfectFifth = 7;

/// Semitonos de una cuarta justa: un paso a la izquierda en el círculo.
const perfectFourth = 5;

/// Semitonos de la tónica a su relativa menor.
const relativeMinorOffset = 9;

/// Las 12 tónicas (clase de altura) sumando quintas desde C.
final List<int> circleOrder = List.unmodifiable([
  for (var i = 0; i < circleLength; i++) i * perfectFifth % circleLength,
]);

/// Posición de la tónica [pitchClass].
int circleIndexOf(int pitchClass) => circleOrder.indexOf(pitchClass % 12);

/// Relativa menor de la tónica [pitchClass].
int relativeMinorOf(int pitchClass) => (pitchClass + relativeMinorOffset) % 12;

// ── Armadura ────────────────────────────────────────────────────────────────

enum Accidental { sharp, flat }

/// Armadura de una tonalidad mayor.
class KeySignature {
  const KeySignature({required this.count, this.accidental});

  final int count;

  /// `null` cuando no hay alteraciones.
  final Accidental? accidental;

  /// 6 ♯ se escribe también como 6 ♭: es la posición opuesta a C.
  bool get isEnharmonic => count == 6;

  /// Forma corta para el círculo: `0`, `2 ♯`, `3 ♭`.
  String get short => switch (accidental) {
    null => '0',
    Accidental.sharp => '$count ♯',
    Accidental.flat => '$count ♭',
  };

  /// Forma larga: "1 sostenido", "3 bemoles", "sin alteraciones".
  LocalizedText get name {
    final kind = accidental;
    if (kind == null) {
      return const LocalizedText(es: 'sin alteraciones', en: 'no accidentals');
    }
    final one = count == 1;
    final text = kind == Accidental.sharp
        ? LocalizedText(
            es: '$count ${one ? 'sostenido' : 'sostenidos'}',
            en: '$count ${one ? 'sharp' : 'sharps'}',
          )
        : LocalizedText(
            es: '$count ${one ? 'bemol' : 'bemoles'}',
            en: '$count ${one ? 'flat' : 'flats'}',
          );
    if (!isEnharmonic) return text;
    return LocalizedText(
      es: '${text.es} (enarmónica de $count bemoles)',
      en: '${text.en} (enharmonic with $count flats)',
    );
  }
}

/// Armadura de la posición [index]: lado derecho ♯, lado izquierdo ♭.
KeySignature keySignatureAt(int index) {
  final i = index % circleLength;
  if (i == 0) return const KeySignature(count: 0);
  return i <= circleLength ~/ 2
      ? KeySignature(count: i, accidental: Accidental.sharp)
      : KeySignature(count: circleLength - i, accidental: Accidental.flat);
}

/// La alteración que agrega una tonalidad respecto de su vecina hacia C.
class AddedAccidental {
  const AddedAccidental({
    required this.accidental,
    required this.pitchClass,
    required this.degree,
  });

  final Accidental accidental;

  /// Clase de altura de la nota alterada (se nombra con sostenidos).
  final int pitchClass;

  /// Grado que ocupa en la nueva tonalidad: 7 para ♯, 4 para ♭.
  final int degree;
}

/// Cada paso a la derecha agrega un ♯, que es la 7ª de la nueva tonalidad;
/// cada paso a la izquierda agrega un ♭, que es la 4ª. `null` en C.
AddedAccidental? addedAccidentalAt(int index) {
  final i = index % circleLength;
  if (i == 0) return null;
  final tonic = circleOrder[i];
  return i <= circleLength ~/ 2
      ? AddedAccidental(
          accidental: Accidental.sharp,
          pitchClass: (tonic + majorScale[6]) % 12,
          degree: 7,
        )
      : AddedAccidental(
          accidental: Accidental.flat,
          pitchClass: (tonic + majorScale[3]) % 12,
          degree: 4,
        );
}

// ── Ventana diatónica ───────────────────────────────────────────────────────

/// En qué parte de la ventana está un acorde.
enum WindowPlace { outerRing, innerRing, outside }

/// Acorde diatónico visto desde el círculo.
class WindowChord {
  const WindowChord({
    required this.numeral,
    required this.root,
    required this.type,
    required this.place,
    required this.offset,
  });

  final String numeral;

  /// Clase de altura de la raíz.
  final int root;

  /// Clave de chords.json: `major`, `minor` o `diminished`.
  final String type;
  final WindowPlace place;

  /// Pasos desde la posición de la tónica (-1, 0, 1); 0 fuera de la ventana.
  final int offset;
}

/// Los vecinos de [tonic]: IV I V afuera, ii vi iii adentro (las relativas de
/// esos tres) y, fuera de la ventana, vii°. Los números salen de
/// [diatonicTriads], así hay una sola fuente de grados.
List<WindowChord> diatonicWindow(int tonic) {
  final center = circleIndexOf(tonic);
  final triads = diatonicTriads(majorScale);
  String numeralOf(int root) {
    final semitones = (root - tonic) % 12;
    return triads.firstWhere((t) => t.semitones == semitones).numeral;
  }

  int rootAt(int offset) => circleOrder[(center + offset) % circleLength];
  const neighbors = [-1, 0, 1];
  final seventh = (tonic + majorScale[6]) % 12;
  return [
    for (final offset in neighbors)
      WindowChord(
        numeral: numeralOf(rootAt(offset)),
        root: rootAt(offset),
        type: 'major',
        place: WindowPlace.outerRing,
        offset: offset,
      ),
    for (final offset in neighbors)
      WindowChord(
        numeral: numeralOf(relativeMinorOf(rootAt(offset))),
        root: relativeMinorOf(rootAt(offset)),
        type: 'minor',
        place: WindowPlace.innerRing,
        offset: offset,
      ),
    WindowChord(
      numeral: numeralOf(seventh),
      root: seventh,
      type: 'diminished',
      place: WindowPlace.outside,
      offset: 0,
    ),
  ];
}

/// Los mismos acordes en orden de grado (I, ii, iii, IV, V, vi, vii°).
List<WindowChord> diatonicByDegree(int tonic) => diatonicWindow(tonic)
  ..sort((a, b) => ((a.root - tonic) % 12).compareTo((b.root - tonic) % 12));

/// I – IV – V – I, la cadencia que se escucha desde el panel.
final Progression cadenceProgression = Progression(
  'circle-cadence',
  'I - IV - V - I',
  ['I', 'IV', 'V', 'I'],
);

// ── Distancia ───────────────────────────────────────────────────────────────

/// Pasos en el círculo entre dos tonalidades (de 0 a 6).
int circleDistance(int a, int b) {
  final d = (circleIndexOf(a) - circleIndexOf(b)).abs();
  return math.min(d, circleLength - d);
}

/// Notas que comparten dos escalas mayores.
///
/// Vale 7 − distancia para distancias de 0 a 5. A distancia 6 no sigue la
/// regla: comparten 2, igual que a distancia 5 (C y F# tienen B y F).
int commonNoteCount(int a, int b) {
  Set<int> notes(int tonic) => {for (final i in majorScale) (tonic + i) % 12};
  return notes(a).intersection(notes(b)).length;
}

// ── Mástil ──────────────────────────────────────────────────────────────────

/// Trastes que se mueve un intervalo de [semitones] al pasar de la cuerda
/// [string] a la siguiente más aguda (índice 0 = 1ª cuerda; [string] de 1 a 5).
int fretShiftToNextString(int string, int semitones) =>
    semitones -
    (standardOpenStringMidi[string - 1] - standardOpenStringMidi[string]);

/// Una cuarta: mismo traste en la cuerda siguiente (de G a B, un traste más).
int fourthFretShift(int string) => fretShiftToNextString(string, perfectFourth);

/// Una quinta: 2 trastes arriba en la cuerda siguiente (de G a B, 3).
int fifthFretShift(int string) => fretShiftToNextString(string, perfectFifth);

/// Una tónica en la cuerda [string] y su quinta en la cuerda siguiente.
({int string, int fret, int nextString, int nextFret}) fifthOnNeck(
  int tonic, {
  int string = 5,
}) {
  final fret = (tonic - standardOpenStringMidi[string]) % 12;
  return (
    string: string,
    fret: fret,
    nextString: string - 1,
    nextFret: fret + fifthFretShift(string),
  );
}

/// La regla de la quinta en el mástil, en una frase.
const fifthShapeRule = LocalizedText(
  es:
      'En el mástil, una quinta está 2 trastes arriba en la cuerda siguiente '
      '(3 si pasas de G a B). Una cuarta, en el mismo traste (1 más de G a B).',
  en:
      'On the neck, a fifth is 2 frets up on the next string (3 going from G '
      'to B). A fourth is on the same fret (1 more from G to B).',
);

// ── Rueda ───────────────────────────────────────────────────────────────────

/// Grados que ocupa cada tonalidad en la rueda.
const wheelStepDegrees = 30.0;

/// Rotación (grados, positiva = horario) que deja [index] en la ventana.
double rotationForIndex(int index) => -index * wheelStepDegrees;

/// Tonalidad que queda en la ventana, arriba, con la rotación [rotation].
int indexAtWindow(double rotation) =>
    (-(rotation / wheelStepDegrees).round()) % circleLength;

/// Acomoda [rotation] a la posición más cercana: un múltiplo exacto de 30°.
double snapRotation(double rotation) =>
    (rotation / wheelStepDegrees).round() * wheelStepDegrees;

/// Camino más corto de [from] a [to], en pasos con signo (de -5 a 6).
int shortestSteps(int from, int to) {
  final d = (to - from) % circleLength;
  return d > circleLength ~/ 2 ? d - circleLength : d;
}

/// Rotación que lleva [target] a la ventana por el camino más corto.
double rotationToward(double rotation, int target) =>
    snapRotation(rotation) -
    shortestSteps(indexAtWindow(rotation), target) * wheelStepDegrees;

/// Cuántas tonalidades pasan por la ventana entre dos rotaciones.
int clicksBetween(double from, double to) =>
    ((to / wheelStepDegrees).round() - (from / wheelStepDegrees).round()).abs();

/// Ángulo de un toque respecto al centro: grados horarios desde arriba.
/// [dx] y [dy] son coordenadas de pantalla (y hacia abajo).
double touchAngle(double dx, double dy) => math.atan2(dx, -dy) * 180 / math.pi;

/// Diferencia entre dos ángulos, por el lado corto (de -180 a 180).
double angleDelta(double from, double to) {
  final d = (to - from) % 360;
  return d > 180 ? d - 360 : d;
}

/// Tonalidad bajo un toque en el ángulo [angle] con la rotación [rotation].
int indexAtTouch(double angle, double rotation) =>
    ((angle - rotation) / wheelStepDegrees).round() % circleLength;

/// Velocidad angular (grados/s, positiva = horario) de un dedo en ([dx], [dy])
/// respecto al centro que se mueve a ([vx], [vy]).
double angularVelocity(double dx, double dy, double vx, double vy) {
  final r2 = dx * dx + dy * dy;
  if (r2 == 0) return 0;
  return (dx * vy - dy * vx) / r2 * 180 / math.pi;
}

// ── Construcción paso a paso ────────────────────────────────────────────────

/// Un paso de "¿Cómo se arma?". Son 13: C, las 11 quintas siguientes y la
/// quinta que cierra el círculo otra vez en C.
class CircleStep {
  const CircleStep({
    required this.number,
    required this.tonic,
    required this.previousTonic,
    required this.explanation,
  });

  /// De 0 a 12.
  final int number;
  final int tonic;

  /// `null` en el primer paso.
  final int? previousTonic;
  final LocalizedText explanation;
}

/// Pasos de la construcción desde C, sumando 7 semitonos.
List<CircleStep> circleConstruction() => [
  for (var n = 0; n <= circleLength; n++)
    CircleStep(
      number: n,
      tonic: circleOrder[n % circleLength],
      previousTonic: n == 0 ? null : circleOrder[n - 1],
      explanation: _stepExplanation(n),
    ),
];

LocalizedText _stepExplanation(int n) {
  final tonic = pitchClassName(circleOrder[n % circleLength]);
  if (n == 0) {
    return LocalizedText(
      es: 'Empezamos en $tonic: ${keySignatureAt(0).name.es}.',
      en: 'We start on $tonic: ${keySignatureAt(0).name.en}.',
    );
  }
  final previous = pitchClassName(circleOrder[n - 1]);
  final sumEs = '$previous + $perfectFifth semitonos = $tonic';
  final sumEn = '$previous + $perfectFifth semitones = $tonic';
  if (n == circleLength) {
    return LocalizedText(
      es: '$sumEs: tras 12 quintas, el círculo se cierra donde empezó.',
      en: '$sumEn: after 12 fifths, the circle closes where it began.',
    );
  }
  final signature = keySignatureAt(n);
  final added = addedAccidentalAt(n)!;
  final note = pitchClassName(added.pitchClass);
  if (added.accidental == Accidental.sharp) {
    // El 6º sostenido cae en F, que en la armadura se escribe E#.
    final spelled = noteNames[added.pitchClass].length == 1;
    return LocalizedText(
      es:
          '$sumEs. Agrega un ♯ en $note${spelled ? ' (se escribe E#)' : ''}, '
          'la 7ª de $tonic. Armadura: ${signature.name.es}.',
      en:
          '$sumEn. It adds a ♯ on $note${spelled ? ' (written E#)' : ''}, the '
          '7th of $tonic. Key signature: ${signature.name.en}.',
    );
  }
  final fromLeft = pitchClassName(circleOrder[(n + 1) % circleLength]);
  return LocalizedText(
    es:
        '$sumEs. Armadura: ${signature.name.es}. De este lado se lee al revés: '
        'desde $fromLeft, un paso a la izquierda agrega un ♭ en $note, la 4ª '
        'de $tonic.',
    en:
        '$sumEn. Key signature: ${signature.name.en}. This side reads backward: '
        'from $fromLeft, one step left adds a ♭ on $note, the 4th of $tonic.',
  );
}
