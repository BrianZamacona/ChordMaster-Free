import '../../../core/i18n/tr.dart';
import '../fingering_theory.dart';

const threeNpsTheory = FingeringSystemTheory(
  id: 'three_nps',
  name: LocalizedText(es: '3NPS', en: '3NPS'),
  shortExplanation: LocalizedText(
    es: '3 notas por cuerda (3 Notes Per String): cada cuerda lleva '
        'exactamente 3 notas de la escala, en orden. Produce digitaciones '
        'simétricas, fáciles de memorizar y cómodas para tocar rápido '
        '(alternate picking, legato).',
    en: '3 Notes Per String: each string holds exactly 3 notes of the scale, '
        'in order. It gives symmetric fingerings that are easy to memorize '
        'and comfortable for fast playing (alternate picking, legato).',
  ),
  shapeOrder: [],
  howShapesConnect: LocalizedText(
    es: 'No tiene formas con nombre como CAGED: las 7 posiciones se '
        'numeran según el grado de la escala con el que empiezan '
        '(posición 1 = empieza en la tónica, posición 2 = en el segundo '
        'grado, etc.), y cada una se conecta con la siguiente subiendo '
        '2-3 trastes en el diapasón.',
    en: 'It has no named shapes like CAGED: the 7 positions are numbered by '
        'the scale degree they start on (position 1 = starts on the tonic, '
        'position 2 = on the second degree, and so on), and each one '
        'connects to the next 2-3 frets higher.',
  ),
);
