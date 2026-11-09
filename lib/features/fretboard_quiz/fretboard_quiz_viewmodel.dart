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
  });

  final FretQuestion question;

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
  }) =>
      FretQuizState(
        question: question ?? this.question,
        selected: selected == null ? this.selected : selected(),
        answered: answered ?? this.answered,
        correct: correct ?? this.correct,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
      );
}

/// Generador de preguntas (en los tests, con semilla).
final fretQuizRandomProvider = Provider<Random>((ref) => Random());

final fretQuizViewModelProvider =
    NotifierProvider.autoDispose<FretQuizViewModel, FretQuizState>(FretQuizViewModel.new);

/// La mejor racha se guarda en [StorageBoxes.userProgress]; cada respuesta
/// cuenta como día de práctica del diapasón.
class FretQuizViewModel extends Notifier<FretQuizState> {
  static const keyBestStreak = 'fretboard_quiz_best_streak';

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
      if (ref.mounted && best > state.bestStreak) state = state.copyWith(bestStreak: best);
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

  void next() => state = state.copyWith(question: nextFretQuestion(_rng), selected: () => null);
}
