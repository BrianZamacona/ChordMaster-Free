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

/// Centro de la etiqueta de grado: sobre la línea, o a la derecha si es casi vertical.
Offset segmentLabelOffset(Offset from, Offset to) {
  final mid = (from + to) / 2;
  return (to.dx - from.dx).abs() < 2
      ? mid + const Offset(14, 0)
      : mid + const Offset(0, -7);
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
