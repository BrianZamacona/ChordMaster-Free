import '../../../core/i18n/tr.dart';
import '../fingering_theory.dart';

/// Shared explanation of the CAGED system.
///
/// Read by both `features/chords` (chord explorer) and the scale
/// explorer via [FingeringSystemsRegistry] — neither should hardcode
/// this text separately.
const cagedTheory = FingeringSystemTheory(
  id: 'caged',
  name: LocalizedText(es: 'CAGED', en: 'CAGED'),
  shortExplanation: LocalizedText(
    es: 'CAGED toma las 5 formas de acorde abierto — C, A, G, E, D — y las '
        'usa como referencia para ubicar cualquier acorde o escala en '
        'cualquier parte del diapasón. Cada forma cubre una caja de 4 '
        'trastes; cinco formas conectadas cubren el mástil completo.',
    en: 'CAGED takes the 5 open chord shapes — C, A, G, E, D — and uses them '
        'as landmarks to find any chord or scale anywhere on the neck. Each '
        'shape covers a box of about 4 frets; five connected shapes cover '
        'the whole neck.',
  ),
  shapeOrder: ['C', 'A', 'G', 'E', 'D'],
  howShapesConnect: LocalizedText(
    es: 'Las formas se solapan: la nota raíz al final de una forma es la '
        'misma nota raíz al inicio de la siguiente. Por eso, al subir por '
        'el diapasón, las 5 formas se repiten en el mismo orden C-A-G-E-D '
        'antes de volver a empezar una octava arriba.',
    en: 'The shapes overlap: the root at the end of one shape is the same '
        'root at the start of the next. That is why, moving up the neck, '
        'the 5 shapes repeat in the same C-A-G-E-D order before starting '
        'again an octave higher.',
  ),
);
