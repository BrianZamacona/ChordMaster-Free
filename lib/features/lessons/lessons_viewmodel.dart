import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../domain/practice/multi_day_challenges.dart';
import '../../services/achievement_service.dart';
import '../../services/activity_log.dart';
import '../../services/key_value_store.dart';
import '../courses/course_registry.dart';

/// Lecciones terminadas y camino elegido. El camino completo (con los cursos)
/// lo arma [learningPathProvider].
class LessonsState {
  LessonsState({
    Set<String> completed = const {},
    this.chosen = LessonTrack.rhythm,
    this.hasChosen = false,
    this.isLoading = true,
  }) : completed = {
          for (final id in completed)
            if (lessonsById.containsKey(id)) id,
        };

  /// Ids terminados que siguen existiendo en el currículo.
  final Set<String> completed;
  final LessonTrack chosen;

  /// Si el usuario tocó un camino; si no, [chosen] es solo el de por defecto.
  final bool hasChosen;
  final bool isLoading;

  LessonsState copyWith({
    Set<String>? completed,
    LessonTrack? chosen,
    bool? hasChosen,
    bool? isLoading,
  }) =>
      LessonsState(
        completed: completed ?? this.completed,
        chosen: chosen ?? this.chosen,
        hasChosen: hasChosen ?? this.hasChosen,
        isLoading: isLoading ?? this.isLoading,
      );
}

/// El camino: lecciones terminadas más los pasos hechos de cada curso. Se
/// recalcula cuando cambia una fuente (`ref.listen`), no al dibujar: así una
/// pestaña oculta que vuelve no dispara recálculos en cadena durante el build.
final learningPathProvider =
    NotifierProvider<LearningPathNotifier, LessonPath>(LearningPathNotifier.new);

class LearningPathNotifier extends Notifier<LessonPath> {
  @override
  LessonPath build() {
    ref.listen(lessonsViewModelProvider, (_, _) => state = _compute());
    for (final course in LessonCourse.values) {
      for (final source in courseSources(course)) {
        ref.listen(source, (_, _) => state = _compute());
      }
    }
    return _compute();
  }

  LessonPath _compute() {
    final lessons = ref.read(lessonsViewModelProvider);
    return LessonPath(
      completed: lessons.completed,
      chosen: lessons.chosen,
      courses: {
        for (final course in LessonCourse.values)
          course: ?courseDone(ref.read, course),
      },
    );
  }
}

/// Al terminar Fundamentos (lecciones o cursos) se desbloquea el logro
/// `foundations_done`. La raíz de la app lo escucha: así nadie que guarde
/// avance tiene que acordarse.
void unlockFoundationsWhenDone(WidgetRef ref) {
  ref.listen(foundationsDoneProvider, (_, done) {
    if (done) ref.read(achievementServiceProvider).unlock('foundations_done');
  });
}

/// Si Fundamentos está terminado. Solo mira sus unidades (sus cursos no
/// dependen de `chords.json`), así escucharlo desde el arranque no carga los
/// acordes. Como [learningPathProvider], se recalcula por avisos.
final foundationsDoneProvider =
    NotifierProvider<FoundationsDoneNotifier, bool>(FoundationsDoneNotifier.new);

class FoundationsDoneNotifier extends Notifier<bool> {
  static final _courses = {
    for (final u in unitsOf(LessonTrack.foundations)) ?u.course,
  };

  @override
  bool build() {
    ref.listen(lessonsViewModelProvider, (_, _) => state = _compute());
    for (final course in _courses) {
      for (final source in courseSources(course)) {
        ref.listen(source, (_, _) => state = _compute());
      }
    }
    return _compute();
  }

  bool _compute() {
    final lessons = ref.read(lessonsViewModelProvider);
    return LessonPath(
      completed: lessons.completed,
      chosen: lessons.chosen,
      courses: {for (final c in _courses) c: ?courseDone(ref.read, c)},
    ).foundationsDone;
  }
}

/// Camino que el mapa resalta: ninguno hasta que toque decidir, es decir,
/// hasta terminar Fundamentos o elegir uno antes.
LessonTrack? highlightedTrackOf(LessonsState state, {required bool foundationsDone}) =>
    foundationsDone || state.hasChosen ? state.chosen : null;

LessonTrack? watchHighlightedTrack(WidgetRef ref) => highlightedTrackOf(
  ref.watch(lessonsViewModelProvider),
  foundationsDone: ref.watch(foundationsDoneProvider),
);

final lessonsViewModelProvider =
    NotifierProvider<LessonsViewModel, LessonsState>(LessonsViewModel.new);

/// Lecciones terminadas y camino elegido, guardados en
/// [StorageBoxes.userProgress].
class LessonsViewModel extends Notifier<LessonsState> {
  static const keyCompleted = 'lessons_completed';
  static const keyTrack = 'lessons_track';

  @override
  LessonsState build() {
    _load();
    return LessonsState();
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final raw = await _storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            keyCompleted,
          ) ??
          const [];
      final trackName =
          await _storage.get<String>(StorageBoxes.userProgress, keyTrack);
      final chosen = switch (trackName) {
        'lead' => LessonTrack.lead,
        _ => LessonTrack.rhythm,
      };
      state = LessonsState(
        completed: raw.whereType<String>().toSet(),
        chosen: chosen,
        hasChosen: trackName != null,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('LessonsViewModel._load error: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Marca [lessonId] como terminada o, si ya lo estaba, como pendiente.
  Future<void> toggleCompleted(String lessonId) async {
    final completed = {...state.completed};
    final nowDone = !completed.remove(lessonId);
    if (nowDone) completed.add(lessonId);
    state = state.copyWith(completed: completed);
    if (nowDone) {
      unawaited(ref.read(activityLogProvider.notifier).record(PracticeActivity.lessons));
    }
    try {
      await _storage.save(
        StorageBoxes.userProgress,
        keyCompleted,
        completed.toList()..sort(),
      );
    } catch (e, st) {
      debugPrint('LessonsViewModel.toggleCompleted error: $e\n$st');
    }
  }

  /// Elige el camino que sigue a Fundamentos.
  Future<void> choose(LessonTrack track) async {
    if (track == LessonTrack.foundations) return;
    if (state.hasChosen && track == state.chosen) return;
    state = state.copyWith(chosen: track, hasChosen: true);
    try {
      await _storage.save(StorageBoxes.userProgress, keyTrack, track.name);
    } catch (e, st) {
      debugPrint('LessonsViewModel.choose error: $e\n$st');
    }
  }
}
