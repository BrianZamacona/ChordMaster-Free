/// Digitación en orden de cuerdas del motor: índice 0 = 1ª cuerda (mi aguda).
/// `null` = cuerda muteada.
typedef EngineFrets = List<int?>;

class VoicingAdapter {
  const VoicingAdapter._();

  /// Convierte `fretPositions` de chords.json (6ª → 1ª, `-1` = muteada) al
  /// orden del motor. Único punto de inversión del proyecto.
  static EngineFrets fromChordJson(List<int> fretPositions) => [
    for (final fret in fretPositions.reversed)
      if (fret < 0) null else fret,
  ];

  /// `fingerPositions` de chords.json (6ª → 1ª) al orden del motor.
  static List<int> fingersFromChordJson(List<int> fingerPositions) =>
      fingerPositions.reversed.toList();
}
