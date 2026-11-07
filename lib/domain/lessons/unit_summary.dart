/// Lo que contiene una unidad, sacado de sus lecciones: cuánto tarda, cuánto
/// llevas, qué acordes y escalas practica, qué reto la cierra y cuál sigue.
/// Nada se escribe a mano: todo sale del currículo.
library;

import 'curriculum.dart';
import 'lesson.dart';

class UnitSummary {
  UnitSummary(this.unit, {this.completed = const {}})
      : lessons = lessonsOfUnit(unit);

  final LessonUnit unit;
  final List<Lesson> lessons;

  /// Ids de las lecciones terminadas (de todo el camino).
  final Set<String> completed;

  bool isDone(Lesson lesson) => completed.contains(lesson.id);

  int get done => lessons.where(isDone).length;
  bool get finished => done == lessons.length;

  int get minutes => lessons.fold(0, (sum, l) => sum + l.minutes);
  int get minutesDone =>
      lessons.where(isDone).fold(0, (sum, l) => sum + l.minutes);

  /// Acordes de la unidad, sin repetir y en el orden en que aparecen.
  List<String> get chords => {for (final l in lessons) ...l.chords}.toList();

  /// Escalas de la unidad, sin repetir.
  List<LessonScale> get scales {
    final seen = <(String, int)>{};
    return [
      for (final l in lessons)
        if (l.scale case final s? when seen.add((s.scaleId, s.root))) s,
    ];
  }

  /// Notas de tablatura de toda la unidad.
  int get tabNotes => lessons.fold(0, (sum, l) => sum + l.tab.length);

  /// Lecciones con rasgueo.
  int get strumLessons => lessons.where((l) => l.strumPattern != null).length;

  /// Posición de la unidad en su camino y nivel, desde 1, y cuántas hay.
  (int, int) get position {
    final row = unitsOf(unit.track, level: unit.level);
    return (row.indexOf(unit) + 1, row.length);
  }

  /// El reto que se desbloquea al cerrar el nivel: solo en la última unidad
  /// de su nivel (Fundamentos no tiene).
  LessonChallenge? get closingChallenge {
    final (index, total) = position;
    if (index != total) return null;
    return challengesOf(unit.track, level: unit.level).firstOrNull;
  }

  /// La unidad que sigue en el mismo camino (pasando de nivel). Null al final
  /// del camino: lo que sigue a Fundamentos lo elige el usuario en el mapa.
  LessonUnit? get nextUnit {
    final all = unitsOf(unit.track);
    final i = all.indexOf(unit);
    return i + 1 < all.length ? all[i + 1] : null;
  }
}
