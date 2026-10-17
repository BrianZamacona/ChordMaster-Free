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

  /// Inverso: una lista por cuerda en orden del motor (0 = 1ª) al orden de
  /// chords.json (6ª → 1ª), para que la UI dibuje sin invertir nada.
  static List<T> toChordJsonOrder<T>(List<T> engineOrder) =>
      engineOrder.reversed.toList();

  /// Índice de cuerda del motor (0 = 1ª) a índice de chords.json (0 = 6ª).
  static int stringIndexToChordJson(int engineString) => 5 - engineString;
}
