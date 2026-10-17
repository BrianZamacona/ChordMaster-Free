import 'dart:ui' show Offset, Size;

import '../../../domain/theory/double_stops.dart';

const fretboardLeftPad = 20.0;
const fretboardTop = 16.0;
const fretboardBottom = 20.0;

/// Posición del centro de una nota en el lienzo. Única fuente de coordenadas
/// para notas y líneas. Cuerda 0 = 1ª cuerda (arriba), igual que `FretboardDiagram`.
Offset noteOffset(
  int string,
  int fret,
  Size size, {
  int startFret = 0,
  int fretCount = 13,
}) {
  final fretWidth = (size.width - fretboardLeftPad) / fretCount;
  final stringSpacing = (size.height - fretboardTop - fretboardBottom) / 5;
  return Offset(
    fretboardLeftPad + (fret - startFret + 0.5) * fretWidth,
    fretboardTop + string * stringSpacing,
  );
}

/// Centro de la etiqueta de grado. Solo las dos cuerdas de la pareja llevan
/// notas, así que va en el hueco libre entre la cuerda superior de la pareja y
/// la de encima, alineada con el centro de la línea; si la pareja empieza en la
/// 1ª cuerda (sin hueco encima), va bajo la cuerda inferior. Nunca encima de
/// una nota: con 13 trastes una nota casi llena el ancho de un traste.
Offset segmentLabelOffset(Offset from, Offset to, double stringSpacing) {
  final x = (from.dx + to.dx) / 2;
  final upper = from.dy < to.dy ? from.dy : to.dy;
  final lower = from.dy < to.dy ? to.dy : from.dy;
  return upper - stringSpacing / 2 < fretboardTop
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
  int fretCount = 13,
}) => [
  for (final p in pairs)
    DoubleStopSegment(
      noteOffset(
        p.root.stringIndex,
        p.root.fret,
        size,
        startFret: startFret,
        fretCount: fretCount,
      ),
      noteOffset(
        p.interval.stringIndex,
        p.interval.fret,
        size,
        startFret: startFret,
        fretCount: fretCount,
      ),
      p,
    ),
];
