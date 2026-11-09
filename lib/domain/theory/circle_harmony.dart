/// Más allá de una tonalidad, leído en el círculo de quintas (fase 2): las
/// dominantes secundarias, modular a otra tonalidad, pedir acordes a la menor
/// paralela y los modos ordenados por brillo. Todo por regla: los acordes
/// salen de las escalas y los pasos del círculo de [circleOrder].
library;

import 'circle_of_fifths.dart';
import 'intervals.dart';
import 'scale_insights.dart';

/// Un acorde visto desde una tonalidad: número romano, raíz (clase de altura)
/// y tipo (clave de chords.json).
typedef CircleChord = ({String numeral, int root, String type});

/// Paso en el círculo de [from] a [to], de −5 a 6 (positivo = a la derecha,
/// hacia los ♯).
int circleStep(int from, int to) {
  final d = (circleIndexOf(to) - circleIndexOf(from)) % circleLength;
  return d > circleLength ~/ 2 ? d - circleLength : d;
}

String _romanOf(int semitones) =>
    const ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'][majorScale.indexOf(semitones % 12)];

// ── Dominantes secundarias ─────────────────────────────────────────────────

/// El V7 de un acorde diatónico: [dominant] resuelve en [target].
typedef SecondaryDominant = ({CircleChord target, CircleChord dominant});

/// La raíz del dominante de [root]: una quinta arriba, su vecino de la
/// derecha en el círculo.
int dominantOf(int root) => circleOrder[(circleIndexOf(root) + 1) % circleLength];

/// El V7 de cada acorde diatónico de [tonic] menos I y vii° (el de I es el V7
/// de la tonalidad; vii° no se tonicaliza): V7/ii, V7/iii, V7/IV, V7/V y V7/vi.
List<SecondaryDominant> secondaryDominants(int tonic) => [
  for (final c in diatonicByDegree(tonic))
    if (c.numeral != 'I' && c.type != 'diminished')
      () {
        final root = dominantOf(c.root);
        return (
          target: (numeral: c.numeral, root: c.root, type: c.type),
          dominant: (numeral: '${_romanOf(root - tonic)}7', root: root, type: 'dominant7'),
        );
      }(),
];

/// III7 – VI7 – II7 – V7 – I: cada dominante resuelve en el siguiente, un
/// paso a la izquierda en el círculo, hasta la tónica.
List<CircleChord> dominantChain(int tonic) => [
  for (final s in const [4, 9, 2, 7]) (numeral: '${_romanOf(s)}7', root: (tonic + s) % 12, type: 'dominant7'),
  (numeral: 'I', root: tonic % 12, type: 'major'),
];

/// ii7 – V7 – Imaj7: tres posiciones seguidas del círculo, contra reloj.
List<CircleChord> twoFiveOne(int tonic) => [
  (numeral: 'ii7', root: (tonic + 2) % 12, type: 'minor7'),
  (numeral: 'V7', root: (tonic + 7) % 12, type: 'dominant7'),
  (numeral: 'Imaj7', root: tonic % 12, type: 'major7'),
];

// ── Modulación ─────────────────────────────────────────────────────────────

/// Un acorde que está en las dos tonalidades: sirve de puente.
typedef PivotChord = ({int root, String type, String numeralInFrom, String numeralInTo});

/// Lo que comparten dos tonalidades mayores.
class Modulation {
  const Modulation({
    required this.from,
    required this.to,
    required this.steps,
    required this.commonNotes,
    required this.pivots,
  });

  final int from;
  final int to;

  /// Pasos en el círculo (−5 a 6; positivo = a la derecha).
  final int steps;

  /// Notas comunes, en el orden de la escala de [from].
  final List<int> commonNotes;

  /// Tríadas diatónicas de las dos, en orden de grado de [from].
  final List<PivotChord> pivots;
}

Modulation modulation(int from, int to) {
  final toNotes = {for (final i in majorScale) (to + i) % 12};
  final toChords = {for (final c in diatonicByDegree(to)) (c.root, c.type): c.numeral};
  return Modulation(
    from: from % 12,
    to: to % 12,
    steps: circleStep(from, to),
    commonNotes: [
      for (final i in majorScale)
        if (toNotes.contains((from + i) % 12)) (from + i) % 12,
    ],
    pivots: [
      for (final c in diatonicByDegree(from))
        if (toChords[(c.root, c.type)] case final n?)
          (root: c.root, type: c.type, numeralInFrom: c.numeral, numeralInTo: n),
    ],
  );
}

// ── Intercambio modal ──────────────────────────────────────────────────────

/// La menor paralela de [tonic] (misma tónica, escala menor) tiene la
/// armadura de su relativa mayor, tres pasos a la izquierda en el círculo.
int parallelMinorIndex(int tonic) => (circleIndexOf(tonic) - 3) % circleLength;

/// Los acordes más usados que se le piden prestados a la menor paralela: iv,
/// ♭VI y ♭VII (raíces nombradas con sostenidos, como en toda la app).
List<CircleChord> borrowedChords(int tonic) {
  final minor = {for (final t in diatonicTriads(naturalMinorScale)) t.semitones: t};
  return [
    for (final s in const [5, 8, 10])
      (numeral: minor[s]!.numeral, root: (tonic + s) % 12, type: minor[s]!.type),
  ];
}

// ── Modos por brillo ───────────────────────────────────────────────────────

/// Un modo sobre una tónica, ordenado del más brillante al más oscuro.
class ModeStep {
  const ModeStep({
    required this.modeId,
    required this.intervals,
    required this.parent,
    required this.steps,
    required this.changed,
  });

  /// Id en `scales_master.json` (lydian, ionian…).
  final String modeId;
  final List<int> intervals;

  /// Tonalidad mayor de la que sale (sus mismas notas).
  final int parent;

  /// Pasos de [parent] desde la mayor de la tónica: +1 el lidio, 0 el jónico,
  /// −1 el mixolidio… −5 el locrio.
  final int steps;

  /// La nota que cambia respecto del modo anterior, ya nombrada (`b7`, `b3`…);
  /// en el lidio, la que sube respecto del jónico (`#4`).
  final String changed;
}

/// Grado de la escala mayor donde empieza cada modo, del más brillante al
/// más oscuro.
const _brightnessDegrees = [3, 0, 4, 1, 5, 2, 6];
const _modeIds = ['ionian', 'dorian', 'phrygian', 'lydian', 'mixolydian', 'aeolian', 'locrian'];

List<int> _rotation(int degree) => [
  for (var k = 0; k < 7; k++) (majorScale[(degree + k) % 7] - majorScale[degree]) % 12,
];

/// Lidio → jónico → mixolidio → dórico → eolio → frigio → locrio: cada uno
/// sale de la mayor un paso a la izquierda de la anterior, y cambia una sola
/// nota, que baja un semitono.
List<ModeStep> modesByBrightness(int tonic) {
  final steps = <ModeStep>[];
  List<int>? previous;
  for (final degree in _brightnessDegrees) {
    final intervals = _rotation(degree);
    final parent = (tonic - majorScale[degree]) % 12;
    final reference = previous ?? _rotation(0);
    final changedAt = [for (var k = 0; k < 7; k++) if (intervals[k] != reference[k]) k].single;
    steps.add(
      ModeStep(
        modeId: _modeIds[degree],
        intervals: intervals,
        parent: parent,
        steps: circleStep(tonic, parent),
        changed: spellInterval(intervals[changedAt], intervals),
      ),
    );
    previous = intervals;
  }
  return steps;
}
