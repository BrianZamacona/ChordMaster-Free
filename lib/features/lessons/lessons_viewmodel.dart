import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../services/achievement_service.dart';
import '../../services/key_value_store.dart';

/// Estado de la pantalla de lecciones.
class LessonsState {
  LessonsState({
    Set<String> completed = const {},
    this.chosen = LessonTrack.rhythm,
    this.isLoading = true,
  }) : path = LessonPath(completed: completed, chosen: chosen);

  final LessonPath path;
  final LessonTrack chosen;
  final bool isLoading;

  LessonsState copyWith({
    Set<String>? completed,
    LessonTrack? chosen,
    bool? isLoading,
  }) =>
      LessonsState(
        completed: completed ?? path.completed,
        chosen: chosen ?? this.chosen,
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
    if (!completed.remove(lessonId)) completed.add(lessonId);
    state = state.copyWith(completed: completed);
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
    if (track == LessonTrack.foundations || track == state.chosen) return;
    state = state.copyWith(chosen: track);
    try {
      await _storage.save(StorageBoxes.userProgress, keyTrack, track.name);
    } catch (e, st) {
      debugPrint('LessonsViewModel.choose error: $e\n$st');
    }
  }
}
