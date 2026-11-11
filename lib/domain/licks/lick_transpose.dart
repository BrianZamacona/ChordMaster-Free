/// Transponer una frase de la biblioteca (decisión del usuario: solo las
/// movibles). Una frase es movible si no toca ninguna cuerda al aire: así la
/// misma digitación suena en cualquier tonalidad moviendo la mano. Se suman los
/// mismos trastes a todas las notas, por el camino más corto a la tónica
/// pedida; si la frase se saldría del mástil, se prueba la otra octava, y si
/// tampoco cabe, esa tónica no se ofrece.
library;

import '../lessons/lesson.dart';
import 'lick.dart';

/// Traste más alto que puede tocar una frase (el mismo límite del test de la
/// biblioteca).
const lickMaxFret = 20;

/// Ninguna nota (tampoco de un acorde) va al aire.
bool isMovable(Lick lick) => lick.tab.every((n) => n.isRest || n.tones.every((t) => t.fret > 0));

/// Semitonos que hay que mover [lick] para que su tónica sea [root], o `null`
/// si no es movible o no cabe en los trastes 1 a [lickMaxFret].
int? transposeShift(Lick lick, int root) {
  if (!isMovable(lick)) return null;
  final up = (root - lick.scale.root) % 12;
  final frets = [
    for (final n in lick.tab)
      if (!n.isRest)
        for (final t in n.tones) t.fret,
  ];
  bool fits(int shift) => frets.every((f) => f + shift >= 1 && f + shift <= lickMaxFret);
  // La más cercana a la posición original primero.
  final candidates = up == 0 ? [0] : ([up, up - 12]..sort((a, b) => a.abs().compareTo(b.abs())));
  for (final shift in candidates) {
    if (fits(shift)) return shift;
  }
  return null;
}

/// Tónicas a las que se puede llevar [lick] (con la suya), de C a B.
List<int> transposableRoots(Lick lick) => [
  for (var r = 0; r < 12; r++)
    if (transposeShift(lick, r) != null) r,
];

/// [tab] con todos sus trastes movidos [shift] (también las notas de un
/// acorde); los silencios quedan igual.
List<TabNote> transposeTab(List<TabNote> tab, int shift) => [
  for (final n in tab)
    if (n.isRest)
      n
    else
      TabNote(
        n.string,
        n.fret + shift,
        length: n.length,
        technique: n.technique,
        bend: n.bend,
        pick: n.pick,
        chord: [for (final (s, f) in n.chord) (s, f + shift)],
      ),
];

/// La frase en la tónica [root]: tablatura, escala y texto (las notas que el
/// texto nombra salen de la tónica, ver [Lick.aboutIn]). `null` si no se
/// puede.
({List<TabNote> tab, LessonScale scale})? transposedLick(Lick lick, int root) {
  final shift = transposeShift(lick, root);
  if (shift == null) return null;
  return (
    tab: transposeTab(lick.tab, shift),
    scale: LessonScale(scaleId: lick.scale.scaleId, root: root % 12),
  );
}
