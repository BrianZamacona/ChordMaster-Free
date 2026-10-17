import '../../../core/i18n/tr.dart';
import '../fingering_theory.dart';

const pentatonicTwoNotesTheory = FingeringSystemTheory(
  id: 'pentatonic_two_notes',
  name: LocalizedText(es: 'Caja pentatónica (2NPS)', en: 'Pentatonic Box (2NPS)'),
  shortExplanation: LocalizedText(
    es: 'La clásica caja pentatónica de 2 notas por cuerda, ideal para '
        'escalas de 5 notas (pentatónica mayor/menor). En la escala '
        'blues, una cuerda lleva 3 notas (4ª - 5ª bemol - 5ª) cuando la '
        '"blue note" cae entre las otras dos.',
    en: 'The classic pentatonic box with 2 notes per string, made for '
        '5-note scales (major/minor pentatonic). In the blues scale one '
        'string holds 3 notes (4th - flat 5th - 5th) when the "blue note" '
        'falls between the other two.',
  ),
  shapeOrder: [],
  howShapesConnect: LocalizedText(
    es: 'Las 5 cajas pentatónicas se conectan igual que las formas CAGED: '
        'ocupan las mismas 5 zonas del diapasón, pero cada caja usa 2 '
        'notas por cuerda en vez de 2-3.',
    en: 'The 5 pentatonic boxes connect just like the CAGED shapes: they '
        'sit in the same 5 areas of the neck, but each box uses 2 notes per '
        'string instead of 2-3.',
  ),
);
