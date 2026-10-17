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

/// Cejilla para dibujar: traste y extremos en índices de chords.json
/// (0 = 6ª cuerda), con `lowString < highString`.
typedef JsonBarre = ({int fret, int lowString, int highString});

/// [detectBarre] a partir de `fretPositions`/`fingerPositions` de chords.json.
///
/// Solo devuelve cejillas tocables: si alguna cuerda bajo la barra está
/// muteada o pisada más abajo que la cejilla (deuda conocida de datos, ver
/// `barre_detection_test`), devuelve `null` para no dibujar algo falso.
JsonBarre? barreFromChordJson(List<int> jsonFrets, List<int> jsonFingers) {
  final frets = VoicingAdapter.fromChordJson(jsonFrets);
  final barre = detectBarre(
    frets,
    VoicingAdapter.fingersFromChordJson(jsonFingers),
  );
  if (barre == null) return null;
  for (var s = barre.endString; s <= barre.fromString; s++) {
    final fret = frets[s];
    if (fret == null || fret < barre.fret) return null;
  }
  final a = VoicingAdapter.stringIndexToChordJson(barre.fromString);
  final b = VoicingAdapter.stringIndexToChordJson(barre.endString);
  return (
    fret: barre.fret,
    lowString: a < b ? a : b,
    highString: a < b ? b : a,
  );
}
