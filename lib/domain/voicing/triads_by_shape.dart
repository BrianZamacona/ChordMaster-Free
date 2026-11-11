/// Las tríadas de un acorde agrupadas por la forma CAGED en la que caen
/// (decisión del usuario tras revisar las apps CAGED): una tríada es de una
/// forma si todas sus notas están dentro de los trastes de esa forma, tal como
/// viene o una octava más arriba o más abajo.
library;

/// Los trastes que ocupa una forma: del más bajo al más alto de los que suenan
/// (una cuerda al aire cuenta como traste 0).
typedef ShapeWindow = ({String shape, int lowest, int highest});

/// Una tríada de una forma: su índice en `triadInversions` y sus trastes ya
/// llevados a la forma (6ª → 1ª, `-1` = no suena).
typedef ShapeTriad = ({int index, List<int> frets});

/// La ventana de la forma [shape] con trastes [jsonFrets] (6ª → 1ª).
ShapeWindow shapeWindow(String shape, List<int> jsonFrets) {
  final played = [for (final f in jsonFrets) if (f >= 0) f];
  return (
    shape: shape,
    lowest: played.reduce((a, b) => a < b ? a : b),
    highest: played.reduce((a, b) => a > b ? a : b),
  );
}

/// [triad] dentro de [window]: tal cual o una octava arriba o abajo (las
/// tríadas son móviles, sin cuerdas al aire, así que ninguna nota puede bajar
/// del traste 1 ni pasar del [maxFret]). `null` si no cabe.
List<int>? triadInWindow(List<int> triad, ShapeWindow window, {int maxFret = 24}) {
  for (final shift in const [0, 12, -12]) {
    final played = [for (final f in triad) if (f >= 0) f + shift];
    if (played.isEmpty) return null;
    final lo = played.reduce((a, b) => a < b ? a : b);
    final hi = played.reduce((a, b) => a > b ? a : b);
    if (lo >= 1 && hi <= maxFret && lo >= window.lowest && hi <= window.highest) {
      return [for (final f in triad) if (f < 0) f else f + shift];
    }
  }
  return null;
}

/// Las tríadas [triads] que caen en cada forma de [shapes], en el orden de las
/// formas. Una tríada puede caer en dos formas vecinas.
List<({ShapeWindow window, List<ShapeTriad> triads})> triadsByShape(
  List<({String shape, List<int> frets})> shapes,
  List<List<int>> triads,
) => [
  for (final s in shapes)
    (
      window: shapeWindow(s.shape, s.frets),
      triads: [
        for (final (i, t) in triads.indexed)
          if (triadInWindow(t, shapeWindow(s.shape, s.frets)) case final moved?) (index: i, frets: moved),
      ],
    ),
];

/// Los índices de las tríadas que no caben en ninguna forma: quedan entre dos.
List<int> triadsBetweenShapes(
  List<({String shape, List<int> frets})> shapes,
  List<List<int>> triads,
) {
  final placed = {
    for (final g in triadsByShape(shapes, triads))
      for (final t in g.triads) t.index,
  };
  return [for (var i = 0; i < triads.length; i++) if (!placed.contains(i)) i];
}
