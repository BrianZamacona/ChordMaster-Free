import '../i18n/tr.dart';

/// Nombres de escalas y modos en español e inglés, por id de
/// `scales_master.json` (el JSON solo trae el nombre en inglés).
const _names = <String, LocalizedText>{
  'major': LocalizedText(es: 'Mayor', en: 'Major'),
  'natural_minor': LocalizedText(es: 'Menor natural', en: 'Natural Minor'),
  'pentatonic_minor': LocalizedText(es: 'Pentatónica menor', en: 'Minor Pentatonic'),
  'pentatonic_major': LocalizedText(es: 'Pentatónica mayor', en: 'Major Pentatonic'),
  'blues_minor': LocalizedText(es: 'Blues menor', en: 'Minor Blues'),
  'harmonic_minor': LocalizedText(es: 'Menor armónica', en: 'Harmonic Minor'),
  'melodic_minor': LocalizedText(es: 'Menor melódica', en: 'Melodic Minor'),
  'whole_tone': LocalizedText(es: 'Tonos enteros', en: 'Whole Tone'),
  'hungarian_minor': LocalizedText(es: 'Húngara menor', en: 'Hungarian Minor'),
  'phrygian_dominant': LocalizedText(es: 'Frigia dominante', en: 'Phrygian Dominant'),
  'ionian': LocalizedText(es: 'Jónica', en: 'Ionian'),
  'dorian': LocalizedText(es: 'Dórica', en: 'Dorian'),
  'phrygian': LocalizedText(es: 'Frigia', en: 'Phrygian'),
  'lydian': LocalizedText(es: 'Lidia', en: 'Lydian'),
  'mixolydian': LocalizedText(es: 'Mixolidia', en: 'Mixolydian'),
  'aeolian': LocalizedText(es: 'Eólica', en: 'Aeolian'),
  'locrian': LocalizedText(es: 'Locria', en: 'Locrian'),
};

/// Nombre visible de una escala.
///
/// Las disminuidas se nombran por sus intervalos (empieza por semitono =
/// semitono-tono), no por el id, para que el nombre nunca dependa de él.
String scaleDisplayName(String id, List<int> intervals, {String? fallback}) {
  if (intervals.length == 8) {
    return intervals[1] == 1
        ? tr(es: 'Disminuida semitono-tono', en: 'Half-Whole Diminished')
        : tr(es: 'Disminuida tono-semitono', en: 'Whole-Half Diminished');
  }
  return _names[id]?.text ?? fallback ?? id;
}

/// Categoría de `scales_master.json` (en español) en el idioma actual.
String scaleCategoryName(String category) => switch (category) {
  'Diatónica' => tr(es: 'Diatónicas', en: 'Diatonic'),
  'Pentatónica' => tr(es: 'Pentatónicas', en: 'Pentatonic'),
  'Simétrica' => tr(es: 'Simétricas', en: 'Symmetric'),
  'Exótica' => tr(es: 'Exóticas', en: 'Exotic'),
  _ => category,
};

/// Nombre de posición del JSON ("Forma C", "Posición 4") en el idioma actual.
String positionDisplayName(String name) => CurrentLanguage.value == AppLanguage.en
    ? name.replaceFirst('Forma ', 'Shape ').replaceFirst('Posición ', 'Position ')
    : name;
