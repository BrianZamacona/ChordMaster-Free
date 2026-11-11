import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../circle/circle_quiz_viewmodel.dart';
import '../ear_training/ear_training_viewmodel.dart';
import '../rhythm_games/rhythm_game_viewmodel.dart';

/// Récord actual de un reto, la ruta del módulo que lo mide y el texto de
/// avance ("Récord: 70 % de 85 %"). Lo usan el mapa y la pantalla de unidad.
({int best, String route, String status, bool passed}) challengeProgress(
  WidgetRef ref,
  LessonChallenge challenge,
) {
  final (best, route, label) = switch (challenge.kind) {
    ChallengeKind.rhythmAccuracy => (
        ref.watch(rhythmGameViewModelProvider.select((s) => s.bestScore)),
        '/practice/rhythm',
        AppStrings.challengeRhythmBest,
      ),
    ChallengeKind.earStreak => (
        ref.watch(earTrainingViewModelProvider.select((s) => s.bestStreak)),
        '/practice/ear-training',
        AppStrings.challengeEarBest,
      ),
    ChallengeKind.circleStreak => (
        ref.watch(circleQuizViewModelProvider.select((s) => s.bestStreak)),
        '/learn/circle/quiz',
        AppStrings.challengeEarBest,
      ),
  };
  final passed = challenge.isPassed(best);
  return (
    best: best,
    route: route,
    status: passed ? AppStrings.challengePassed : label(best, challenge.goal),
    passed: passed,
  );
}
