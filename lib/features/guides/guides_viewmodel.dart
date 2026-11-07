import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/guides/guide_progress.dart';
import '../../domain/guides/guides.dart';
import '../../services/key_value_store.dart';
import '../lessons/lessons_viewmodel.dart';

/// Capítulos de guía marcados a mano ([chapterKey]), guardados en
/// [StorageBoxes.userProgress].
final guideChecksProvider =
    NotifierProvider<GuideChecksViewModel, Set<String>>(GuideChecksViewModel.new);

/// Progreso de las guías: las marcas más las lecciones terminadas.
final guideProgressProvider = Provider<GuideProgress>(
  (ref) => GuideProgress(
    checked: ref.watch(guideChecksProvider),
    lessonsCompleted: ref.watch(lessonsViewModelProvider).path.completed,
  ),
);

class GuideChecksViewModel extends Notifier<Set<String>> {
  static const keyChecked = 'guides_chapters_done';

  @override
  Set<String> build() {
    _load();
    return const {};
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final raw = await _storage.get<List<dynamic>>(
            StorageBoxes.userProgress,
            keyChecked,
          ) ??
          const [];
      state = {...state, ...raw.whereType<String>()};
    } catch (e, st) {
      debugPrint('GuideChecksViewModel._load error: $e\n$st');
    }
  }

  /// Marca o desmarca un capítulo. El de una lección marca la lección, que es
  /// la única fuente de si está hecha.
  Future<void> toggle(Guide guide, int index) async {
    if (guide.chapters[index].target case LessonLink(:final lessonId)) {
      await ref.read(lessonsViewModelProvider.notifier).toggleCompleted(lessonId);
      return;
    }
    final key = chapterKey(guide, index);
    final next = {...state};
    if (!next.remove(key)) next.add(key);
    state = next;
    try {
      await _storage.save(
        StorageBoxes.userProgress,
        keyChecked,
        next.toList()..sort(),
      );
    } catch (e, st) {
      debugPrint('GuideChecksViewModel.toggle error: $e\n$st');
    }
  }
}
