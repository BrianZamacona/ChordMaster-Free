/// Los acordes que ofrece "Mi progresión": los de cada grado de una escala de
/// base (la mayor o uno de sus modos), en tríada o con su 7ª, por regla
/// (`diatonicTriads`). Se guardan como número romano (`ii7`, `♭VIImaj7`), que
/// `parseDegreeNumeral` vuelve a leer: los de antes (`I`, `vi`) siguen valiendo.
library;

import '../../core/i18n/tr.dart';
import '../theory/harmony.dart';
import '../theory/scale_insights.dart';
import 'progression_data.dart';
import 'progression_playback.dart';

/// Escalas de base de "Mi progresión": las rotaciones de la mayor, en el
/// orden de [modeScaleIds] (0 = mayor, 5 = menor natural).
const customBaseModes = [0, 1, 2, 3, 4, 5, 6];

/// Máximo de acordes en "Mi progresión".
const customProgressionMax = 8;

/// La escala de base por defecto: la mayor.
const customDefaultMode = 0;

/// Acordes de cada grado de la escala de base [mode] (rotación de la mayor),
/// del I al VII: tríadas o, con [sevenths], cuatríadas (1-3-5-7 con notas de la
/// escala).
List<ProgressionDegree> customChordChoices(int mode, {bool sevenths = false}) => [
  for (final c in diatonicTriads(modeIntervals(mode)))
    () {
      final numeral = _withSeventh(_glyphs(c.numeral), sevenths ? c.seventhType : null);
      final parsed = parseDegreeNumeral(numeral)!;
      return ProgressionDegree(numeral, parsed.semitones, parsed.type);
    }(),
];

/// Si [numeral] se puede poner en "Mi progresión" (un grado bien escrito).
bool isCustomNumeral(String numeral) => parseDegreeNumeral(numeral) != null;

/// Cómo se guarda un acorde de "Mi progresión": su número romano y, si no
/// dura un compás, `@` y sus pulsos (`ii7@2`). Lo guardado antes, sin `@`,
/// dura un compás.
String customToken(String numeral, int beats) =>
    beats == progressionBeatsPerChord ? numeral : '$numeral@$beats';

/// Lee [customToken]; `null` si el grado o la duración no valen.
({String numeral, int beats})? parseCustomToken(String token) {
  final parts = token.split('@');
  if (parts.length > 2 || !isCustomNumeral(parts.first)) return null;
  final beats = parts.length == 1 ? progressionBeatsPerChord : int.tryParse(parts[1]);
  if (beats == null || !customChordBeats.contains(beats)) return null;
  return (numeral: parts.first, beats: beats);
}

/// `b`/`#` de `spellInterval` con los signos de las progresiones (♭, ♯).
String _glyphs(String numeral) => numeral.replaceAll('b', '♭').replaceAll('#', '♯');

String _withSeventh(String triad, String? seventhType) => switch (seventhType) {
  null => triad,
  'major7' => '${triad}maj7',
  'dominant7' || 'minor7' => '${triad}7',
  'halfDiminished' => triad.replaceFirst('°', 'ø7'),
  'diminished7' => triad.replaceFirst('°', '°7'),
  _ => throw StateError('$triad: sin 7ª en los datos ($seventhType)'),
};

/// De dónde sale un acorde de "Mi progresión" (decisión del usuario tras
/// revisar Pocket Composer): de la escala de base o de una fuente fuera de
/// ella, cada una por regla y con su explicación.
enum ChordSource {
  /// Los grados de la escala de base.
  scale,

  /// Intercambio modal: los mismos grados de las escalas paralelas (misma
  /// tónica, otro modo) que no están en la de base.
  borrowed,

  /// V7 de cada grado: un acorde de 7ª dominante una 5ª justa arriba.
  secondaryDominant,

  /// vii°7 de cada grado: un disminuido con 7ª medio tono abajo.
  leadingTone,

  /// Sustituto tritonal del V7 de cada grado: un 7 medio tono arriba.
  tritoneSub,

  /// Armonía negativa: cada grado reflejado sobre el eje entre la 3ª menor
  /// y la mayor de la tónica (la nota p pasa a 7 − p).
  negative,
}

