import 'curriculum.dart';
import 'lesson.dart';

/// Estado del camino a partir de las lecciones terminadas y del camino que
/// eligió la persona (rítmica o líder).
class LessonPath {
  LessonPath({required Set<String> completed, required this.chosen})
      : completed = {
          for (final id in completed)
            if (lessonsById.containsKey(id)) id,
        },
        assert(chosen != LessonTrack.foundations);

  /// Ids terminados que siguen existiendo en el currículo (los de lecciones
  /// borradas se ignoran).
  final Set<String> completed;

  /// Camino que se muestra después de Fundamentos.
  final LessonTrack chosen;

  bool isDone(Lesson lesson) => completed.contains(lesson.id);

  /// Terminadas y totales de [track].
  (int done, int total) progressOf(LessonTrack track) {
    final lessons = lessonsOf(track);
    return (lessons.where(isDone).length, lessons.length);
  }

  bool get foundationsDone {
    final (done, total) = progressOf(LessonTrack.foundations);
    return done == total;
  }

  /// La que toca ahora: la primera pendiente de Fundamentos; si ya se
  /// terminaron, la primera del camino elegido; si también, la primera
  /// pendiente del otro. `null` cuando no queda ninguna.
  Lesson? get next {
    final order = [
      LessonTrack.foundations,
      chosen,
      if (chosen == LessonTrack.rhythm) LessonTrack.lead else LessonTrack.rhythm,
    ];
    for (final track in order) {
      for (final lesson in lessonsOf(track)) {
        if (!isDone(lesson)) return lesson;
      }
    }
    return null;
  }

  /// Número que se muestra en la ruta: F1…F8, R1…R8, L1…L8.
  static String labelOf(Lesson lesson) {
    final prefix = switch (lesson.track) {
      LessonTrack.foundations => 'F',
      LessonTrack.rhythm => 'R',
      LessonTrack.lead => 'L',
    };
    return '$prefix${lessonsOf(lesson.track).indexOf(lesson) + 1}';
  }
}
