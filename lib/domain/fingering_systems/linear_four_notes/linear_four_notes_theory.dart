import '../fingering_theory.dart';

const linearFourNotesTheory = FingeringSystemTheory(
  id: 'linear_four_notes',
  name: 'Linear (4NPS)',
  shortExplanation:
      'Toma hasta 4 notas de la escala por cuerda en orden estrictamente '
      'ascendente, sin saltar cuerdas. Genera una forma horizontal pura '
      'que se extiende a lo largo del diapasón — útil para runs legato '
      'y patrones de estiramiento amplio (wide-stretch).',
  shapeOrder: [],
  howShapesConnect:
      'A diferencia de CAGED, no hay formas fijas que se repitan — cada '
      'posición cubre un tramo continuo del diapasón y la siguiente '
      'posición simplemente continúa donde la anterior terminó.',
);
