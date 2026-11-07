import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/lessons/lesson_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Set<String> idsOf(LessonTrack track) => {for (final l in lessonsOf(track)) l.id};
  final basics = unitOfCourse(LessonCourse.basics);
  final melodies = unitOfCourse(LessonCourse.melodies);
  // Pasos hechos de cada curso: todo terminado.
  const finished = {
    LessonCourse.basics: (20, 20),
    LessonCourse.melodies: (30, 30),
    LessonCourse.openChords: (50, 50),
    LessonCourse.strumming: (50, 50),
  };
  const foundationsDone = {
    LessonCourse.basics: (20, 20),
    LessonCourse.melodies: (30, 30),
  };
  /// La primera lección de [track] (sus cursos, terminados, no cuentan).
  Lesson firstLesson(LessonTrack track) => lessonsOf(track).first;

  test('sin progreso, lo que toca es el primer curso de Fundamentos', () {
    final path = LessonPath(completed: {}, chosen: LessonTrack.rhythm);
    expect(path.next, isA<NextCourse>());
    expect(path.next!.unit, basics);
    expect(path.nextLesson, isNull);
    expect(path.foundationsDone, isFalse);
  });

  test('un curso a medias sigue siendo lo que toca; terminado, pasa al siguiente', () {
    var path = LessonPath(
      completed: {},
      chosen: LessonTrack.rhythm,
      courses: {LessonCourse.basics: (5, 20)},
    );
    expect(path.next!.unit, basics);
    path = LessonPath(
      completed: {},
      chosen: LessonTrack.rhythm,
      courses: {LessonCourse.basics: (20, 20)},
    );
    expect(path.next!.unit, melodies);
  });

  test('un curso que aún carga (0 de 0) no cuenta como terminado', () {
    final path = LessonPath(
      completed: {},
      chosen: LessonTrack.rhythm,
      courses: {LessonCourse.basics: (0, 0)},
    );
    expect(path.unitFinished(basics), isFalse);
  });

  test('el avance de un camino suma lecciones y pasos de sus cursos', () {
    final lead = lessonsOf(LessonTrack.lead);
    final path = LessonPath(
      completed: {lead[0].id, lead[1].id},
      chosen: LessonTrack.lead,
      courses: {LessonCourse.basics: (3, 20), LessonCourse.melodies: (0, 30)},
    );
    expect(path.next!.unit, basics, reason: 'Fundamentos va primero');
    expect(path.progressOf(LessonTrack.lead), (2, lead.length));
    expect(path.progressOf(LessonTrack.foundations), (3, 50));
  });

  test('con Fundamentos terminado, sigue el camino elegido', () {
    final rhythm = LessonPath(completed: {}, chosen: LessonTrack.rhythm, courses: foundationsDone);
    expect(rhythm.foundationsDone, isTrue);
    // Rítmica empieza por un curso (Acordes abiertos – Parte 1).
    expect(rhythm.next, isA<NextCourse>());
    expect(rhythm.next!.unit.course, LessonCourse.openChords);
    final lead = LessonPath(completed: {}, chosen: LessonTrack.lead, courses: foundationsDone);
    expect(lead.nextLesson, firstLesson(LessonTrack.lead));
  });

  test('al terminar el camino elegido, sigue el otro; al final, null', () {
    expect(
      LessonPath(
        completed: idsOf(LessonTrack.rhythm),
        chosen: LessonTrack.rhythm,
        courses: finished,
      ).nextLesson,
      firstLesson(LessonTrack.lead),
    );
    final all = {for (final l in curriculum) l.id};
    expect(
      LessonPath(completed: all, chosen: LessonTrack.rhythm, courses: finished).next,
      isNull,
    );
  });

  test('ids que ya no existen en el currículo se ignoran', () {
    final path = LessonPath(
      completed: {'leccion_borrada', curriculum.first.id},
      chosen: LessonTrack.rhythm,
    );
    expect(path.completed, {curriculum.first.id});
  });

  test('etiquetas R1…R20 y L1…L18', () {
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.rhythm).first), 'R1');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.rhythm).last), 'R20');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.lead).last), 'L18');
    expect(LessonPath.labelOf(lessonsOf(LessonTrack.lead)[2]), 'L3');
  });
}
