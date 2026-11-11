/// El arpegio de la tónica dentro de una forma de escala (decisión del usuario
/// tras revisar las apps CAGED): qué notas de la forma son las del acorde de
/// la tónica, por regla.
library;

import 'notes.dart';

/// Semitonos desde la tónica de la tríada de la tónica de [scale]: en las de
/// 7 notas, sus grados 1, 3 y 5 (en la locria, la b5); en las demás, la 3ª que
/// tenga (mayor primero) y la 5ª justa, o si no la b5 con 3ª menor o la #5 con
/// 3ª mayor. `null` si la escala no tiene 3ª o le falta la 5ª que le toca.
List<int>? tonicTriad(List<int> scale) {
  final s = {for (final i in scale) i % 12}.toList()..sort();
  if (s.length == 7) return [s[0], s[2], s[4]];
  final third = s.contains(4) ? 4 : (s.contains(3) ? 3 : null);
  if (third == null) return null;
  final fifth = s.contains(7)
      ? 7
      : third == 3 && s.contains(6)
      ? 6
      : third == 4 && s.contains(8)
      ? 8
      : null;
  return fifth == null ? null : [0, third, fifth];
}

/// Tipo de chords.json de la tríada [triad] (`major`, `minor`, `diminished`,
/// `augmented`).
String triadType(List<int> triad) => switch ((triad[1], triad[2])) {
  (4, 7) => 'major',
  (3, 7) => 'minor',
  (3, 6) => 'diminished',
  (4, 8) => 'augmented',
  _ => throw ArgumentError.value(triad, 'triad'),
};

/// La nota de la cuerda [string] (1 = mi aguda) en el traste [fret] es del
/// arpegio [triad] sobre la tónica [root] (semitono, C = 0).
bool isTriadNote(int string, int fret, int root, List<int> triad) =>
    triad.contains((standardOpenStringMidi[string - 1] + fret - root) % 12);
