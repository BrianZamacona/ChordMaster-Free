/// "¿Qué capo uso?": para una tonalidad, el traste del capo y la forma abierta
/// que la dan. Todo sale de la regla "el capo sube cada cuerda un semitono por
/// traste", sin tablas.
library;

import 'notes.dart';

/// Las cinco formas abiertas mayores, en el orden CAGED.
const majorShapes = ['C', 'A', 'G', 'E', 'D'];

/// Las formas abiertas menores más usadas.
const minorShapes = ['Am', 'Em', 'Dm'];

/// Hasta aquí el capo resulta cómodo: más arriba los trastes quedan muy juntos.
const comfortableCapoFret = 7;

/// Tónica (clase de altura) del nombre de acorde [chord]: "F#m" → F#.
int chordRoot(String chord) {
  final sharp = chord.length > 1 && chord[1] == '#';
  return noteIndex(chord.substring(0, sharp ? 2 : 1));
}

/// Lo que sigue a la tónica en el nombre: "m", "7", "" …
String chordSuffix(String chord) {
  final sharp = chord.length > 1 && chord[1] == '#';
  return chord.substring(sharp ? 2 : 1);
}

/// Cómo suena la forma [shape] con el capo en el traste [fret].
String soundingChord(String shape, int fret) =>
    '${pitchClassName(chordRoot(shape) + fret)}${chordSuffix(shape)}';

/// Una forma abierta con el capo en un traste.
class CapoOption {
  const CapoOption({required this.fret, required this.shape});

  /// 0 = sin capo.
  final int fret;

  /// Acorde que se arma (forma abierta).
  final String shape;

  @override
  bool operator ==(Object other) =>
      other is CapoOption && other.fret == fret && other.shape == shape;

  @override
  int get hashCode => Object.hash(fret, shape);

  @override
  String toString() => '$shape@$fret';
}

/// Formas abiertas que suenan en la tonalidad [key] (C = 0), con el capo
/// hasta [maxFret], de la más grave a la más aguda.
List<CapoOption> capoOptions(
  int key, {
  bool minor = false,
  int maxFret = comfortableCapoFret,
}) {
  final options = [
    for (final shape in minor ? minorShapes : majorShapes)
      CapoOption(fret: (key - chordRoot(shape)) % 12, shape: shape),
  ]..removeWhere((o) => o.fret > maxFret);
  options.sort((a, b) => a.fret.compareTo(b.fret));
  return options;
}

/// Grados de la progresión de ejemplo: I – IV – V (o i – iv – v en menor),
/// en semitonos desde la tónica.
const _primaryDegrees = [0, 5, 7];

/// I – IV – V de la forma [shape]: lo que se arma con la mano y cómo suena con
/// el capo en [fret].
List<({String shape, String sounds})> capoProgression(String shape, int fret) {
  final suffix = chordSuffix(shape);
  return [
    for (final degree in _primaryDegrees)
      (
        shape: '${pitchClassName(chordRoot(shape) + degree)}$suffix',
        sounds: '${pitchClassName(chordRoot(shape) + degree + fret)}$suffix',
      ),
  ];
}

/// Sufijo del nombre de acorde para un `type` de chords.json.
String chordTypeSuffix(String type) => switch (type) {
  'minor' => 'm',
  'diminished' => 'dim',
  _ => '',
};

/// Acordes de una progresión en la tonalidad [key]: cada grado es su distancia
/// en semitonos a la tónica y su tipo (`major`, `minor`, `diminished`).
List<String> chordsInKey(List<({int semitones, String type})> degrees, int key) => [
  for (final d in degrees)
    '${pitchClassName(key + d.semitones)}${chordTypeSuffix(d.type)}',
];

/// Una progresión girada a [key] con el capo: lo que arma la mano con la
/// forma abierta de [option] y cómo suena.
({List<String> shapes, List<String> sounds}) capoTransposition(
  List<({int semitones, String type})> degrees,
  CapoOption option,
) {
  final shapes = chordsInKey(degrees, chordRoot(option.shape));
  return (
    shapes: shapes,
    sounds: [for (final c in shapes) soundingChord(c, option.fret)],
  );
}
