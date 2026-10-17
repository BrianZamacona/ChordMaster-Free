import '../i18n/tr.dart';

/// Nombre completo de un intervalo por semitonos (hasta la 13ª), en es/en.
const _names = <int, LocalizedText>{
  0: LocalizedText(es: 'Unísono', en: 'Unison'),
  1: LocalizedText(es: '2ª menor', en: 'Minor 2nd'),
  2: LocalizedText(es: '2ª mayor', en: 'Major 2nd'),
  3: LocalizedText(es: '3ª menor', en: 'Minor 3rd'),
  4: LocalizedText(es: '3ª mayor', en: 'Major 3rd'),
  5: LocalizedText(es: '4ª justa', en: 'Perfect 4th'),
  6: LocalizedText(es: 'Tritono', en: 'Tritone'),
  7: LocalizedText(es: '5ª justa', en: 'Perfect 5th'),
  8: LocalizedText(es: '6ª menor', en: 'Minor 6th'),
  9: LocalizedText(es: '6ª mayor', en: 'Major 6th'),
  10: LocalizedText(es: '7ª menor', en: 'Minor 7th'),
  11: LocalizedText(es: '7ª mayor', en: 'Major 7th'),
  12: LocalizedText(es: 'Octava', en: 'Octave'),
  13: LocalizedText(es: '9ª menor', en: 'Minor 9th'),
  14: LocalizedText(es: '9ª mayor', en: 'Major 9th'),
  15: LocalizedText(es: '9ª aumentada', en: 'Augmented 9th'),
  17: LocalizedText(es: '11ª justa', en: 'Perfect 11th'),
  18: LocalizedText(es: '11ª aumentada', en: 'Augmented 11th'),
  21: LocalizedText(es: '13ª mayor', en: 'Major 13th'),
};

/// Cómo suena cada intervalo simple (entrenamiento de oído).
const _sounds = <int, LocalizedText>{
  0: LocalizedText(es: 'La misma nota: quietud total', en: 'Same pitch — complete stillness'),
  1: LocalizedText(es: 'Tenso y disonante: el roce de medio tono', en: 'Tense, dissonant, half-step clash'),
  2: LocalizedText(es: 'Un paso brillante, algo abierto', en: 'Bright step, slightly open'),
  3: LocalizedText(es: 'Melancólico, sabor menor', en: 'Melancholy, minor feel'),
  4: LocalizedText(es: 'Brillante, alegre, abierto', en: 'Bright, happy, open'),
  5: LocalizedText(es: 'Firme, algo suspendido', en: 'Strong, somewhat suspended'),
  6: LocalizedText(es: 'Inestable, disonante, inquieto', en: 'Unstable, dissonant, restless'),
  7: LocalizedText(es: 'Potente, estable, abierto', en: 'Powerful, stable, open'),
  8: LocalizedText(es: 'Agridulce, algo oscuro', en: 'Bittersweet, slightly dark'),
  9: LocalizedText(es: 'Cálido, nostálgico, dulce', en: 'Warm, nostalgic, sweet'),
  10: LocalizedText(es: 'Bluesero, jazzístico, sin resolver', en: 'Bluesy, jazzy, unresolved'),
  11: LocalizedText(es: 'Soñador, algo tenso, romántico', en: 'Dreamy, slightly tense, romantic'),
  12: LocalizedText(es: 'Resolución total: la misma nota más aguda', en: 'Complete resolution, same pitch class'),
};

String intervalLongName(int semitones, {String? fallback}) =>
    _names[semitones]?.text ?? fallback ?? '$semitones';

String intervalSound(int semitones, {String? fallback}) =>
    _sounds[semitones]?.text ?? fallback ?? '';
