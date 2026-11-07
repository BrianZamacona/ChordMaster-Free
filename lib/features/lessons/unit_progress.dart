import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../courses/course_registry.dart';
import 'lessons_viewmodel.dart';

/// Avance de una unidad del mapa: lecciones terminadas o, si es un curso,
/// pasos hechos; y cuántos tiene (0 de 0 mientras un curso carga).
(int, int) watchUnitProgress(WidgetRef ref, LessonUnit unit) {
  if (unit.course case final course?) return watchCourseDone(ref, course);
  final path = ref.watch(lessonsViewModelProvider.select((s) => s.path));
  final lessons = lessonsOfUnit(unit);
  return (lessons.where(path.isDone).length, lessons.length);
}
