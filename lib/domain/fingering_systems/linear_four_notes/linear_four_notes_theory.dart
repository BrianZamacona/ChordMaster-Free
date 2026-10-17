import '../../../core/i18n/tr.dart';
import '../fingering_theory.dart';

const linearFourNotesTheory = FingeringSystemTheory(
  id: 'linear_four_notes',
  name: LocalizedText(es: 'Lineal (4NPS)', en: 'Linear (4NPS)'),
  shortExplanation: LocalizedText(
    es: 'Toma hasta 4 notas de la escala por cuerda en orden estrictamente '
        'ascendente, sin saltar cuerdas. Genera una forma horizontal que '
        'se extiende a lo largo del diapasón: útil para runs legato y '
        'patrones de estiramiento amplio.',
    en: 'It takes up to 4 scale notes per string in strictly ascending '
        'order, without skipping strings. The result is a horizontal shape '
        'that stretches along the neck: useful for legato runs and '
        'wide-stretch patterns.',
  ),
  shapeOrder: [],
  howShapesConnect: LocalizedText(
    es: 'A diferencia de CAGED, no hay formas fijas que se repitan: cada '
        'posición cubre un tramo continuo del diapasón y la siguiente '
        'continúa donde la anterior terminó.',
    en: 'Unlike CAGED, there are no fixed repeating shapes: each position '
        'covers a continuous stretch of the neck and the next one picks up '
        'where the previous one ended.',
  ),
);
