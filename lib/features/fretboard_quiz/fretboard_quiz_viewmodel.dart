import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/practice/multi_day_challenges.dart';
import '../../domain/theory/fretboard_quiz.dart';
import '../../services/activity_log.dart';
import '../../services/key_value_store.dart';

/// Estado del quiz del diapasón.
class FretQuizState {
  const FretQuizState({
    required this.question,
    this.selected,
    this.answered = 0,
    this.correct = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.filter = const FretQuizFilter(),
  });

  final FretQuestion question;

  /// Qué se practica (cuerdas, trastes, solo naturales).
  final FretQuizFilter filter;

  /// Lo que se eligió (`null` = sin responder).
  final int? selected;
  final int answered;
  final int correct;
  final int streak;

  /// Mejor racha de todas las sesiones.
  final int bestStreak;

  bool get isAnswered => selected != null;

  FretQuizState copyWith({
    FretQuestion? question,
    int? Function()? selected,
    int? answered,
    int? correct,
    int? streak,
    int? bestStreak,
    FretQuizFilter? filter,
  }) =>
      FretQuizState(
        question: question ?? this.question,
        selected: selected == null ? this.selected : selected(),
        answered: answered ?? this.answered,
        correct: correct ?? this.correct,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        filter: filter ?? this.filter,
      );
}

/// Generador de preguntas (en los tests, con semilla).
final fretQuizRandomProvider = Provider<Random>((ref) => Random());

final fretQuizViewModelProvider =
    NotifierProvider.autoDispose<FretQuizViewModel, FretQuizState>(FretQuizViewModel.new);

/// La mejor racha se guarda en [StorageBoxes.userProgress] y el filtro en
/// [StorageBoxes.settings]; cada respuesta cuenta como día de práctica del
/// diapasón.
class FretQuizViewModel extends Notifier<FretQuizState> {
  static const keyBestStreak = 'fretboard_quiz_best_streak';
  static const keyFilter = 'fretboard_quiz_filter';

  Random get _rng => ref.read(fretQuizRandomProvider);

  @override
  FretQuizState build() {
    _load();
    return FretQuizState(question: nextFretQuestion(_rng));
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final best = await _storage.get<int>(StorageBoxes.userProgress, keyBestStreak) ?? 0;
      final filter = FretQuizFilter.fromJson(await _storage.get<Map>(StorageBoxes.settings, keyFilter));
      if (!ref.mounted) return;
      if (best > state.bestStreak) state = state.copyWith(bestStreak: best);
      // Con un filtro guardado, la primera pregunta se vuelve a sacar dentro
      // de él (si todavía no se respondió).
      if (filter != state.filter && !state.isAnswered) {
        state = state.copyWith(filter: filter, question: nextFretQuestion(_rng, filter));
      }
    } catch (e, st) {
      debugPrint('FretQuizViewModel._load error: $e\n$st');
    }
  }

  Future<void> answer(int choice) async {
    if (state.isAnswered) return;
    unawaited(ref.read(activityLogProvider.notifier).record(PracticeActivity.fretboard));
    final right = state.question.isRight(choice);
    final streak = right ? state.streak + 1 : 0;
    final best = max(streak, state.bestStreak);
    state = state.copyWith(
      selected: () => choice,
      answered: state.answered + 1,
      correct: state.correct + (right ? 1 : 0),
      streak: streak,
      bestStreak: best,
    );
    if (best == streak && right) {
      try {
        await _storage.save(StorageBoxes.userProgress, keyBestStreak, best);
      } catch (e, st) {
        debugPrint('FretQuizViewModel.answer error: $e\n$st');
      }
    }
  }

  void next() => state = state.copyWith(question: nextFretQuestion(_rng, state.filter), selected: () => null);

  /// Cambia qué se practica: saca una pregunta nueva dentro y lo guarda. Un
  /// filtro no válido (sin cuerdas o con menos de cuatro trastes) no se toma.
  Future<void> setFilter(FretQuizFilter filter) async {
    if (!filter.isValid || filter == state.filter) return;
    state = state.copyWith(filter: filter, question: nextFretQuestion(_rng, filter), selected: () => null);
    try {
      await _storage.save(StorageBoxes.settings, keyFilter, filter.toJson());
    } catch (e, st) {
      debugPrint('FretQuizViewModel.setFilter error: $e\n$st');
    }
  }
}
