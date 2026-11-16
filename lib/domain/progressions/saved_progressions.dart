/// "Mis progresiones": las progresiones armadas en "Mi progresión" que el
/// usuario guarda con nombre (decisión del usuario tras revisar Pocket
/// Composer). Cada una lleva su escala de base y la canción entera: sus
/// secciones (acordes con su duración) y el orden en que se tocan.
library;

import 'custom_progression.dart';
import 'song.dart';

/// Un acorde de "Mi progresión": su número romano y sus pulsos.
typedef CustomChord = ({String numeral, int beats});

/// Cuántas se pueden guardar.
const savedProgressionsMax = 20;

/// Una progresión guardada.
class SavedProgression {
  const SavedProgression({required this.name, required this.mode, required this.sections, this.order = const [0]});

  final String name;

  /// Escala de base (ver `customBaseModes`).
  final int mode;

  /// Las secciones (A, B…), cada una con sus acordes.
  final List<List<CustomChord>> sections;

  /// En qué orden se tocan (índices de [sections]).
  final List<int> order;

  /// Cómo se guarda: los acordes como en "Mi progresión" (`customToken`).
  Map<String, Object> toJson() => {
    'name': name,
    'mode': mode,
    'sections': [
      for (final section in sections) [for (final c in section) customToken(c.numeral, c.beats)],
    ],
    'order': order,
  };

  /// Lee [toJson] (y las de antes, de una sola sección en `chords`); `null` si
  /// algo no vale: nombre vacío, escala o acorde desconocidos, una sección
  /// vacía o de más, o un orden que nombra una sección que no está.
  static SavedProgression? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final mode = json['mode'];
    if (name is! String || name.trim().isEmpty || mode is! int || !customBaseModes.contains(mode)) return null;
    final song = parseSong(json['sections'] ?? (json.containsKey('chords') ? [json['chords']] : null), json['order']);
    if (song == null) return null;
    return SavedProgression(name: name.trim(), mode: mode, sections: song.sections, order: song.order);
  }
}

/// Las secciones (listas de `customToken`) y el orden de una canción; `null`
/// si algo no vale: una sección de más, un acorde desconocido, un orden vacío o
/// que nombra una sección que no está. Con [allowEmpty] una sección puede
/// estar vacía (la de "Mi progresión" mientras se arma); las guardadas no.
({List<List<CustomChord>> sections, List<int> order})? parseSong(
  Object? rawSections,
  Object? rawOrder, {
  bool allowEmpty = false,
}) {
  if (rawSections is! List || rawSections.isEmpty || rawSections.length > songMaxSections) return null;
  final sections = <List<CustomChord>>[];
  for (final tokens in rawSections) {
    if (tokens is! List || tokens.any((t) => t is! String)) return null;
    final chords = [for (final t in tokens.cast<String>()) parseCustomToken(t)];
    if ((chords.isEmpty && !allowEmpty) || chords.length > customProgressionMax || chords.any((c) => c == null)) {
      return null;
    }
    sections.add([for (final c in chords) c!]);
  }
  final order = rawOrder ?? const [0];
  if (order is! List || order.isEmpty || order.length > songMaxParts) return null;
  if (order.any((i) => i is! int || i < 0 || i >= sections.length)) return null;
  return (sections: sections, order: order.cast<int>());
}

/// [sections] y [order] sin las secciones vacías (el orden se corre con
/// `orderWithoutSection`).
({List<List<CustomChord>> sections, List<int> order}) withoutEmptySections(
  List<List<CustomChord>> sections,
  List<int> order,
) {
  var out = [...sections];
  var next = [...order];
  for (var i = out.length - 1; i >= 0; i--) {
    if (out[i].isNotEmpty) continue;
    out = [...out]..removeAt(i);
    next = orderWithoutSection(next, i);
  }
  return (sections: out, order: next);
}

/// Si dos nombres son el mismo (sin espacios de más ni mayúsculas).
bool sameProgressionName(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

/// [saved] con [item]: si ya hay una con su nombre, la reemplaza en su lugar;
/// si no, va al principio. `null` si no cabe (ya hay [savedProgressionsMax]).
List<SavedProgression>? upsertSaved(List<SavedProgression> saved, SavedProgression item) {
  final i = saved.indexWhere((s) => sameProgressionName(s.name, item.name));
  if (i >= 0) return [...saved]..[i] = item;
  if (saved.length >= savedProgressionsMax) return null;
  return [item, ...saved];
}

/// El primer "[base] N" (N = 1, 2…) que no está usado.
String nextProgressionName(List<SavedProgression> saved, String base) {
  for (var n = 1; ; n++) {
    final name = '$base $n';
    if (!saved.any((s) => sameProgressionName(s.name, name))) return name;
  }
}
