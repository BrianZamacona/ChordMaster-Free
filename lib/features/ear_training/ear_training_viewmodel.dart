import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/audio/pluck_synth.dart' show NoteEvent;
import '../../domain/theory/notes.dart';
import '../../models/interval_model.dart';
import '../../services/achievement_service.dart';
import '../../services/audio_service.dart';
import '../../services/storage_service.dart';

/// The set of intervals used in ear training (semitones 1-12 only).
final List<IntervalModel> _trainingIntervals = defaultIntervals
    .where((m) => (m['semitones'] as int) >= 1 && (m['semitones'] as int) <= 12)
    .map((m) => IntervalModel.fromJson(Map<String, dynamic>.from(m)))
    .toList();

/// Notas MIDI posibles para la nota grave (C3 a C4): con la octava, la aguda
/// no pasa de C5.
const earRootMidiRange = (low: 48, high: 60);

/// Cómo suena el intervalo: melódico (grave y luego aguda, a 0.8 s) o
/// armónico (las dos a la vez, con un rasgueo mínimo).
List<NoteEvent> intervalEvents(int rootMidi, int semitones, {bool harmonic = false}) => [
  (midi: rootMidi, at: 0),
  (midi: rootMidi + semitones, at: harmonic ? 0.03 : 0.8),
];

// ── State ────────────────────────────────────────────────────────────────────

/// Immutable state for [EarTrainingViewModel].
class EarTrainingState {
  const EarTrainingState({
    required this.currentInterval,
    required this.choices,
    this.totalAnswered = 0,
    this.correctAnswers = 0,
    this.streak = 0,
    this.lastAnswerCorrect,
    this.isLoading = true,
    this.totalExercisesDone = 0,
    this.rootMidi = 60,
    this.harmonic = false,
  });

  /// Nota grave del intervalo (cambia en cada pregunta).
  final int rootMidi;

  /// `true` = las dos notas a la vez.
  final bool harmonic;

  /// The interval the user needs to identify.
  final IntervalModel currentInterval;

  /// Four choices displayed to the user (includes the correct one).
  final List<IntervalModel> choices;

  final int totalAnswered;
  final int correctAnswers;
  final int streak;

  /// `null` = question not answered yet; `true`/`false` = last result.
  final bool? lastAnswerCorrect;

  final bool isLoading;

  /// Cumulative exercises completed (across sessions, for achievement tracking).
  final int totalExercisesDone;

  double get accuracy =>
      totalAnswered == 0 ? 0 : correctAnswers / totalAnswered;

  EarTrainingState copyWith({
    IntervalModel? currentInterval,
    List<IntervalModel>? choices,
    int? totalAnswered,
    int? correctAnswers,
    int? streak,
    Object? lastAnswerCorrect = _unset,
    bool? isLoading,
    int? totalExercisesDone,
    int? rootMidi,
    bool? harmonic,
  }) =>
      EarTrainingState(
        currentInterval: currentInterval ?? this.currentInterval,
        choices: choices ?? this.choices,
        totalAnswered: totalAnswered ?? this.totalAnswered,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        streak: streak ?? this.streak,
        lastAnswerCorrect: identical(lastAnswerCorrect, _unset)
            ? this.lastAnswerCorrect
            : lastAnswerCorrect as bool?,
        isLoading: isLoading ?? this.isLoading,
        totalExercisesDone: totalExercisesDone ?? this.totalExercisesDone,
        rootMidi: rootMidi ?? this.rootMidi,
        harmonic: harmonic ?? this.harmonic,
      );

  static const Object _unset = Object();
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provider for [EarTrainingViewModel].
final earTrainingViewModelProvider =
    NotifierProvider<EarTrainingViewModel, EarTrainingState>(
        EarTrainingViewModel.new);

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Manages ear training quiz state.
class EarTrainingViewModel extends Notifier<EarTrainingState> {
  static const _keyTotalExercises = 'ear_training_total';
  final _rng = Random();

