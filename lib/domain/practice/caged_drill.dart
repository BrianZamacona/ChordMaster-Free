/// Práctica CAGED sorteada (decisión del usuario tras revisar las apps CAGED):
/// una tónica y una forma al azar, y tres fases sobre ellas: la escala mayor en
/// esa forma, su arpegio y el acorde de la forma.
library;

import 'dart:math';

import '../theory/caged_anchor.dart';

/// Lo sorteado: la tónica (semitono, C = 0) y la forma (`C A G E D`).
typedef CagedDraw = ({int root, String shape});

/// Las fases, en orden.
enum CagedDrillPhase { scale, arpeggio, chord }

/// Una tónica y una forma al azar con [rng], nunca la misma pareja que
/// [previous] (hay 60).
CagedDraw drawCaged(Random rng, {CagedDraw? previous}) {
  while (true) {
    final draw = (root: rng.nextInt(12), shape: cagedOrder[rng.nextInt(cagedOrder.length)]);
    if (draw != previous) return draw;
  }
}

/// El id en scales_master.json de la posición CAGED de la forma [shape].
String cagedPositionId(String shape) => 'caged_${shape.toLowerCase()}';
