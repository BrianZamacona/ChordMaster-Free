import 'dart:ui' show Offset, Size;

import '../../../domain/theory/double_stops.dart';
import '../../widgets/fret_grid_geometry.dart';

/// Geometría de un diapasón de double stops, la misma de `FretboardDiagram`.
FretGridGeometry doubleStopGrid(
  Size size, {
  int startFret = 0,
  int endFret = 12,
}) => FretGridGeometry(
  width: size.width,
  height: size.height,
  startFret: startFret,
  endFret: endFret,
);

/// Posición del centro de una nota en el lienzo. Única fuente de coordenadas
/// para notas y líneas. Cuerda 0 = 1ª cuerda (arriba), como en el dominio; el
/// traste 0 cae en la columna de afinación y el traste N en su celda.
Offset noteOffset(
  int string,
  int fret,
  Size size, {
  int startFret = 0,
  int endFret = 12,
}) => doubleStopGrid(
  size,
  startFret: startFret,
  endFret: endFret,
).noteOffset(string + 1, fret);

/// Centro de la etiqueta de grado. Solo las dos cuerdas de la pareja llevan
/// notas, así que va en el hueco libre entre la cuerda superior de la pareja y
/// la de encima, alineada con el centro de la línea; si la pareja empieza en la
/// 1ª cuerda (sin hueco encima), va bajo la cuerda inferior. Nunca encima de
/// una nota: con 13 trastes una nota casi llena el ancho de un traste. Con
/// [nutX], si la línea cruza la cejuela la etiqueta se corre a su derecha para
/// que la línea gruesa no la tape.
Offset segmentLabelOffset(
  Offset from,
  Offset to,
  double stringSpacing, {
  double? nutX,
}) {
  const nutClearance = 9.0;
  final middle = (from.dx + to.dx) / 2;
  final x = nutX != null && (middle - nutX).abs() < nutClearance
      ? nutX + nutClearance
      : middle;
  final upper = from.dy < to.dy ? from.dy : to.dy;
  final lower = from.dy < to.dy ? to.dy : from.dy;
  return upper - stringSpacing / 2 < FretGridGeometry.top
      ? Offset(x, lower + stringSpacing / 2)
      : Offset(x, upper - stringSpacing / 2);
}

class DoubleStopSegment {
  const DoubleStopSegment(this.from, this.to, this.pair);

  final Offset from;
  final Offset to;
  final DoubleStopPair pair;
}

/// Un segmento por pareja, calculado con [noteOffset].
List<DoubleStopSegment> doubleStopSegments(
  List<DoubleStopPair> pairs,
  Size size, {
  int startFret = 0,
  int endFret = 12,
}) => [
  for (final p in pairs)
    DoubleStopSegment(
      noteOffset(
        p.root.stringIndex,
        p.root.fret,
        size,
        startFret: startFret,
        endFret: endFret,
      ),
      noteOffset(
        p.interval.stringIndex,
        p.interval.fret,
        size,
        startFret: startFret,
        endFret: endFret,
      ),
      p,
    ),
];
