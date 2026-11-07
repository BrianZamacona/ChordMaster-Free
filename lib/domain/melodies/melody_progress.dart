/// Avance del curso de melodías, sin E/S: lo guarda la UI.
library;

import 'melody_course.dart';

/// Lo hecho en el curso de melodías: el mejor tempo limpio de cada paso con
/// notas y los pasos de teoría leídos.
class MelodyProgress {
  const MelodyProgress({this.best = const {}, this.read = const {}});

  final Map<String, int> best;
  final Set<String> read;

  int stars(MelodyStep step) => starsFor(best[step.id]);

  bool isDone(MelodyStep step) => step.kind == MelodyStepKind.theory
      ? read.contains(step.id)
      : stars(step) > 0;

  /// Estrellas ganadas y posibles en todo el curso.
  (int, int) get starTotals {
    final playable = [
      for (final s in melodyStepsById.values)
        if (s.kind != MelodyStepKind.theory) s,
    ];
    return (
      playable.fold(0, (sum, s) => sum + stars(s)),
      playable.length * melodyStarTempos.length,
    );
  }

  /// Canciones con al menos una estrella, y cuántas hay.
  (int, int) get songTotals {
    final songs = [
      for (final s in melodyStepsById.values)
        if (s.kind == MelodyStepKind.song) s,
    ];
    return (songs.where(isDone).length, songs.length);
  }

  MelodyProgress copyWith({Map<String, int>? best, Set<String>? read}) =>
      MelodyProgress(best: best ?? this.best, read: read ?? this.read);
}
