import '../theory/double_stops.dart' show noteNames;
import 'barre_detection.dart';
import 'ergonomics.dart';
import 'voicing_adapter.dart';

/// Etiquetas por semitono respecto a la raíz; 9/11/13 se reducen módulo 12
/// (p. ej. la 9ª se etiqueta "2"), una simplificación deliberada.
const _toneLabelBySemitone = [
  'R', 'b2', '2', 'b3', '3', '4', 'b5', '5', 'b6', '6', 'b7', '7', //
];

class FingeringMetrics {
  const FingeringMetrics({
    required this.ergonomicCost,
    required this.fingers,
    required this.barre,
    required this.lowestFret,
    required this.fretSpan,
    required this.mutedStrings,
    required this.mutedInside,
    required this.bassNote,
    required this.inversion,
    required this.toneLabels,
  });

  /// `null` si el costo ergonómico es infinito.
  final double? ergonomicCost;

  /// Dedos distintos usados (> 0).
  final int fingers;
  final Barre? barre;

  /// Traste pisado más bajo (0 si todo está al aire).
  final int lowestFret;

  /// Máximo menos mínimo de los trastes pisados (> 0).
  final int fretSpan;
  final int mutedStrings;

  /// Muteadas entre la cuerda sonante más grave y la más aguda.
  final int mutedInside;
  final String bassNote;
  final String inversion;

  /// De la cuerda más grave a la más aguda, solo cuerdas sonantes.
  final List<String> toneLabels;
}

/// Analiza una digitación de chords.json (orden 6ª → 1ª, `-1` = muteada).
FingeringMetrics analyzeFingering({
  required List<int> jsonFrets,
  required List<int> jsonFingers,
  required String root,
  required List<int> intervals,
}) {
  final frets = VoicingAdapter.fromChordJson(jsonFrets);
  final engineFingers = VoicingAdapter.fingersFromChordJson(jsonFingers);
  final barre = detectBarre(frets, engineFingers);
  final cost = calculateErgonomicCost(
    ErgonomicVoicing(
      fretPositions: frets,
      fingerPositions: engineFingers,
      barre: barre,
    ),
  );

  final fretted = [
    for (final f in frets)
      if (f != null && f > 0) f,
  ];
  final sounding = [
    for (var s = 5; s >= 0; s--)
      if (frets[s] != null) s,
  ];

  var mutedInside = 0;
  if (sounding.isNotEmpty) {
    for (var s = sounding.last; s <= sounding.first; s++) {
      if (frets[s] == null) mutedInside++;
    }
  }

  final rootPc = noteNames.indexOf(root);
  int pitchClass(int s) => (standardOpenStringMidi[s] + frets[s]!) % 12;
  int midi(int s) => standardOpenStringMidi[s] + frets[s]!;
  final bassString = sounding.reduce((a, b) => midi(b) < midi(a) ? b : a);
  final bassPc = midi(bassString) % 12;
  final bassSemitone = (bassPc - rootPc + 12) % 12;
  final chordSemitones = [for (final i in intervals) i % 12];
  final position = chordSemitones.indexOf(bassSemitone);

  return FingeringMetrics(
    ergonomicCost: cost.isFinite ? cost : null,
    fingers: {
      for (final f in engineFingers)
        if (f > 0) f,
    }.length,
    barre: barre,
    lowestFret: fretted.isEmpty ? 0 : fretted.reduce((a, b) => a < b ? a : b),
    fretSpan: fretted.isEmpty
        ? 0
        : fretted.reduce((a, b) => a > b ? a : b) -
              fretted.reduce((a, b) => a < b ? a : b),
    mutedStrings: frets.where((f) => f == null).length,
    mutedInside: mutedInside,
    bassNote: noteNames[bassPc],
    inversion: switch (position) {
      -1 => 'Fuera del acorde',
      0 => 'Fundamental',
      _ => '$position\u00aa inversión',
    },
    toneLabels: [
      for (final s in sounding)
        _toneLabelBySemitone[(pitchClass(s) - rootPc + 12) % 12],
    ],
  );
}

/// Índices con el menor valor; ignora `null`. Vacío si no hay al menos dos
/// valores comparables o si todos son iguales.
Set<int> bestIndices(List<num?> values) {
  final present = [
    for (var i = 0; i < values.length; i++)
      if (values[i] != null) i,
  ];
  if (present.length < 2) return {};
  final min = present.map((i) => values[i]!).reduce((a, b) => a < b ? a : b);
  final best = {
    for (final i in present)
      if (values[i] == min) i,
  };
  return best.length == present.length ? {} : best;
}
