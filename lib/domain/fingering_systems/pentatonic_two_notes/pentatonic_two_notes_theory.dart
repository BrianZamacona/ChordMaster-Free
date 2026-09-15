import '../fingering_theory.dart';

const pentatonicTwoNotesTheory = FingeringSystemTheory(
  id: 'pentatonic_two_notes',
  name: 'Pentatonic Box (2NPS)',
  shortExplanation:
      'La clásica caja pentatónica de 2 notas por cuerda, ideal para '
      'escalas de 5 notas (pentatónica mayor/menor). Para la escala '
      'blues, permite un grupo de 3 notas (4ª - 5ª bemol - 5ª) cuando '
      'la "blue note" cae entre las otras dos en la misma cuerda.',
  shapeOrder: [],
  howShapesConnect:
      'Las 5 cajas pentatónicas se conectan igual que las formas CAGED '
      '— de hecho comparten las mismas 5 posiciones en el diapasón, '
      'solo que cada caja usa 2 notas por cuerda en vez de 2-3.',
);
