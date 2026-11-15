import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/practice/multi_day_challenges.dart';
import '../../domain/theory/fretboard_quiz.dart';
import '../../domain/theory/fretboard_round.dart';
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
    this.round,
    this.lastRound,
    this.lastRoundRecord = false,
    this.bestRound = 0,
  });

  /// La ronda con reloj en curso (`null` = práctica libre).
  final FretRound? round;

  /// La última ronda terminada, para el resultado.
  final FretRound? lastRound;

  /// Si [lastRound] batió el récord.
  final bool lastRoundRecord;

  /// Mejor ronda de todas las sesiones (puntos).
  final int bestRound;

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
    FretRound? Function()? round,
    FretRound? Function()? lastRound,
    bool? lastRoundRecord,
    int? bestRound,
  }) =>
      FretQuizState(
        question: question ?? this.question,
        selected: selected == null ? this.selected : selected(),
        answered: answered ?? this.answered,
        correct: correct ?? this.correct,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        filter: filter ?? this.filter,
        round: round == null ? this.round : round(),
        lastRound: lastRound == null ? this.lastRound : lastRound(),
        lastRoundRecord: lastRoundRecord ?? this.lastRoundRecord,
        bestRound: bestRound ?? this.bestRound,
      );
}

/// Generador de preguntas (en los tests, con semilla).
final fretQuizRandomProvider = Provider<Random>((ref) => Random());

final fretQuizViewModelProvider =
    NotifierProvider.autoDispose<FretQuizViewModel, FretQuizState>(FretQuizViewModel.new);

/// La mejor racha y la mejor ronda se guardan en [StorageBoxes.userProgress]
/// y el filtro en [StorageBoxes.settings]; cada respuesta cuenta como día de
/// práctica del diapasón.
class FretQuizViewModel extends Notifier<FretQuizState> {
  static const keyBestStreak = 'fretboard_quiz_best_streak';
  static const keyBestRound = 'fretboard_quiz_best_round';
  static const keyFilter = 'fretboard_quiz_filter';

  Random get _rng => ref.read(fretQuizRandomProvider);

  /// El reloj de la ronda: un segundo por tic.
  Timer? _clock;

  @override
  FretQuizState build() {
    ref.onDispose(() => _clock?.cancel());
    _load();
    return FretQuizState(question: nextFretQuestion(_rng));
  }

  KeyValueStore get _storage => ref.read(keyValueStoreProvider);

  Future<void> _load() async {
    try {
      final best = await _storage.get<int>(StorageBoxes.userProgress, keyBestStreak) ?? 0;
      final bestRound = await _storage.get<int>(StorageBoxes.userProgress, keyBestRound) ?? 0;
      final filter = FretQuizFilter.fromJson(await _storage.get<Map>(StorageBoxes.settings, keyFilter));
      if (!ref.mounted) return;
      if (best > state.bestStreak) state = state.copyWith(bestStreak: best);
      if (bestRound > state.bestRound) state = state.copyWith(bestRound: bestRound);
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
    if (state.isAnswered || (state.round?.isOver ?? false)) return;
    unawaited(ref.read(activityLogProvider.notifier).record(PracticeActivity.fretboard));
    final right = state.question.isRight(choice);
    final streak = right ? state.streak + 1 : 0;
    final best = max(streak, state.bestStreak);
    final round = state.round;
    state = state.copyWith(
      // En la ronda no hay pausa: la siguiente sale al responder.
      question: round == null ? null : nextFretQuestion(_rng, state.filter),
      selected: () => round == null ? choice : null,
      round: round == null ? null : () => round.answer(state.question, choice),
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

  /// Empieza una ronda de [fretRoundSeconds] con una pregunta nueva.
  void startRound() {
    _clock?.cancel();
    state = state.copyWith(
      question: nextFretQuestion(_rng, state.filter),
      selected: () => null,
      round: () => const FretRound(),
      lastRound: () => null,
      lastRoundRecord: false,
    );
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final round = state.round?.tick();
    if (round == null) return;
    if (round.isOver) {
      _finishRound(round);
    } else {
      state = state.copyWith(round: () => round);
    }
  }

  /// Fin de la ronda: guarda el récord si lo bate y vuelve a la práctica
  /// libre con una pregunta nueva.
  Future<void> _finishRound(FretRound round) async {
    _clock?.cancel();
    final record = isRoundRecord(round.score, state.bestRound);
    state = state.copyWith(
      question: nextFretQuestion(_rng, state.filter),
      selected: () => null,
      round: () => null,
      lastRound: () => round,
      lastRoundRecord: record,
      bestRound: record ? round.score : null,
    );
    if (!record) return;
    try {
      await _storage.save(StorageBoxes.userProgress, keyBestRound, round.score);
    } catch (e, st) {
      debugPrint('FretQuizViewModel._finishRound error: $e\n$st');
    }
  }

  /// Deja la ronda sin terminar (no cuenta para el récord).
  void stopRound() {
    _clock?.cancel();
    state = state.copyWith(round: () => null, selected: () => null, question: nextFretQuestion(_rng, state.filter));
  }

  /// Cierra el resultado de la última ronda.
  void dismissRoundResult() => state = state.copyWith(lastRound: () => null, lastRoundRecord: false);

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
