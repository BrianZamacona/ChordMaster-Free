import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/melodies/melody_course.dart';
import '../open_chords/open_chords_course_provider.dart';
import '../strumming/strumming_course_provider.dart';
import 'course_progress.dart';

/// Lo que la app necesita de cada curso del mapa: dónde guarda su avance,
/// sus niveles, su presentación y sus rutas (cuelgan de Lecciones, así atrás
/// vuelve al mapa).
extension LessonCourseInfo on LessonCourse {
  CourseId get progressId => switch (this) {
    LessonCourse.melodies => CourseId.melodies,
    LessonCourse.openChords => CourseId.openChords,
    LessonCourse.strumming => CourseId.strumming,
  };

  /// Tramo de la ruta: `/learn/lessons/course/<slug>/<paso>`.
  String get slug => switch (this) {
    LessonCourse.melodies => 'melodies',
    LessonCourse.openChords => 'open-chords',
    LessonCourse.strumming => 'strumming',
  };

  String get intro => switch (this) {
    LessonCourse.melodies => AppStrings.melodiesIntro,
    LessonCourse.openChords => AppStrings.openChordsIntro,
    LessonCourse.strumming => AppStrings.strummingIntro,
  };

  String stepRoute(String stepId) => '/learn/lessons/course/$slug/$stepId';

  /// El curso por su tramo de ruta.
  static LessonCourse? fromSlug(String slug) =>
      LessonCourse.values.where((c) => c.slug == slug).firstOrNull;
}

/// Los niveles de [course]; `null` mientras se cargan las digitaciones.
List<CourseLevel<CourseStep>>? watchCourseLevels(WidgetRef ref, LessonCourse course) =>
    switch (course) {
      LessonCourse.melodies => melodyCourse,
      LessonCourse.openChords => ref.watch(openChordsCourseProvider),
      LessonCourse.strumming => ref.watch(strummingCourseProvider),
    };

/// Pasos hechos de [course] y cuántos tiene (0 y 0 mientras carga).
(int, int) watchCourseDone(WidgetRef ref, LessonCourse course) {
  final levels = watchCourseLevels(ref, course);
  if (levels == null) return (0, 0);
  final progress = ref.watch(courseProgressProvider(course.progressId));
  final steps = courseSteps(levels);
  return (steps.where(progress.isDone).length, steps.length);
}
