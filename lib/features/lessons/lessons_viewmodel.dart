import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../domain/practice/multi_day_challenges.dart';
import '../../services/achievement_service.dart';
import '../../services/activity_log.dart';
import '../../services/key_value_store.dart';

/// Estado de la pantalla de lecciones.
class LessonsState {
  LessonsState({
    Set<String> completed = const {},
    this.chosen = LessonTrack.rhythm,
    this.hasChosen = false,
    this.isLoading = true,
  }) : path = LessonPath(completed: completed, chosen: chosen);

  final LessonPath path;
  final LessonTrack chosen;

  /// Si el usuario tocó un camino; si no, [chosen] es solo el de por defecto.
  final bool hasChosen;
  final bool isLoading;

  /// Camino que el mapa resalta: ninguno hasta que toque decidir, es decir,
  /// hasta terminar Fundamentos o elegir uno antes.
  LessonTrack? get highlightedTrack =>
      path.foundationsDone || hasChosen ? chosen : null;

  LessonsState copyWith({
    Set<String>? completed,
    LessonTrack? chosen,
    bool? hasChosen,
    bool? isLoading,
  }) =>
      LessonsState(
        completed: completed ?? path.completed,
        chosen: chosen ?? this.chosen,
        hasChosen: hasChosen ?? this.hasChosen,
        isLoading: isLoading ?? this.isLoading,
      );
}

final lessonsViewModelProvider =
    NotifierProvider<LessonsViewModel, LessonsState>(LessonsViewModel.new);

/// Lecciones terminadas y camino elegido, guardados en
/// [StorageBoxes.userProgress]. Al terminar Fundamentos desbloquea el logro
/// `foundations_done`.
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
    final completed = {...state.path.completed};
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
      if (state.path.foundationsDone) {
        await ref.read(achievementServiceProvider).unlock('foundations_done');
      }
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
