import 'curriculum.dart';
import 'lesson.dart';

/// Lo que toca ahora en el camino: una lección o un curso del mapa.
sealed class PathNext {
  const PathNext();

  /// La unidad del mapa donde está.
  LessonUnit get unit;
}

final class NextLesson extends PathNext {
  const NextLesson(this.lesson);
  final Lesson lesson;

  @override
  LessonUnit get unit => lesson.unit;
}

final class NextCourse extends PathNext {
  const NextCourse(this.unit);

  @override
  final LessonUnit unit;
}

/// Estado del camino a partir de las lecciones terminadas, los pasos hechos
/// de cada curso y el camino que eligió la persona (rítmica o líder).
class LessonPath {
  LessonPath({
    required Set<String> completed,
    required this.chosen,
    this.courses = const {},
  })  : completed = {
          for (final id in completed)
            if (lessonsById.containsKey(id)) id,
        },
        assert(chosen != LessonTrack.foundations);

  /// Ids terminados que siguen existiendo en el currículo (los de lecciones
  /// borradas se ignoran).
  final Set<String> completed;

  /// Camino que se muestra después de Fundamentos.
  final LessonTrack chosen;

  /// Pasos hechos y totales de cada curso. Un curso que falta (porque sus
  /// datos aún cargan) cuenta como 0 de 0 y no está terminado.
  final Map<LessonCourse, (int, int)> courses;

  bool isDone(Lesson lesson) => completed.contains(lesson.id);

  /// Hechos y totales de [unit]: lecciones o, si es un curso, pasos.
  (int, int) unitProgress(LessonUnit unit) {
    if (unit.course case final course?) return courses[course] ?? (0, 0);
    final lessons = lessonsOfUnit(unit);
    return (lessons.where(isDone).length, lessons.length);
  }

  bool unitFinished(LessonUnit unit) {
    final (done, total) = unitProgress(unit);
    return total > 0 && done == total;
  }

  /// Hechos y totales de [track], sumando sus unidades.
  (int done, int total) progressOf(LessonTrack track) {
    var done = 0;
    var total = 0;
    for (final unit in unitsOf(track)) {
      final (d, t) = unitProgress(unit);
      done += d;
      total += t;
    }
    return (done, total);
  }

  bool get foundationsDone => unitsOf(LessonTrack.foundations).every(unitFinished);

  /// Lo que toca ahora: lo primero pendiente de Fundamentos; si ya se
  /// terminó, del camino elegido; si también, del otro. `null` cuando no
  /// queda nada.
  PathNext? get next {
    final order = [
      LessonTrack.foundations,
      chosen,
      if (chosen == LessonTrack.rhythm) LessonTrack.lead else LessonTrack.rhythm,
    ];
    for (final track in order) {
      for (final unit in unitsOf(track)) {
        if (unit.course != null) {
          if (!unitFinished(unit)) return NextCourse(unit);
          continue;
        }
        for (final lesson in lessonsOfUnit(unit)) {
          if (!isDone(lesson)) return NextLesson(lesson);
        }
      }
    }
    return null;
  }

  /// La próxima lección pendiente, si lo que toca es una lección.
  Lesson? get nextLesson => switch (next) {
    NextLesson(:final lesson) => lesson,
    _ => null,
  };

  /// Número que se muestra en la ruta: R3, L10…
  static String labelOf(Lesson lesson) {
    final prefix = switch (lesson.track) {
      LessonTrack.foundations => 'F',
      LessonTrack.rhythm => 'R',
      LessonTrack.lead => 'L',
    };
    return '$prefix${lessonsOf(lesson.track).indexOf(lesson) + 1}';
  }
}
