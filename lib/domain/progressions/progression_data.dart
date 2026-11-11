import '../../core/i18n/tr.dart';

const _majorDegrees = {
  'I': (semitones: 0, type: 'major'),
  'ii': (semitones: 2, type: 'minor'),
  'iii': (semitones: 4, type: 'minor'),
  'IV': (semitones: 5, type: 'major'),
  'V': (semitones: 7, type: 'major'),
  'vi': (semitones: 9, type: 'minor'),
  'vii°': (semitones: 11, type: 'diminished'),
};

/// Los demás grados que usan los blues, las progresiones en menor y los vamps
/// modales. Se cuentan desde la tónica de la progresión, con ♭ cuando el grado
/// está medio tono abajo del de la escala mayor (♭VII = un tono debajo de la
/// tónica), como en el círculo.
const _otherDegrees = {
  'I7': (semitones: 0, type: 'dominant7'),
  'IV7': (semitones: 5, type: 'dominant7'),
  'V7': (semitones: 7, type: 'dominant7'),
  'i': (semitones: 0, type: 'minor'),
  'i7': (semitones: 0, type: 'minor7'),
  'i°': (semitones: 0, type: 'diminished'),
  '♭II': (semitones: 1, type: 'major'),
  'II': (semitones: 2, type: 'major'),
  '♭III': (semitones: 3, type: 'major'),
  'iv': (semitones: 5, type: 'minor'),
  'iv7': (semitones: 5, type: 'minor7'),
  'v': (semitones: 7, type: 'minor'),
  '♭VI': (semitones: 8, type: 'major'),
  '♭VII': (semitones: 10, type: 'major'),
};

/// Grados de la tonalidad mayor en orden (I … vii°).
final majorDegreeNumerals = List<String>.unmodifiable(_majorDegrees.keys);

/// Todos los grados que puede tener una progresión, en este orden.
final allDegreeNumerals = List<String>.unmodifiable([
  ..._majorDegrees.keys,
  ..._otherDegrees.keys,
]);

({int semitones, String type}) _degree(String numeral) =>
    _majorDegrees[numeral] ?? _otherDegrees[numeral]!;

class ProgressionDegree {
  const ProgressionDegree(this.numeral, this.semitones, this.type);

  final String numeral;

  /// Semitonos desde la tónica.
  final int semitones;

  /// Valor `type` de chords.json (`major`, `minor`, `dominant7`…).
  final String type;
}

/// De qué familia es una progresión: la lista se agrupa así y la teoría
/// «¿Por qué?» explica cada una a su manera.
enum ProgressionKind { major, blues, minor, modal }

/// Cómo se reparte el pulso al escucharla: un golpe por pulso, o tres
/// (12/8: el blues lento).
enum ProgressionFeel { straight, triplet }

class Progression {
  Progression(
    this.id,
    this.label,
    List<String> numerals, {
    this.kind = ProgressionKind.major,
    this.feel = ProgressionFeel.straight,
    this.name,
    this.mode,
  }) : degrees = [
         for (final n in numerals)
           ProgressionDegree(n, _degree(n).semitones, _degree(n).type),
       ];

  /// Permanente: lo guarda el contador del logro "composer".
  final String id;
  final String label;
  final List<ProgressionDegree> degrees;
  final ProgressionKind kind;
  final ProgressionFeel feel;

  /// Nombre de las que no se nombran por sus grados (el blues de 12 compases).
  final LocalizedText? name;

  /// En un vamp modal, el modo como rotación de la escala mayor (1 = dórico,
  /// 2 = frigio … 6 = locrio); el test lo compara con scales_master.json.
  final int? mode;
}

/// Id en scales_master.json de cada rotación de la mayor ([Progression.mode]).
const modeScaleIds = [
  'ionian',
  'dorian',
  'phrygian',
  'lydian',
  'mixolydian',
  'aeolian',
  'locrian',
];

const _blues = [
  'I7',
  'I7',
  'I7',
  'I7',
  'IV7',
  'IV7',
  'I7',
  'I7',
  'V7',
  'IV7',
  'I7',
  'V7',
];
const _quickChange = [
  'I7',
  'IV7',
  'I7',
  'I7',
  'IV7',
  'IV7',
  'I7',
  'I7',
  'V7',
  'IV7',
  'I7',
  'V7',
];
const _minorBlues = [
  'i7',
  'i7',
  'i7',
  'i7',
  'iv7',
  'iv7',
  'i7',
  'i7',
  '♭VI',
  'V7',
  'i7',
  'V7',
];

