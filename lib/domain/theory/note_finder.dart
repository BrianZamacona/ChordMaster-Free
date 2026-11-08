/// Buscador por notas: con lo que se marca en el diapasón, qué acordes pueden
/// ser (una nota por cuerda, con su bajo) y en qué escalas caben las notas.
///
/// Los resultados salen de las fórmulas (intervalos desde la tónica) de `chords.json` y
/// `scales_master.json`: nada de tablas propias de acordes o escalas.
library;

import 'notes.dart';

/// Un tipo de acorde o escala: su id y sus intervalos desde la tónica, en
/// semitonos (pueden pasar de 12, como la 9ª = 14).
typedef PitchFormula = ({String id, List<int> intervals});

/// Una nota marcada: cuerda (1 = mi aguda … 6 = mi grave) y traste (0 = al
/// aire).
typedef FretNote = ({int string, int fret});

/// Altura MIDI de [n] en afinación estándar.
int fretNoteMidi(FretNote n) => standardOpenStringMidi[n.string - 1] + n.fret;

/// Clase de altura (0 = C … 11 = B) de [n].
int fretNotePitchClass(FretNote n) => fretNoteMidi(n) % 12;

/// Clases de altura de [notes].
Set<int> pitchClassesOf(Iterable<FretNote> notes) => {for (final n in notes) fretNotePitchClass(n)};

/// La nota más grave de [notes] (clase de altura), o `null` si no hay.
int? bassOf(Iterable<FretNote> notes) {
  FretNote? low;
  for (final n in notes) {
    if (low == null || fretNoteMidi(n) < fretNoteMidi(low)) low = n;
  }
  return low == null ? null : fretNotePitchClass(low);
}

Set<int> _pitchSet(int root, List<int> intervals) => {for (final i in intervals) (root + i) % 12};

bool _sameSet(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);

/// Un acorde posible para las notas marcadas.
class ChordMatch {
  const ChordMatch({
    required this.root,
    required this.type,
    required this.bass,
    this.omitted = const [],
  });

  /// Tónica (0 = C … 11 = B).
  final int root;

  /// Tipo, como en `chords.json` (`major`, `minor7`…).
  final String type;

  /// Nota más grave que suena; si no es la tónica, el acorde es slash (C/E).
  final int? bass;

  /// Notas del acorde que no suenan (intervalos desde la tónica: 7 = 5ª,
  /// 14 = 9ª, 17 = 11ª), como se toca en guitarra. Vacío = completo.
  final List<int> omitted;

  bool get isSlash => bass != null && bass != root;

  @override
  bool operator ==(Object other) =>
      other is ChordMatch &&
      other.root == root &&
      other.type == type &&
      other.bass == bass &&
      _sameList(other.omitted, omitted);

  @override
  int get hashCode => Object.hash(root, type, bass, Object.hashAll(omitted));

  @override
  String toString() =>
      '${pitchClassName(root)} $type${isSlash ? '/${pitchClassName(bass!)}' : ''}'
      '${omitted.isEmpty ? '' : ' sin $omitted'}';
}

