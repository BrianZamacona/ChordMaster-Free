import 'ergonomics.dart';
import 'voicing_adapter.dart';

/// Digitación de un acorde con otra nota en el bajo (C/E, D/F#, Am/G...), en
/// orden del motor (índice 0 = 1ª cuerda).
class SlashVoicing {
  const SlashVoicing({
    required this.frets,
    required this.fingers,
    required this.cost,
  });

  final EngineFrets frets;

  /// Dedo por cuerda (0 = al aire o muteada), mismo orden que [frets].
  final List<int> fingers;

  /// Costo ergonómico (menor = más cómoda).
  final double cost;
}

/// Cuerdas donde se prueba el bajo: 6ª, 5ª y 4ª (índices del motor).
const _bassStrings = [5, 4, 3];

/// Acordes slash generados por regla a partir de las digitaciones del acorde
/// ([sources], orden del motor):
///
/// 1. Se elige una cuerda grave (6ª, 5ª o 4ª) para el bajo; las cuerdas más
///    graves que ella se mutean.
/// 2. En esa cuerda se pisa [bassPc] en cualquier traste del 0 al 15.
/// 3. Se conserva la forma en las cuerdas agudas, que debe seguir teniendo al
///    menos 3 notas, la raíz y la nota que define el tipo (`intervals[1]`:
///    la 3ª, o la 2ª/4ª en los sus).
/// 4. El bajo tiene que ser la nota más grave, la digitación debe ser
///    tocable ([calculateErgonomicCost] finito) y caber en 4 dedos.
///
/// Devuelve hasta [limit] digitaciones distintas: primero las abiertas
/// ([isOpenPosition], como en Progresiones), luego las de más cuerdas y, a
/// igualdad, la más cómoda y la más baja.
List<SlashVoicing> slashVoicings({
  required List<EngineFrets> sources,
  required int rootPc,
  required List<int> intervals,
  required int bassPc,
  int limit = 6,
}) {
  final root = rootPc % 12;
  final bass = bassPc % 12;
  final defining = intervals.length > 1 ? (root + intervals[1]) % 12 : root;
  final seen = <String>{};
  final out = <SlashVoicing>[];
  for (final source in sources) {
    if (source.length != 6) continue;
    for (final b in _bassStrings) {
      final upper = [
        for (var s = 0; s < b; s++)
          if (source[s] != null) s,
      ];
      if (upper.length < 3) continue;
      final upperPcs = {
        for (final s in upper) (standardOpenStringMidi[s] + source[s]!) % 12,
      };
      if (!upperPcs.contains(root) || !upperPcs.contains(defining)) continue;
      final lowestUpper = [
        for (final s in upper) standardOpenStringMidi[s] + source[s]!,
      ].reduce((a, c) => a < c ? a : c);
      for (var fret = 0; fret <= 15; fret++) {
        if ((standardOpenStringMidi[b] + fret) % 12 != bass) continue;
        if (standardOpenStringMidi[b] + fret >= lowestUpper) continue;
        final frets = <int?>[
          for (var s = 0; s < 6; s++)
            if (s < b) source[s] else if (s == b) fret else null,
        ];
        if (!seen.add(frets.join(','))) continue;
        final fingers = assignFingers(frets);
        if (fingers == null) continue;
        final cost = calculateErgonomicCost(
          ErgonomicVoicing(fretPositions: frets, fingerPositions: fingers),
        );
        if (!cost.isFinite) continue;
        out.add(SlashVoicing(frets: frets, fingers: fingers, cost: cost));
      }
    }
  }
  int lowestFret(EngineFrets f) => [
    for (final x in f)
      if (x != null && x > 0) x,
  ].fold(99, (a, c) => a < c ? a : c);
  int sounding(EngineFrets f) => f.where((x) => x != null).length;
  out.sort((a, c) {
    final byOpen = (isOpenPosition(c.frets) ? 1 : 0) - (isOpenPosition(a.frets) ? 1 : 0);
    if (byOpen != 0) return byOpen;
    final byStrings = sounding(c.frets) - sounding(a.frets);
    if (byStrings != 0) return byStrings;
    final byCost = a.cost.compareTo(c.cost);
    return byCost != 0 ? byCost : lowestFret(a.frets).compareTo(lowestFret(c.frets));
  });
  return out.take(limit).toList();
}

/// Dedos para una digitación (orden del motor). Con 4 notas pisadas o menos,
/// un dedo por nota, por traste y, en el mismo traste, de la cuerda grave a
/// la aguda. Con más, el índice hace cejilla en el traste más bajo si las
/// cuerdas de en medio no están al aire, muteadas ni más abajo. `null` si
/// hacen falta más de 4 dedos.
List<int>? assignFingers(EngineFrets frets) {
  final fretted = [
    for (var s = 0; s < frets.length; s++)
      if (frets[s] != null && frets[s]! > 0) (string: s, fret: frets[s]!),
  ]..sort((a, b) => a.fret != b.fret ? a.fret.compareTo(b.fret) : b.string.compareTo(a.string));
  final fingers = List.filled(frets.length, 0);
  if (fretted.length <= 4) {
    for (final (i, n) in fretted.indexed) {
      fingers[n.string] = i + 1;
    }
    return fingers;
  }
  final low = fretted.first.fret;
  final atLow = [
    for (final n in fretted)
      if (n.fret == low) n.string,
  ];
  final from = atLow.reduce((a, b) => a < b ? a : b);
  final to = atLow.reduce((a, b) => a > b ? a : b);
  final canBarre = [
    for (var s = from; s <= to; s++) frets[s],
  ].every((f) => f != null && f >= low);
  if (!canBarre) return null;
  final rest = [
    for (final n in fretted)
      if (n.fret != low) n,
  ];
  if (rest.length > 3) return null;
  for (final s in atLow) {
    fingers[s] = 1;
  }
  for (final (i, n) in rest.indexed) {
    fingers[n.string] = i + 2;
  }
  return fingers;
}
