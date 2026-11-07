import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/courses/course.dart';
import '../../services/key_value_store.dart';

/// Cursos de la app, cada uno con sus claves en `userProgress`.
enum CourseId {
  melodies(keyBest: 'melodies_best_bpm', keyRead: 'melodies_read'),
  openChords(keyBest: 'open_chords_best_bpm', keyRead: 'open_chords_read');

  const CourseId({required this.keyBest, required this.keyRead});

  /// Mejor tempo limpio por paso (`{id: bpm}`).
  final String keyBest;

  /// Pasos de teoría leídos (lista de ids).
  final String keyRead;
}

final courseProgressProvider =
    NotifierProvider.family<CourseProgressViewModel, CourseProgress, CourseId>(
      CourseProgressViewModel.new,
    );

class CourseProgressViewModel extends Notifier<CourseProgress> {
  CourseProgressViewModel(this.course);

  final CourseId course;

  @override
  CourseProgress build() {
    _load();
    return const CourseProgress();
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final best = await _storage.get<Map<dynamic, dynamic>>(
            StorageBoxes.userProgress,
            course.keyBest,
          ) ??
          const {};
      final read = await _storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            course.keyRead,
          ) ??
          const [];
      state = CourseProgress(
        best: {
          for (final MapEntry(:key, :value) in best.entries)
            if (key is String && value is int) key: value,
          ...state.best,
        },
        read: {...read.whereType<String>(), ...state.read},
      );
    } catch (e, st) {
      debugPrint('CourseProgressViewModel._load error: $e\n$st');
    }
  }

  /// "Me salió limpio a [bpm]": guarda el tempo si supera el mejor.
  Future<void> saveClean(String stepId, int bpm) async {
    final current = state.best[stepId];
    if (current != null && current >= bpm) return;
    final best = {...state.best, stepId: bpm};
    state = state.copyWith(best: best);
    try {
      await _storage.save(StorageBoxes.userProgress, course.keyBest, best);
    } catch (e, st) {
      debugPrint('CourseProgressViewModel.saveClean error: $e\n$st');
    }
  }

  /// Marca un paso de teoría como leído o, si ya lo estaba, como pendiente.
  Future<void> toggleRead(String stepId) async {
    final read = {...state.read};
    if (!read.remove(stepId)) read.add(stepId);
    state = state.copyWith(read: read);
    try {
      await _storage.save(
        StorageBoxes.userProgress,
        course.keyRead,
        read.toList()..sort(),
      );
    } catch (e, st) {
      debugPrint('CourseProgressViewModel.toggleRead error: $e\n$st');
    }
  }
}