  @override
  EarTrainingState build() {
    final initial = _buildQuestion(
      totalAnswered: 0,
      correctAnswers: 0,
      streak: 0,
      totalExercisesDone: 0,
      harmonic: false,
    );
    _loadCount(initial);
    return initial;
  }

  Future<void> _loadCount(EarTrainingState initial) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final count = await storage.get<int>(
            StorageService.userProgressBox, _keyTotalExercises) ??
          0;
      state = state.copyWith(totalExercisesDone: count, isLoading: false);
    } catch (e, st) {
      debugPrint('EarTrainingViewModel._loadCount error: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  EarTrainingState _buildQuestion({
    required int totalAnswered,
    required int correctAnswers,
    required int streak,
    required int totalExercisesDone,
    required bool harmonic,
  }) {
    final correct = _trainingIntervals[_rng.nextInt(_trainingIntervals.length)];
    final choices = _generateChoices(correct);
    return EarTrainingState(
      rootMidi: earRootMidiRange.low +
          _rng.nextInt(earRootMidiRange.high - earRootMidiRange.low + 1),
      harmonic: harmonic,
      currentInterval: correct,
      choices: choices,
      totalAnswered: totalAnswered,
      correctAnswers: correctAnswers,
      streak: streak,
      totalExercisesDone: totalExercisesDone,
      isLoading: false,
    );
  }

  List<IntervalModel> _generateChoices(IntervalModel correct) {
    final pool = List<IntervalModel>.from(_trainingIntervals)
      ..removeWhere((i) => i.semitones == correct.semitones);
    pool.shuffle(_rng);
    final distractors = pool.take(3).toList();
    final all = [correct, ...distractors]..shuffle(_rng);
    return all;
  }

  /// Interprets the user's answer [selectedInterval].
  Future<void> answer(IntervalModel selectedInterval) async {
    if (state.lastAnswerCorrect != null) return; // already answered

    final isCorrect = selectedInterval.semitones == state.currentInterval.semitones;
    final newCorrect = state.correctAnswers + (isCorrect ? 1 : 0);
    final newStreak = isCorrect ? state.streak + 1 : 0;
    final newTotal = state.totalAnswered + 1;
    final newExercisesDone = state.totalExercisesDone + 1;

    state = state.copyWith(
      totalAnswered: newTotal,
      correctAnswers: newCorrect,
      streak: newStreak,
      lastAnswerCorrect: isCorrect,
      totalExercisesDone: newExercisesDone,
    );

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.save(
        StorageService.userProgressBox,
        _keyTotalExercises,
        newExercisesDone,
      );
      if (newExercisesDone >= 20) {
        await AchievementService.instance.unlock('ear_wizard');
      }
    } catch (e, st) {
      debugPrint('EarTrainingViewModel.answer error: $e\n$st');
    }
  }

  /// Pasa a la siguiente pregunta y la hace sonar.
  void nextQuestion() {
    state = _buildQuestion(
      totalAnswered: state.totalAnswered,
      correctAnswers: state.correctAnswers,
      streak: state.streak,
      totalExercisesDone: state.totalExercisesDone,
      harmonic: state.harmonic,
    );
    play();
  }

  /// Hace sonar el intervalo de la pregunta actual.
  Future<void> play() => ref.read(audioServiceProvider).playNotes(
        intervalEvents(
          state.rootMidi,
          state.currentInterval.semitones,
          harmonic: state.harmonic,
        ),
      );

  /// Melódico o armónico; vuelve a sonar con el modo nuevo.
  void setHarmonic({required bool harmonic}) {
    if (harmonic == state.harmonic) return;
    state = state.copyWith(harmonic: harmonic);
    play();
  }

  /// Nota grave de la pregunta (con sostenidos).
  String get displayRootNote => pitchClassName(state.rootMidi);

  /// Nota aguda de la pregunta.
  String get displayIntervalNote =>
      pitchClassName(state.rootMidi + state.currentInterval.semitones);
}

