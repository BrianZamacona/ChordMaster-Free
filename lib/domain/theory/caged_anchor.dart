/// El recorrido CAGED desde el ancla (decisión del usuario tras revisar las
/// apps CAGED): encontrar la tónica en la 6ª, la 5ª y la 4ª cuerda y armar
/// cada forma desde la suya. Todo por regla; las formas salen de chords.json.
library;

import 'notes.dart';

/// Las formas en el orden en que se suceden subiendo por el mástil.
const cagedOrder = ['C', 'A', 'G', 'E', 'D'];

/// La cuerda en la que cada forma tiene su raíz más grave: su ancla.
const cagedAnchorString = {'E': 6, 'G': 6, 'A': 5, 'C': 5, 'D': 4};

/// Los pasos del recorrido.
enum CagedAnchorStep { anchorSix, anchorFiveFour, fromSix, fromFive, fromFour }

/// Las formas que se arman en el paso [step] (vacío en los de buscar anclas).
List<String> shapesOf(CagedAnchorStep step) => switch (step) {
  CagedAnchorStep.fromSix => const ['E', 'G'],
  CagedAnchorStep.fromFive => const ['A', 'C'],
  CagedAnchorStep.fromFour => const ['D'],
  _ => const [],
};

/// El traste más bajo (0–11) donde la cuerda [string] (6 = mi grave … 1 = mi
/// aguda) da la tónica [root] (semitono, C = 0).
int anchorFret(int string, int root) => (root - standardOpenStringMidi[string - 1]) % 12;

/// En la forma [shape] (trastes [jsonFrets] de chords.json, 6ª → 1ª), el
/// traste donde su cuerda ancla da la tónica [root]; `null` si esa cuerda no
/// suena o no da la tónica.
int? shapeAnchorFret(String shape, List<int> jsonFrets, int root) {
  final string = cagedAnchorString[shape];
  if (string == null) return null;
  final fret = jsonFrets[6 - string];
  if (fret < 0) return null;
  return (standardOpenStringMidi[string - 1] + fret - root) % 12 == 0 ? fret : null;
}

/// Hacia dónde se arma la forma desde su ancla [anchor]: `true` si ninguna
/// nota pisada queda por debajo (empieza en el ancla y sube, como E, A y D),
/// `false` si ninguna queda por encima (termina en el ancla y baja hacia la
/// cejuela, como G y C); `null` si tiene notas a los dos lados.
bool? shapeGoesUp(List<int> jsonFrets, int anchor) {
  final fretted = [for (final f in jsonFrets) if (f > 0) f];
  if (fretted.every((f) => f >= anchor)) return true;
  if (fretted.every((f) => f <= anchor)) return false;
  return null;
}
