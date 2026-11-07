import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/lessons/lesson_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Set<String> idsOf(LessonTrack track) => {for (final l in lessonsOf(track)) l.id};

  test('sin progreso, la siguiente es la primera de Fundamentos', () {
    final path = LessonPath(completed: {}, chosen: LessonTrack.rhythm);
    expect(path.next, curriculum.first);
    expect(path.foundationsDone, isFalse);
    expect(
      path.progressOf(LessonTrack.foundations),
      (0, lessonsOf(LessonTrack.foundations).length),
    );
  });

  test('Fundamentos va primero aunque ya se haya avanzado en un camino', () {
    final lead = lessonsOf(LessonTrack.lead);
    final path = LessonPath(
      completed: {lead[0].id, lead[1].id},
      chosen: LessonTrack.lead,
    );
    expect(path.next, lessonsOf(LessonTrack.foundations).first);
    expect(path.progressOf(LessonTrack.lead), (2, lessonsOf(LessonTrack.lead).length));
  });

  test('con Fundamentos terminado, sigue el camino elegido', () {
    final done = idsOf(LessonTrack.foundations);
    expect(
      LessonPath(completed: done, chosen: LessonTrack.rhythm).next,
      lessonsOf(LessonTrack.rhythm).first,
    );
    expect(
      LessonPath(completed: done, chosen: LessonTrack.lead).next,
      lessonsOf(LessonTrack.lead).first,
    );
  });

  test('al terminar el camino elegido, sigue el otro; al final, null', () {
    final foundationsAndRhythm = {
      ...idsOf(LessonTrack.foundations),
      ...idsOf(LessonTrack.rhythm),
    };
    expect(
      LessonPath(completed: foundationsAndRhythm, chosen: LessonTrack.rhythm).next,
      lessonsOf(LessonTrack.lead).first,
    );
    final all = {for (final l in curriculum) l.id};
    expect(LessonPath(completed: all, chosen: LessonTrack.rhythm).next, isNull);
  });

  test('ids que ya no existen en el currículo se ignoran', () {
    final path = LessonPath(
      completed: {'leccion_borrada', curriculum.first.id},
      chosen: LessonTrack.rhythm,
    );
    expect(path.completed, {curriculum.first.id});
  });

  test('etiquetas F1…F10, R1…R17, L1…L18', () {
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.foundations).first), 'F1');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.foundations).last), 'F10');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.rhythm).last), 'R17');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.lead).last), 'L18');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.lead)[2]), 'L3');
  });
}