bool _sameList(List<int> a, List<int> b) =>
    a.length == b.length && [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

/// Intervalos que un acorde puede no tocar: la 5ª justa, la 9ª y la 11ª,
/// salvo que sean su nota más alta (la que le da el nombre: en Cadd9 la 9ª
/// no se omite). Tónica, 3ª (o 2ª/4ª de los sus), 7ª y 6ª/13ª siempre suenan.
const omissibleIntervals = {7, 14, 17};

List<int> _omissible(List<int> intervals) {
  final top = intervals.reduce((a, b) => a > b ? a : b);
  return [
    for (final i in intervals)
      if (omissibleIntervals.contains(i) && i != top) i,
  ];
}

/// Acordes de [types] que forman las notas [pitchClasses], con [bass] como
/// nota más grave: exactamente sus notas, o todas menos alguna de las que se
/// pueden omitir ([omissibleIntervals]). Primero los completos, luego los que
/// tienen la tónica en el bajo, los que omiten menos, los de menos notas y,
/// si no, en el orden de [types]. Con menos de dos notas distintas no hay
/// acorde.
List<ChordMatch> chordsFor(
  Set<int> pitchClasses, {
  required List<PitchFormula> types,
  int? bass,
}) {
  if (pitchClasses.length < 2) return const [];
  final found = <(ChordMatch, int size, int order)>[];
  for (var root = 0; root < 12; root++) {
    for (final (order, t) in types.indexed) {
      final chord = _pitchSet(root, t.intervals);
      if (!chord.containsAll(pitchClasses)) continue;
      final missing = chord.difference(pitchClasses);
      final omissible = _omissible(t.intervals);
      final omitted = [
        for (final i in omissible)
          if (missing.contains((root + i) % 12)) i,
      ];
      // Lo que falta tiene que ser omitible (y no la misma nota que otra que sí suena).
      if (missing.length != omitted.length) continue;
      found.add((
        ChordMatch(root: root, type: t.id, bass: bass, omitted: omitted),
        chord.length,
        order,
      ));
    }
  }
  int rank(ChordMatch m) => (m.omitted.isEmpty ? 0 : 2) + (m.isSlash ? 1 : 0);
  found.sort((a, b) {
    final byRank = rank(a.$1).compareTo(rank(b.$1));
    if (byRank != 0) return byRank;
    final byOmitted = a.$1.omitted.length.compareTo(b.$1.omitted.length);
    if (byOmitted != 0) return byOmitted;
    final bySize = a.$2.compareTo(b.$2);
    if (bySize != 0) return bySize;
    final byOrder = a.$3.compareTo(b.$3);
    return byOrder != 0 ? byOrder : a.$1.root.compareTo(b.$1.root);
  });
  return [for (final f in found) f.$1];
}

/// Una escala en la que caben todas las notas marcadas.
class ScaleMatch {
  const ScaleMatch({required this.root, required this.id, required this.extra});

  /// Tónica (0 = C … 11 = B).
  final int root;

  /// Id de `scales_master.json`.
  final String id;

  /// Notas de la escala que no se marcaron: 0 = la escala son justo esas.
  final int extra;

  @override
  bool operator ==(Object other) =>
      other is ScaleMatch && other.root == root && other.id == id && other.extra == extra;

  @override
  int get hashCode => Object.hash(root, id, extra);

  @override
  String toString() => '${pitchClassName(root)} $id (+$extra)';
}

/// Escalas de [scales] (en las 12 tónicas) que contienen todas las notas
/// [pitchClasses]. Primero las que menos notas agregan; a igualdad, la que
/// tiene por tónica [tonic] (la nota más grave), luego las que tienen la
/// tónica entre las notas marcadas, y si no, en el orden de [scales]. Dos
/// escalas con la misma tónica y las mismas notas (mayor y jónica) salen una
/// vez: la primera de [scales]. Con menos de dos notas distintas no se busca.
List<ScaleMatch> scalesFor(
  Set<int> pitchClasses, {
  required List<PitchFormula> scales,
  int? tonic,
}) {
  if (pitchClasses.length < 2) return const [];
  final found = <(ScaleMatch, int order)>[];
  for (var root = 0; root < 12; root++) {
    final seen = <Set<int>>[];
    for (final (order, s) in scales.indexed) {
      final set = _pitchSet(root, s.intervals);
      if (!set.containsAll(pitchClasses)) continue;
      if (seen.any((other) => _sameSet(other, set))) continue;
      seen.add(set);
      found.add((
        ScaleMatch(root: root, id: s.id, extra: set.length - pitchClasses.length),
        order,
      ));
    }
  }
  int closeness(ScaleMatch m) =>
      m.root == tonic ? 0 : (pitchClasses.contains(m.root) ? 1 : 2);
  found.sort((a, b) {
    final byExtra = a.$1.extra.compareTo(b.$1.extra);
    if (byExtra != 0) return byExtra;
    final byTonic = closeness(a.$1).compareTo(closeness(b.$1));
    if (byTonic != 0) return byTonic;
    final byOrder = a.$2.compareTo(b.$2);
    return byOrder != 0 ? byOrder : a.$1.root.compareTo(b.$1.root);
  });
  return [for (final f in found) f.$1];
}
