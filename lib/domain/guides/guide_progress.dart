/// Progreso en las guías: qué capítulos están hechos, cuánto falta, cuánto
/// tarda una guía y cuál sigue. Dart puro; el estado lo guarda la UI.
///
/// Un capítulo que enlaza una lección está hecho cuando la lección está
/// terminada (una sola fuente: `lessons_completed`). Los demás se marcan a
/// mano y se guardan como `guideId/índice`.
library;

import '../lessons/curriculum.dart';
import 'guides.dart';

/// Minutos aproximados de un capítulo. Una lección dice los suyos; el resto
/// es lo que toma una práctica corta con ese módulo.
int chapterMinutes(GuideTarget target) => switch (target) {
  LessonLink(:final lessonId) => lessonsById[lessonId]?.minutes ?? 8,
  ChordLink() => 3,
  ScaleLink() => 5,
  ModuleLink() => 5,
  CourseLink() => 5,
  WorkoutLink() => 10,
  LickLink() => 5,
};

/// Minutos aproximados de toda la guía.
int guideMinutes(Guide guide) =>
    guide.chapters.fold(0, (sum, c) => sum + chapterMinutes(c.target));

/// Clave guardada de un capítulo marcado a mano.
String chapterKey(Guide guide, int index) => '${guide.id}/$index';

/// Qué está hecho, a partir de los capítulos marcados y las lecciones
/// terminadas.
class GuideProgress {
  const GuideProgress({
    this.checked = const {},
    this.lessonsCompleted = const {},
  });

  /// Claves [chapterKey] de los capítulos marcados a mano.
  final Set<String> checked;
  final Set<String> lessonsCompleted;

  bool isDone(Guide guide, int index) => switch (guide.chapters[index].target) {
    LessonLink(:final lessonId) => lessonsCompleted.contains(lessonId),
    _ => checked.contains(chapterKey(guide, index)),
  };

  int doneCount(Guide guide) => [
    for (var i = 0; i < guide.chapters.length; i++)
      if (isDone(guide, i)) i,
  ].length;

  bool isFinished(Guide guide) => doneCount(guide) == guide.chapters.length;

  /// Empezada y sin terminar.
  bool isStarted(Guide guide) =>
      doneCount(guide) > 0 && !isFinished(guide);

  /// Primer capítulo pendiente, o null si la guía está terminada.
  int? nextChapter(Guide guide) {
    for (var i = 0; i < guide.chapters.length; i++) {
      if (!isDone(guide, i)) return i;
    }
    return null;
  }

  /// Guías empezadas y sin terminar, en el orden del catálogo.
  List<Guide> inProgress() => [for (final g in guides) if (isStarted(g)) g];

  /// La guía que conviene después de [guide]: la siguiente sin terminar de su
  /// fila y, si no queda, la siguiente sin terminar del catálogo (dando la
  /// vuelta). Null si todas están terminadas.
  Guide? nextGuide(Guide guide) {
    final row = guidesIn(guide.category);
    for (final g in row.skip(row.indexOf(guide) + 1)) {
      if (!isFinished(g)) return g;
    }
    final start = guides.indexOf(guide);
    for (var step = 1; step < guides.length; step++) {
      final g = guides[(start + step) % guides.length];
      if (g != guide && !isFinished(g)) return g;
    }
    return null;
  }
}
