import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/achievement_service.dart';
import '../../services/audio_service.dart';
import '../../services/key_value_store.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Margen para que un toque cuente a tiempo. Con ±150 ms, a 80 BPM tocar al
/// azar acertaba el 40 % de las veces; ±75 ms exige escuchar el pulso.
const rhythmToleranceMs = 75;

/// Toques mínimos para que la sesión cuente como récord (y para el logro):
/// con uno solo bien dado ya salía 100 %.
const rhythmMinTapsForRecord = 16;

/// Result of a single tap attempt: timing offset in milliseconds.
class TapResult {
  const TapResult({required this.offsetMs, required this.timestamp});

  /// Signed offset from the expected beat time (negative = early, positive = late).
  final int offsetMs;
  final DateTime timestamp;

  /// A tiempo: a ±[rhythmToleranceMs] del pulso.
  bool get isAccurate => offsetMs.abs() <= rhythmToleranceMs;
}

/// Immutable state for [RhythmGameViewModel].
class RhythmGameState {
  const RhythmGameState({
    this.bpm = 80,
    this.isRunning = false,
    this.tapResults = const [],
    this.beatCount = 0,
    this.isBeatActive = false,
    this.bestScore = 0,
  });

  final int bpm;
  final bool isRunning;
  final List<TapResult> tapResults;

  /// How many beats have fired since the game started.
  final int beatCount;

  /// True for a brief moment after each beat tick (for visual pulse).
  final bool isBeatActive;

  /// Best accuracy score across sessions (0-100).
  final int bestScore;

  Duration get beatInterval => Duration(milliseconds: (60000 / bpm).round());

  int get tapsCount => tapResults.length;

  /// Precisión 0-100: toques a tiempo entre lo que había que tocar. Los
  /// pulsos que pasaron sin tocar cuentan como fallos, y tocar de más
  /// también resta.
  int get accuracy {
    final expected = max(tapResults.length, beatCount);
    if (expected == 0) return 0;
    final accurate = tapResults.where((r) => r.isAccurate).length;
    return (accurate / expected * 100).round();
  }

  /// La sesión tiene toques suficientes para contar como récord.
  bool get countsForRecord => tapResults.length >= rhythmMinTapsForRecord;

  RhythmGameState copyWith({
    int? bpm,
    bool? isRunning,
    List<TapResult>? tapResults,
    int? beatCount,
    bool? isBeatActive,
    int? bestScore,
  }) =>
      RhythmGameState(
        bpm: bpm ?? this.bpm,
        isRunning: isRunning ?? this.isRunning,
        tapResults: tapResults ?? this.tapResults,
        beatCount: beatCount ?? this.beatCount,
        isBeatActive: isBeatActive ?? this.isBeatActive,
        bestScore: bestScore ?? this.bestScore,
      );
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// Provider for [RhythmGameViewModel].
final rhythmGameViewModelProvider =
    NotifierProvider<RhythmGameViewModel, RhythmGameState>(
        RhythmGameViewModel.new);

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Manages rhythm game state: BPM, beat timer, tap accuracy.
class RhythmGameViewModel extends Notifier<RhythmGameState> {
  static const _keyBestScore = 'rhythm_game_best_score';

  Timer? _beatTimer;
  Timer? _flashTimer;
  DateTime? _lastBeatTime;

  @override
  RhythmGameState build() {
    ref.onDispose(_stopTimers);
    _loadBestScore();
    return const RhythmGameState();
  }

  Future<void> _loadBestScore() async {
    try {
      final storage = ref.read(keyValueStoreProvider);
      final best =
          await storage.get<int>(StorageBoxes.userProgress, _keyBestScore) ?? 0;
      state = state.copyWith(bestScore: best);
    } catch (e, st) {
      debugPrint('RhythmGameViewModel._loadBestScore error: $e\n$st');
    }
  }

  /// Sets the target BPM (20–220).
  void setBpm(int bpm) {
    final clamped = bpm.clamp(20, 220);
    state = state.copyWith(bpm: clamped);
    if (state.isRunning) {
      _stopTimers();
      _startTimers();
    }
  }

  /// Starts the beat clock.
  void start() {
    if (state.isRunning) return;
    state = state.copyWith(
      isRunning: true,
      tapResults: [],
      beatCount: 0,
    );
    _startTimers();
  }

  /// Stops the beat clock and saves the session score.
  Future<void> stop() async {
    _stopTimers();
    final score = state.accuracy;
    state = state.copyWith(isRunning: false);

    if (score > 0 && state.countsForRecord) {
      final newBest = max(score, state.bestScore);
      state = state.copyWith(bestScore: newBest);
      try {
        final storage = ref.read(keyValueStoreProvider);
        await storage.save(
            StorageBoxes.userProgress, _keyBestScore, newBest);
        if (newBest >= 90) {
          await ref.read(achievementServiceProvider).unlock('rhythm_master');
        }
      } catch (e, st) {
        debugPrint('RhythmGameViewModel.stop error: $e\n$st');
      }
    }
  }

  /// Called when the user taps the beat button.
  void tap() {
    if (!state.isRunning || _lastBeatTime == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastBeatTime!).inMilliseconds;
    final beatMs = state.beatInterval.inMilliseconds;
    // Calculate nearest beat offset
    final offsetFromBeat = elapsed % beatMs;
    final signed = offsetFromBeat > beatMs ~/ 2
        ? offsetFromBeat - beatMs
        : offsetFromBeat;

    final result = TapResult(offsetMs: signed, timestamp: now);
    state = state.copyWith(tapResults: [...state.tapResults, result]);
  }

  void _startTimers() {
    _lastBeatTime = DateTime.now();
    _beatTimer = Timer.periodic(state.beatInterval, (_) {
      _lastBeatTime = DateTime.now();
      // El pulso también se oye: clic de metrónomo, acento cada 4 tiempos.
      ref.read(audioServiceProvider).playMetronomeTick(isAccent: state.beatCount % 4 == 0);
      state = state.copyWith(
        beatCount: state.beatCount + 1,
        isBeatActive: true,
      );
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 120), () {
        state = state.copyWith(isBeatActive: false);
      });
    });
  }

  void _stopTimers() {
    _beatTimer?.cancel();
    _beatTimer = null;
    _flashTimer?.cancel();
    _flashTimer = null;
  }
}
