import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/practice/multi_day_challenges.dart';
import '../../domain/theory/circle_quiz.dart';
import '../../services/achievement_service.dart';
import '../../services/activity_log.dart';
import '../../services/key_value_store.dart';

/// Racha que da el logro del círculo.
const circleQuizAchievementStreak = 10;

class CircleQuizState {
  const CircleQuizState({
    required this.question,
    this.selected,
    this.answered = 0,
    this.correct = 0,
    this.streak = 0,
    this.bestStreak = 0,
  });

  final CircleQuestion question;

  /// Lo que se eligió (`null` = sin responder).
  final int? selected;
  final int answered;
  final int correct;
  final int streak;

  /// Mejor racha de todas las sesiones (la usa el reto del círculo).
  final int bestStreak;

  bool get isAnswered => selected != null;

  CircleQuizState copyWith({
    CircleQuestion? question,
    int? Function()? selected,
    int? answered,
    int? correct,
    int? streak,
    int? bestStreak,
  }) => CircleQuizState(
    question: question ?? this.question,
    selected: selected == null ? this.selected : selected(),
    answered: answered ?? this.answered,
    correct: correct ?? this.correct,
    streak: streak ?? this.streak,
    bestStreak: bestStreak ?? this.bestStreak,
  );
}

/// Generador de preguntas (en los tests, con semilla).
final circleQuizRandomProvider = Provider<Random>((ref) => Random());

final circleQuizViewModelProvider =
    NotifierProvider.autoDispose<CircleQuizViewModel, CircleQuizState>(CircleQuizViewModel.new);

/// La mejor racha va en [StorageBoxes.userProgress]; cada respuesta cuenta como
/// día de práctica, y una racha de [circleQuizAchievementStreak] da el logro.
class CircleQuizViewModel extends Notifier<CircleQuizState> {
  static const keyBestStreak = 'circle_quiz_best_streak';
  static const achievementId = 'circle_master';

  Random get _rng => ref.read(circleQuizRandomProvider);
  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  @override
  CircleQuizState build() {
    _load();
    return CircleQuizState(question: nextCircleQuestion(_rng));
  }

  Future<void> _load() async {
    try {
      final best = await _storage.get<int>(StorageBoxes.userProgress, keyBestStreak) ?? 0;
      if (ref.mounted && best > state.bestStreak) state = state.copyWith(bestStreak: best);
    } catch (e, st) {
      debugPrint('CircleQuizViewModel._load error: $e\n$st');
    }
  }

  Future<void> answer(int choice) async {
    if (state.isAnswered) return;
    unawaited(ref.read(activityLogProvider.notifier).record(PracticeActivity.circle));
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
    if (!right || streak < best) return;
    try {
      await _storage.save(StorageBoxes.userProgress, keyBestStreak, best);
      if (best >= circleQuizAchievementStreak) {
        await ref.read(achievementServiceProvider).unlock(achievementId);
      }
    } catch (e, st) {
      debugPrint('CircleQuizViewModel.answer error: $e\n$st');
    }
  }

  void next() => state = state.copyWith(question: nextCircleQuestion(_rng), selected: () => null);
}
