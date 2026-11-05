import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Afinación estándar como etiquetas de cuerda, de la 1ª (arriba) a la 6ª.
const tuningLabels = ['e', 'B', 'G', 'D', 'A', 'E'];

/// Trastes con un punto en el mástil.
const inlayFrets = [3, 5, 7, 9, 15, 17, 19, 21];

/// Trastes con doble punto.
const doubleInlayFrets = [12, 24];

/// Coordenadas de un diapasón dibujado: la única fuente para notas, líneas,
/// puntos y números de todos los diapasones de escala.
///
/// La cuerda al aire no es un traste: a la izquierda de la cejuela hay una
/// columna de ancho fijo con la afinación, donde van las notas al aire. El
/// traste N es la celda entre los alambres N-1 y N, así que el traste 1 es la
/// primera celda tras la cejuela.
class FretGridGeometry {
  const FretGridGeometry({
    required this.width,
    required this.height,
    required this.startFret,
    required this.endFret,
    this.fixedFretWidth,
    this.maxNoteRadius = 11,
  });

  /// Ancho de la columna de afinación; la cejuela va en su borde derecho.
  static const openColumnWidth = 32.0;
  static const tuningLabelX = 6.0;
  static const openNoteX = 21.0;

  /// Las cuerdas empiezan justo después de su nombre.
  static const stringStartX = 12.0;
  static const openNoteMaxRadius = 9.0;
  static const top = 16.0;
  static const bottom = 20.0;

  final double width;
  final double height;
  final int startFret;
  final int endFret;

  /// Ancho de traste fijo (mástil con scroll); sin él, se reparte [width].
  final double? fixedFretWidth;
  final double maxNoteRadius;

  /// Primer traste con celda: el 0 solo existe como columna de afinación.
  int get firstFret => math.max(startFret, 1);
  int get lastFret => math.max(endFret, firstFret);
  int get cellCount => lastFret - firstFret + 1;

  /// La cejuela solo se dibuja si la celda de al lado es de verdad el traste 1.
  bool get hasNut => firstFret == 1;

  double get nutX => openColumnWidth;
  double get fretWidth => fixedFretWidth ?? (width - nutX) / cellCount;
  double get stringSpacing => (height - top - bottom) / 5;
  double get boardBottom => top + 5 * stringSpacing;
  double get radius =>
      math.min(maxNoteRadius, math.min(fretWidth, stringSpacing) * 0.42);

  /// Radio en la columna de afinación, donde también va el nombre de la cuerda.
  double get openRadius => math.min(radius, openNoteMaxRadius);

  /// Ancho total: columna de afinación más todas las celdas.
  double get boardWidth => nutX + cellCount * fretWidth;

  /// Alambre derecho del traste [wire]; el alambre 0 es la cejuela.
  double fretLineX(int wire) => nutX + (wire - firstFret + 1) * fretWidth;

  /// Altura de la cuerda [string] (1 = mi aguda).
  double stringY(int string) => top + (string - 1) * stringSpacing;

  /// Centro de la nota de la cuerda [string] (1 = mi aguda) en el traste
  /// [fret]: el 0 cae en la columna de afinación y el resto en su celda.
  Offset noteOffset(int string, int fret) => Offset(
    fret == 0 ? openNoteX : fretLineX(fret) - fretWidth / 2,
    stringY(string),
  );
}
