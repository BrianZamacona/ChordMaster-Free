/// Cómo se recorre la biblioteca de licks: filtros (nivel, tipo, escala,
/// tónica y técnica), la frase anterior y la siguiente de un estilo, y el
/// tempo a una fracción del suyo ("▶ al 50 %").
library;

import '../guides/guides.dart';
import '../lessons/lesson.dart';
import '../practice/technique_exercises.dart';
import 'lick.dart';
import 'licks.dart';

/// Velocidades de un toque, en % del tempo de la frase.
const lickSpeeds = [50, 75, 100];

/// El tempo de [lick] al [percent] %, redondeado al paso del selector de tempo
/// (5 BPM) y sin bajar del mínimo.
int lickTempoAt(Lick lick, int percent) {
  final raw = lick.bpm * percent / 100;
  final stepped = (raw / techniqueBpmStep).round() * techniqueBpmStep;
  return stepped.clamp(techniqueMinBpm, techniqueMaxBpm);
}

/// La velocidad de [lickSpeeds] que da [bpm] en [lick], o `null` si el tempo
/// se eligió a mano.
int? lickSpeedOf(Lick lick, int bpm) {
  for (final s in lickSpeeds) {
    if (lickTempoAt(lick, s) == bpm) return s;
  }
  return null;
}

/// La frase anterior y la siguiente del mismo estilo, en el orden de la
/// biblioteca (`null` en los extremos).
({Lick? previous, Lick? next}) lickNeighbors(Lick lick) {
  final mine = [for (final l in licks) if (l.style == lick.style) l];
  final i = mine.indexOf(lick);
  return (
    previous: i > 0 ? mine[i - 1] : null,
    next: i >= 0 && i + 1 < mine.length ? mine[i + 1] : null,
  );
}

/// Filtros de la biblioteca; `null` = todos.
class LickFilter {
  const LickFilter({this.level, this.kind, this.scaleId, this.root, this.technique});

  final GuideLevel? level;
  final LickKind? kind;

  /// Id de `scales_master.json`.
  final String? scaleId;

  /// Tónica (semitono, 0 = C).
  final int? root;
  final TabTechnique? technique;

  bool matches(Lick l) =>
      (level == null || l.level == level) &&
      (kind == null || l.kind == kind) &&
      (scaleId == null || l.scale.scaleId == scaleId) &&
      (root == null || l.scale.root == root) &&
      (technique == null || l.techniques.contains(technique));

  LickFilter copyWith({
    GuideLevel? Function()? level,
    LickKind? Function()? kind,
    String? Function()? scaleId,
    int? Function()? root,
    TabTechnique? Function()? technique,
  }) => LickFilter(
    level: level == null ? this.level : level(),
    kind: kind == null ? this.kind : kind(),
    scaleId: scaleId == null ? this.scaleId : scaleId(),
    root: root == null ? this.root : root(),
    technique: technique == null ? this.technique : technique(),
  );
}

/// Escalas que usa la biblioteca, en el orden en que aparecen.
List<String> get lickScaleIds => {for (final l in licks) l.scale.scaleId}.toList();

/// Tónicas que usa la biblioteca, de C a B.
List<int> get lickRoots => ({for (final l in licks) l.scale.root}.toList()..sort());

/// Técnicas que usa la biblioteca, en el orden de [TabTechnique].
List<TabTechnique> get lickTechniques {
  final used = {for (final l in licks) ...l.techniques};
  return [for (final t in TabTechnique.values) if (used.contains(t)) t];
}