final progressions = [
  Progression('v1-1', 'I - vi - IV - V', ['I', 'vi', 'IV', 'V']),
  Progression('v1-2', 'I - V - vi - IV', ['I', 'V', 'vi', 'IV']),
  Progression('v1-3', 'I - IV - V', ['I', 'IV', 'V']),
  Progression('v2-1', 'I - vi - ii - V', ['I', 'vi', 'ii', 'V']),
  Progression('v2-2', 'I - IV - vi - V', ['I', 'IV', 'vi', 'V']),
  Progression('v2-3', 'I - IV - I - V', ['I', 'IV', 'I', 'V']),
  Progression('v3-1', 'I - V - vi - iii', ['I', 'V', 'vi', 'iii']),
  Progression('v3-2', 'I - IV - ii - V', ['I', 'IV', 'ii', 'V']),
  Progression('v3-3', 'I - iii - IV - V', ['I', 'iii', 'IV', 'V']),
  // Blues de 12 compases: un grado por compás.
  Progression(
    'blues-12',
    _blues.join(' - '),
    _blues,
    kind: ProgressionKind.blues,
    name: const LocalizedText(es: 'Blues de 12 compases', en: '12-bar blues'),
  ),
  Progression(
    'blues-12-quick',
    _quickChange.join(' - '),
    _quickChange,
    kind: ProgressionKind.blues,
    name: const LocalizedText(
      es: 'Blues con cambio rápido',
      en: 'Quick-change blues',
    ),
  ),
  Progression(
    'blues-12-slow',
    _blues.join(' - '),
    _blues,
    kind: ProgressionKind.blues,
    feel: ProgressionFeel.triplet,
    name: const LocalizedText(
      es: 'Blues lento en 12/8',
      en: 'Slow blues in 12/8',
    ),
  ),
  Progression(
    'blues-12-minor',
    _minorBlues.join(' - '),
    _minorBlues,
    kind: ProgressionKind.blues,
    name: const LocalizedText(es: 'Blues menor', en: 'Minor blues'),
  ),
  // En menor.
  Progression('m1', 'i - ♭VII - ♭VI - ♭VII', [
    'i',
    '♭VII',
    '♭VI',
    '♭VII',
  ], kind: ProgressionKind.minor),
  Progression('m2', 'i - ♭VI - ♭III - ♭VII', [
    'i',
    '♭VI',
    '♭III',
    '♭VII',
  ], kind: ProgressionKind.minor),
  Progression('m3', 'i - iv - V7', [
    'i',
    'iv',
    'V7',
  ], kind: ProgressionKind.minor),
  Progression('m4', 'i - iv - v - i', [
    'i',
    'iv',
    'v',
    'i',
  ], kind: ProgressionKind.minor),
  // Vamps modales: dos acordes que hacen oír la nota característica del modo.
  Progression(
    'mode-dorian',
    'i - IV',
    ['i', 'IV'],
    kind: ProgressionKind.modal,
    mode: 1,
    name: const LocalizedText(es: 'Dórico (i–IV)', en: 'Dorian (i–IV)'),
  ),
  Progression(
    'mode-phrygian',
    'i - ♭II',
    ['i', '♭II'],
    kind: ProgressionKind.modal,
    mode: 2,
    name: const LocalizedText(es: 'Frigio (i–♭II)', en: 'Phrygian (i–♭II)'),
  ),
  Progression(
    'mode-lydian',
    'I - II',
    ['I', 'II'],
    kind: ProgressionKind.modal,
    mode: 3,
    name: const LocalizedText(es: 'Lidio (I–II)', en: 'Lydian (I–II)'),
  ),
  Progression(
    'mode-mixolydian',
    'I - ♭VII',
    ['I', '♭VII'],
    kind: ProgressionKind.modal,
    mode: 4,
    name: const LocalizedText(
      es: 'Mixolidio (I–♭VII)',
      en: 'Mixolydian (I–♭VII)',
    ),
  ),
  Progression(
    'mode-locrian',
    'i° - ♭II',
    ['i°', '♭II'],
    kind: ProgressionKind.modal,
    mode: 6,
    name: const LocalizedText(es: 'Locrio (i°–♭II)', en: 'Locrian (i°–♭II)'),
  ),
];

/// Las de la tonalidad mayor, con tríadas (las que gira el capo).
List<Progression> get majorProgressions => [
  for (final p in progressions)
    if (p.kind == ProgressionKind.major) p,
];
