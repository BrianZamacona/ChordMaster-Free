/// Llaves de posición bajo el mástil (decisión del usuario tras revisar las
/// apps de mástil): dónde va cada forma de un sistema, en todas las octavas
/// donde cabe, repartidas en filas para que dos llaves nunca se encimen.
library;

/// Una llave: la forma [index] (en la lista dada) de los trastes [start] a
/// [end], en la fila [row] (0 = la de arriba).
typedef PositionBracket = ({int index, int start, int end, int row});

/// Las llaves de las formas [spans] (traste más bajo y más alto de cada una)
/// en todas las octavas donde caben enteras, entre la cuerda al aire y
/// [maxFret]; como [patternAcrossNeck], nunca recorta. Ordenadas por traste;
/// cada una va en la primera fila donde no toca a otra (compartir un traste
/// cuenta como tocarse).
List<PositionBracket> positionBrackets(
  List<({int start, int end})> spans, {
  int maxFret = 24,
}) {
  final copies = [
    for (final (index, span) in spans.indexed)
      for (var shift = -maxFret; shift <= maxFret; shift += 12)
        if (span.start + shift >= 0 && span.end + shift <= maxFret)
          (index: index, start: span.start + shift, end: span.end + shift),
  ]..sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : a.end.compareTo(b.end));
  final rowEnds = <int>[];
  return [
    for (final c in copies)
      (index: c.index, start: c.start, end: c.end, row: _placeIn(rowEnds, c.start, c.end)),
  ];
}

/// La primera fila de [rowEnds] (último traste ocupado de cada una) libre
/// desde [start]; si no hay, una nueva. Anota [end] en ella.
int _placeIn(List<int> rowEnds, int start, int end) {
  for (var row = 0; row < rowEnds.length; row++) {
    if (rowEnds[row] < start) {
      rowEnds[row] = end;
      return row;
    }
  }
  rowEnds.add(end);
  return rowEnds.length - 1;
}

/// Cuántas filas ocupan [brackets].
int bracketRows(List<PositionBracket> brackets) =>
    brackets.isEmpty ? 0 : brackets.map((b) => b.row).reduce((a, b) => a > b ? a : b) + 1;
