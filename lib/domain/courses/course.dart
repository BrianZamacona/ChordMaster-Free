/// Lo común a los cursos por niveles (melodías, acordes abiertos…): pasos de
/// teoría, ejercicio y canción; estrellas por tempo limpio y el avance.
library;

import '../../core/i18n/tr.dart';

enum CourseStepKind { theory, exercise, song }

/// Un paso de un curso. Los de teoría se marcan leídos; los demás dan
/// estrellas por el tempo al que salen limpios.
abstract interface class CourseStep {
  /// Identificador estable: es la clave guardada en el progreso.
  String get id;
  CourseStepKind get kind;
  LocalizedText get title;

  /// De dónde viene una canción (tradicional, compositor y año).
  LocalizedText? get origin;
}

/// Un nivel: título, idea y sus pasos en orden.
class CourseLevel<S extends CourseStep> {
  const CourseLevel({
    required this.title,
    required this.intro,
    required this.steps,
  });

  final LocalizedText title;
  final LocalizedText intro;
  final List<S> steps;
}

/// Tempos que dan una, dos y tres estrellas al tocar un paso limpio.
const courseStarTempos = [60, 80, 100];

/// Estrellas de un paso con mejor tempo limpio [bestBpm].
int starsFor(int? bestBpm) =>
    bestBpm == null ? 0 : courseStarTempos.where((t) => bestBpm >= t).length;

/// Tempo con el que abre un paso: el de la próxima estrella (o el último).
int startTempoFor(int? bestBpm) => courseStarTempos.firstWhere(
  (t) => bestBpm == null || t > bestBpm,
  orElse: () => courseStarTempos.last,
);

/// Todos los pasos de un curso, en orden.
List<S> courseSteps<S extends CourseStep>(List<CourseLevel<S>> levels) => [
  for (final l in levels) ...l.steps,
];

/// El paso que sigue a [step], o `null` si es el último.
S? nextCourseStep<S extends CourseStep>(List<CourseLevel<S>> levels, S step) {
  final all = courseSteps(levels);
  final i = all.indexWhere((s) => s.id == step.id);
  return i >= 0 && i + 1 < all.length ? all[i + 1] : null;
}

/// Número (desde 1) del nivel que contiene [step].
int courseLevelOf<S extends CourseStep>(List<CourseLevel<S>> levels, S step) =>
    levels.indexWhere((l) => l.steps.any((s) => s.id == step.id)) + 1;

/// Los ejercicios y canciones se numeran dentro del nivel; la teoría no.
int? courseExerciseNumber(CourseLevel level, CourseStep step) {
  if (step.kind == CourseStepKind.theory) return null;
  final playable = [
    for (final s in level.steps)
      if (s.kind != CourseStepKind.theory) s.id,
  ];
  return playable.indexOf(step.id) + 1;
}

/// Lo hecho en un curso: el mejor tempo limpio de cada paso que se toca y los
/// pasos de teoría leídos. Sin E/S: lo guarda la UI.
class CourseProgress {
  const CourseProgress({this.best = const {}, this.read = const {}});

  final Map<String, int> best;
  final Set<String> read;

  int stars(CourseStep step) => starsFor(best[step.id]);

  bool isDone(CourseStep step) => step.kind == CourseStepKind.theory
      ? read.contains(step.id)
      : stars(step) > 0;

  /// Estrellas ganadas y posibles en [steps].
  (int, int) starTotals(Iterable<CourseStep> steps) {
    final playable = [
      for (final s in steps)
        if (s.kind != CourseStepKind.theory) s,
    ];
    return (
      playable.fold(0, (sum, s) => sum + stars(s)),
      playable.length * courseStarTempos.length,
    );
  }

  /// Canciones de [steps] con al menos una estrella, y cuántas hay.
  (int, int) songTotals(Iterable<CourseStep> steps) {
    final songs = [
      for (final s in steps)
        if (s.kind == CourseStepKind.song) s,
    ];
    return (songs.where(isDone).length, songs.length);
  }

  CourseProgress copyWith({Map<String, int>? best, Set<String>? read}) =>
      CourseProgress(best: best ?? this.best, read: read ?? this.read);
}
