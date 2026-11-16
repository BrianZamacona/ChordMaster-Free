/// "Mis progresiones": las progresiones armadas en "Mi progresión" que el
/// usuario guarda con nombre (decisión del usuario tras revisar Pocket
/// Composer). Cada una lleva su escala de base y sus acordes con su duración.
library;

import 'custom_progression.dart';

/// Un acorde de "Mi progresión": su número romano y sus pulsos.
typedef CustomChord = ({String numeral, int beats});

/// Cuántas se pueden guardar.
const savedProgressionsMax = 20;

/// Una progresión guardada.
class SavedProgression {
  const SavedProgression({required this.name, required this.mode, required this.chords});

  final String name;

  /// Escala de base (ver `customBaseModes`).
  final int mode;
  final List<CustomChord> chords;

  /// Cómo se guarda: los acordes como en "Mi progresión" (`customToken`).
  Map<String, Object> toJson() => {
    'name': name,
    'mode': mode,
    'chords': [for (final c in chords) customToken(c.numeral, c.beats)],
  };

  /// Lee [toJson]; `null` si algo no vale (nombre vacío, escala o acorde
  /// desconocidos, ningún acorde).
  static SavedProgression? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'];
    final mode = json['mode'];
    final tokens = json['chords'];
    if (name is! String || name.trim().isEmpty || mode is! int || !customBaseModes.contains(mode)) return null;
    if (tokens is! List || tokens.any((t) => t is! String)) return null;
    final chords = [for (final t in tokens.cast<String>()) parseCustomToken(t)];
    if (chords.isEmpty || chords.length > customProgressionMax || chords.any((c) => c == null)) return null;
    return SavedProgression(name: name.trim(), mode: mode, chords: [for (final c in chords) c!]);
  }
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
