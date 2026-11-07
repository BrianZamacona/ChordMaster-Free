import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lessons/lesson.dart';
import 'lessons_viewmodel.dart';

/// Avance de una unidad del mapa: lecciones terminadas o, si es un curso,
/// pasos hechos; y cuántos tiene (0 de 0 mientras un curso carga).
(int, int) watchUnitProgress(WidgetRef ref, LessonUnit unit) =>
    ref.watch(learningPathProvider.select((p) => p.unitProgress(unit)));
