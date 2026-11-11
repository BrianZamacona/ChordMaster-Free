/// «¿Qué tocar encima?» de una progresión, por regla: las escalas de su tónica
/// que contienen todas las notas de sus acordes, las pentatónicas que caben en
/// ellas y, en el blues (donde ninguna escala de 7 notas contiene el I7, el
/// IV7 y el V7), las tres de siempre, con lo que aporta cada una.
library;

import '../progressions/progression_data.dart';
import 'harmony.dart';
import 'intervals.dart';

/// Las escalas para improvisar sobre una progresión (ids de
/// scales_master.json; todas sobre la tónica de la progresión).
class PlayOverScales {
  const PlayOverScales({required this.fit, required this.pentatonic, required this.blues});

  /// Contienen todas las notas de todos los acordes.
  final List<String> fit;

  /// Pentatónicas (5 notas) que caben enteras en la primera de [fit].
  final List<String> pentatonic;

  /// En el blues: la pentatónica menor, la de blues y la mayor de la tónica.
  final List<String> blues;
}

/// Las tres del blues, en este orden; ver [bluesScaleRoles].
const bluesScaleIds = ['pentatonic_minor', 'blues_minor', 'pentatonic_major'];

/// Semitonos desde la tónica de todas las notas de los acordes de [p].
Set<int> progressionTones(Progression p) => {for (final d in p.degrees) ...degreeChordTones(d)};

/// Las escalas de [candidates] (id → intervalos) para tocar sobre [p]. Las que
/// tienen las mismas notas (mayor y jónica) salen una vez: la primera.
PlayOverScales playOverScales(Progression p, Map<String, List<int>> candidates) {
  final tones = progressionTones(p);
  final seen = <String>{};
  final fit = [
    for (final e in candidates.entries)
      if (tones.every(e.value.contains) && seen.add((e.value.toSet().toList()..sort()).join(','))) e.key,
  ];
  final home = fit.isEmpty ? null : candidates[fit.first]!.toSet();
  final pentatonic = [
    if (home != null)
      for (final e in candidates.entries)
        if (e.value.toSet().length == 5 && home.containsAll(e.value)) e.key,
  ];
  final blues = [
    if (p.kind == ProgressionKind.blues)
      for (final id in bluesScaleIds)
        if (candidates.containsKey(id)) id,
  ];
  return PlayOverScales(fit: fit, pentatonic: pentatonic, blues: blues);
}

/// Qué aporta cada escala del blues sobre el I7 (lo verifica un test con sus
/// intervalos): la menor y la de blues tienen su raíz, su 5ª y su b7, y su b3
/// roza la 3ª del acorde (la nota «blue»); la de blues suma la b5. La mayor
/// tiene su raíz, su 3ª y su 5ª: suena más dulce.
({String es, String en}) bluesScaleRole(String id) => switch (id) {
  'pentatonic_minor' => (
    es: 'tiene la raíz, la 5ª y la b7 del I7; su b3 roza la 3ª del acorde: el sonido del blues',
    en: 'it has the root, 5th and b7 of the I7; its b3 rubs against the chord\'s 3rd: the blues sound',
  ),
  'blues_minor' => (
    es: 'la pentatónica menor con la b5 de paso',
    en: 'the minor pentatonic with the passing b5',
  ),
  'pentatonic_major' => (
    es: 'tiene la raíz, la 3ª y la 5ª del I7: más dulce, sin choque',
    en: 'it has the root, 3rd and 5th of the I7: sweeter, with no clash',
  ),
  _ => throw ArgumentError.value(id, 'id'),
};

/// Las notas del arpegio del grado [d], desde su raíz: semitonos y nombre del
/// intervalo (1 = la raíz).
List<({int semitones, String label})> degreeArpeggio(ProgressionDegree d) => [
  for (final i in degreeChordIntervals(d.type)) (semitones: (d.semitones + i) % 12, label: spellInterval(i)),
];
