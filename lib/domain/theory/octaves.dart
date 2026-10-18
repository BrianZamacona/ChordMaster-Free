/// Patrones de octava en el diapasón (afinación estándar), deducidos de la
/// afinación y no escritos a mano.
///
/// Cuerdas numeradas como en `scales_master.json`: 1 = mi aguda … 6 = mi
/// grave.
library;

/// MIDI de cada cuerda al aire, índice 0 = 1ª cuerda.
const _openMidi = [64, 59, 55, 50, 45, 40];

/// Una forma de octava: desde [lowString] hasta [highString], la misma nota
/// [octaves] octavas más arriba cae [fretShift] trastes a la derecha (o a la
/// izquierda si es negativo).
class OctaveShape {
  const OctaveShape({
    required this.lowString,
    required this.highString,
    required this.fretShift,
    required this.octaves,
  });

  final int lowString;
  final int highString;
  final int fretShift;
  final int octaves;

  /// Cuerdas que hay en medio (1 = salta una cuerda).
  int get skipped => lowString - highString - 1;

  @override
  bool operator ==(Object other) =>
      other is OctaveShape &&
      other.lowString == lowString &&
      other.highString == highString &&
      other.fretShift == fretShift &&
      other.octaves == octaves;

  @override
  int get hashCode => Object.hash(lowString, highString, fretShift, octaves);

  @override
  String toString() => '$lowString→$highString ${fretShift >= 0 ? '+' : ''}$fretShift ($octaves oct)';
}

/// Todas las formas de octava que caben en una mano (a 3 trastes o menos),
/// ordenadas por cuerdas saltadas y de grave a aguda. Las cuerdas contiguas
/// no tienen: la octava queda a 7 trastes.
List<OctaveShape> octaveShapes() {
  final shapes = <OctaveShape>[];
  for (var low = 6; low >= 2; low--) {
    for (var high = low - 1; high >= 1; high--) {
      for (final octaves in const [1, 2]) {
        final shift = _openMidi[low - 1] + 12 * octaves - _openMidi[high - 1];
        if (shift.abs() <= 3) {
          shapes.add(
            OctaveShape(lowString: low, highString: high, fretShift: shift, octaves: octaves),
          );
        }
      }
    }
  }
  shapes.sort((a, b) {
    final bySkip = a.skipped.compareTo(b.skipped);
    return bySkip != 0 ? bySkip : b.lowString.compareTo(a.lowString);
  });
  return shapes;
}

/// Dónde está la nota [pitchClass] (C = 0) en cada cuerda, del traste 0 a
/// [maxFret].
List<({int string, int fret})> notePositions(int pitchClass, {int maxFret = 12}) => [
  for (var string = 6; string >= 1; string--)
    for (var fret = 0; fret <= maxFret; fret++)
      if ((_openMidi[string - 1] + fret) % 12 == pitchClass) (string: string, fret: fret),
];

/// Pares (nota grave, su octava) de [pitchClass] según [shape], dentro de
/// los trastes 0 a [maxFret].
List<(({int string, int fret}), ({int string, int fret}))> octavePairs(
  int pitchClass,
  OctaveShape shape, {
  int maxFret = 12,
}) => [
  for (final p in notePositions(pitchClass, maxFret: maxFret))
    if (p.string == shape.lowString &&
        p.fret + shape.fretShift >= 0 &&
        p.fret + shape.fretShift <= maxFret)
      (p, (string: shape.highString, fret: p.fret + shape.fretShift)),
];
