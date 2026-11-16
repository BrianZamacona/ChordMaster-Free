import '../../../core/i18n/tr.dart';
import '../fingering_theory.dart';

/// Posiciones de un dedo por traste (decisión del usuario): la idea del método
/// de guitarra de Berklee, pero sin su nombre, porque la guía con la que se armó
/// la regla no se pudo comparar con el libro. Las posiciones salen de
/// `tool/regenerate_scales_master.py` (`one_finger_box`).
const oneFingerTheory = FingeringSystemTheory(
  id: 'one_finger',
  name: LocalizedText(es: 'Un dedo por traste', en: 'One finger per fret'),
  shortExplanation: LocalizedText(
    es: 'La mano se queda quieta en cuatro trastes, un dedo en cada uno: el '
        'índice marca la posición. Solo el índice se estira un traste hacia '
        'atrás y el meñique uno hacia adelante, y cada cuerda lleva 2 o 3 '
        'notas. Es la idea de los métodos de lectura, como el de Berklee: tocar '
        'sin mirar el mástil y sin mover la mano.',
    en: 'The hand stays put over four frets, one finger on each: the index '
        'marks the position. Only the index stretches one fret back and the '
        'pinky one fret forward, and each string carries 2 or 3 notes. It is '
        'the idea behind sight-reading methods such as Berklee\'s: play '
        'without looking at the neck and without moving the hand.',
  ),
  shapeOrder: [],
  howShapesConnect: LocalizedText(
    es: 'Hay una posición por cada grado de la escala en la 6ª cuerda: la '
        'siguiente empieza en el grado de arriba y se enciman, así que pasar '
        'de una a otra es cambiar el índice de traste sin perder la escala.',
    en: 'There is one position for each scale degree on the 6th string: the '
        'next one starts on the degree above and they overlap, so moving '
        'from one to the next means shifting the index without losing the '
        'scale.',
  ),
);
