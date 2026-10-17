import 'ergonomics.dart';
import 'voicing_adapter.dart';

export 'ergonomics.dart' show BarreKind, barreKind, barreWidth;

/// Cejilla inferida de [frets] + [engineFingers] (orden del motor, 0 = 1ª cuerda).
///
/// `fromString` es la cuerda más grave (índice mayor) y `endString` la más
/// aguda; `_barreDifficulty` usa `abs`, así que solo importa ser consistente.
/// Con varios dedos candidatos gana el de mayor ancho; en empate, el de traste menor.
Barre? detectBarre(EngineFrets frets, List<int> engineFingers) {
  final groups = <(int, int), List<int>>{};
  for (var s = 0; s < frets.length && s < engineFingers.length; s++) {
    final fret = frets[s];
    final finger = engineFingers[s];
    if (fret == null || fret <= 0 || finger <= 0) continue;
    groups.putIfAbsent((finger, fret), () => []).add(s);
  }

  Barre? best;
  for (final entry in groups.entries) {
    final strings = entry.value;
    if (strings.length < 2) continue;
    final candidate = Barre(
      fret: entry.key.$2,
      fromString: strings.reduce((a, b) => a > b ? a : b),
      endString: strings.reduce((a, b) => a < b ? a : b),
    );
    if (best == null ||
        barreWidth(candidate) > barreWidth(best) ||
        (barreWidth(candidate) == barreWidth(best) && candidate.fret < best.fret)) {
      best = candidate;
    }
  }
  return best;
}