/// Un acorde que ofrece una fuente: el grado (con el número romano que se
/// guarda), cómo se nombra en su fuente (`V7/ii`) y por qué está.
class SourcedChord {
  const SourcedChord({required this.degree, required this.label, required this.why});

  final ProgressionDegree degree;
  final String label;
  final LocalizedText why;
}

/// Los acordes de [source] sobre la escala de base [mode]. La dominante, la
/// sensible y el sustituto tritonal van siempre con su 7ª (así se usan); el
/// resto sigue a [sevenths]. Ninguno repite un acorde de la escala de base ni
/// otro de la misma fuente.
List<SourcedChord> chordsFrom(ChordSource source, int mode, {bool sevenths = false}) {
  final base = customChordChoices(mode, sevenths: sevenths);
  if (source == ChordSource.scale) {
    return [for (final d in base) SourcedChord(degree: d, label: d.numeral, why: _scaleWhy(mode))];
  }
  final inBase = {
    for (final s in [false, true])
      for (final d in customChordChoices(mode, sevenths: s)) (d.semitones, d.type),
  };
  final seen = <(int, String)>{};
  final out = <SourcedChord>[];
  void add(int semitones, String type, String label, LocalizedText why, {bool sharp = false, String? spelled}) {
    final s = semitones % 12;
    if (inBase.contains((s, type))) return;
    final numeral = spelled ?? spellDegree(s, type, sharp: sharp);
    if (!seen.add((s, type))) return;
    out.add(SourcedChord(degree: ProgressionDegree(numeral, s, type), label: label, why: why));
  }

  // Los grados a los que se llega: los de la escala que no son disminuidos
  // (un V7 de un disminuido no resuelve en él).
  final targets = [
    for (final d in customChordChoices(mode))
      if (d.type == 'major' || d.type == 'minor') d,
  ];
  switch (source) {
    case ChordSource.scale:
      break;
    case ChordSource.borrowed:
      for (final other in _brightness) {
        if (other == mode) continue;
        // Con el nombre que tiene en su escala (la ♯4 de la lidia, no ♭5).
        for (final d in customChordChoices(other, sevenths: sevenths)) {
          add(
            d.semitones,
            d.type,
            d.numeral,
            LocalizedText(
              es: 'prestado de ${_modeNames[other].es}: la misma tónica, otra escala',
              en: 'borrowed from ${_modeNames[other].en}: same tonic, another scale',
            ),
            spelled: d.numeral,
          );
        }
      }
    case ChordSource.secondaryDominant:
      for (final t in targets) {
        add(
          t.semitones + 7,
          'dominant7',
          'V7/${t.numeral}',
          LocalizedText(
            es: 'la dominante de ${t.numeral}: su 3ª sube medio tono a la raíz de ${t.numeral}',
            en: 'the dominant of ${t.numeral}: its 3rd rises a half step to the root of ${t.numeral}',
          ),
        );
      }
    case ChordSource.leadingTone:
      for (final t in targets) {
        add(
          t.semitones - 1,
          'diminished7',
          'vii°7/${t.numeral}',
          LocalizedText(
            es: 'el disminuido de la sensible de ${t.numeral}: su raíz sube medio tono a la de ${t.numeral}',
            en: 'the leading-tone diminished of ${t.numeral}: its root rises a half step to that of ${t.numeral}',
          ),
          sharp: true,
        );
      }
    case ChordSource.tritoneSub:
      for (final t in targets) {
        add(
          t.semitones + 1,
          'dominant7',
          'subV7/${t.numeral}',
          LocalizedText(
            es: 'el sustituto tritonal del V7 de ${t.numeral}: comparte su 3ª y su 7ª, y su raíz baja medio tono a la de ${t.numeral}',
            en: 'the tritone sub of the V7 of ${t.numeral}: it shares its 3rd and 7th, and its root falls a half step to that of ${t.numeral}',
          ),
        );
      }
    case ChordSource.negative:
      for (final d in base) {
        final mirror = negativeOf(d);
        add(
          mirror.semitones,
          mirror.type,
          '${spellDegree(mirror.semitones, mirror.type)} ⇄ ${d.numeral}',
          LocalizedText(
            es: 'el reflejo negativo de ${d.numeral}: cada nota se refleja sobre el eje entre la 3ª menor y la mayor de la tónica',
            en: "the negative mirror of ${d.numeral}: each note is reflected across the axis between the tonic's minor and major 3rd",
          ),
        );
      }
  }
  return out;
}

