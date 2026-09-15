import '../fingering_theory.dart';

/// Shared explanation of the CAGED system.
///
/// Read by both `features/chords` (chord explorer) and the scale
/// explorer via [FingeringSystemsRegistry] — neither should hardcode
/// this text separately.
const cagedTheory = FingeringSystemTheory(
  id: 'caged',
  name: 'CAGED',
  shortExplanation:
      'CAGED toma las 5 formas de acorde abierto — C, A, G, E, D — y las '
      'usa como referencia para ubicar cualquier acorde o escala en '
      'cualquier parte del diapasón. Cada forma cubre una caja de 4 '
      'trastes; cinco formas conectadas cubren el mástil completo.',
  shapeOrder: ['C', 'A', 'G', 'E', 'D'],
  howShapesConnect:
      'Las formas se solapan: la nota raíz al final de una forma es la '
      'misma nota raíz al inicio de la siguiente. Por eso, al subir por '
      'el diapasón, las 5 formas se repiten en el mismo orden C-A-G-E-D '
      'antes de volver a empezar una octava arriba.',
);