/// Las fuentes que explican [degree] sobre la escala de base [mode] (con o
/// sin 7ª); vacío si es de la escala. Primero las de dominante: el V7 de la
/// menor se explica mejor como V7/i que como prestado de la mayor, y el I7 de
/// la mayor como V7/IV. Después los prestados (el ♭VII7 de la mayor viene de
/// la menor, no es «el sustituto del V7 de vi»).
List<SourcedChord> sourcesOf(ProgressionDegree degree, int mode) => [
  for (final source in _explainOrder)
    for (final sevenths in [false, true])
      for (final c in chordsFrom(source, mode, sevenths: sevenths))
        if (c.degree.numeral == degree.numeral) c,
];

/// El reflejo negativo de [d]: cada nota p pasa a 7 − p (desde la tónica) y
/// el acorde que forman se nombra por su raíz.
({int semitones, String type}) negativeOf(ProgressionDegree d) {
  final tones = {for (final t in degreeChordTones(d)) (7 - t) % 12};
  for (final type in _negativeTypes) {
    final intervals = degreeChordIntervals(type);
    if (intervals.length != tones.length) continue;
    for (var root = 0; root < 12; root++) {
      if (intervals.every((i) => tones.contains((root + i) % 12))) return (semitones: root, type: type);
    }
  }
  throw StateError('${d.numeral}: su reflejo no es un acorde conocido');
}

const _negativeTypes = [
  'major',
  'minor',
  'diminished',
  'augmented',
  'major7',
  'dominant7',
  'minor7',
  'halfDiminished',
  'diminished7',
];

/// El número romano de un acorde de [type] a [semitones] de la tónica: el
/// grado de la mayor si cae en ella; si no, con ♭ (o ♯ con [sharp], como la
/// sensible de un grado). Mayúscula si su 3ª es mayor; el sufijo dice el tipo.
String spellDegree(int semitones, String type, {bool sharp = false}) {
  final s = semitones % 12;
  final natural = _majorSteps.indexOf(s);
  final (index, accidental) = natural >= 0
      ? (natural, '')
      : sharp
      ? (_majorSteps.indexOf(s - 1), '♯')
      : (_majorSteps.indexOf((s + 1) % 12), '♭');
  const romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
  final upper = const {'major', 'augmented', 'dominant7', 'major7'}.contains(type);
  final roman = upper ? romans[index] : romans[index].toLowerCase();
  final suffix = switch (type) {
    'major' || 'minor' => '',
    'diminished' => '°',
    'augmented' => '+',
    'dominant7' || 'minor7' => '7',
    'major7' => 'maj7',
    'halfDiminished' => 'ø7',
    'diminished7' => '°7',
    _ => throw ArgumentError.value(type, 'type'),
  };
  return '$accidental$roman$suffix';
}

const _majorSteps = [0, 2, 4, 5, 7, 9, 11];

const _explainOrder = [
  ChordSource.secondaryDominant,
  ChordSource.leadingTone,
  ChordSource.borrowed,
  ChordSource.tritoneSub,
  ChordSource.negative,
];

/// Los modos de la más brillante a la más oscura (lidia … locria): un
/// préstamo se atribuye a la primera paralela que tiene el acorde.
const _brightness = [3, 0, 4, 1, 5, 2, 6];

const _modeNames = [
  LocalizedText(es: 'la mayor', en: 'the major scale'),
  LocalizedText(es: 'la dórica', en: 'Dorian'),
  LocalizedText(es: 'la frigia', en: 'Phrygian'),
  LocalizedText(es: 'la lidia', en: 'Lydian'),
  LocalizedText(es: 'la mixolidia', en: 'Mixolydian'),
  LocalizedText(es: 'la menor natural', en: 'the natural minor'),
  LocalizedText(es: 'la locria', en: 'Locrian'),
];

LocalizedText _scaleWhy(int mode) => LocalizedText(
  es: 'de ${_modeNames[mode].es}, la escala de base',
  en: 'from ${_modeNames[mode].en}, the base scale',
);
