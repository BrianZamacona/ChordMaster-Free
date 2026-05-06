import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

// ── State ────────────────────────────────────────────────────────────────────

/// Result of a single tap attempt: timing offset in milliseconds.
class TapResult {
  const TapResult({required this.offsetMs, required this.timestamp});

  /// Signed offset from the expected beat time (negative = early, positive = late).
  final int offsetMs;
  final DateTime timestamp;

  /// Whether this tap is considered accurate (within ±150 ms).
  bool get isAccurate => offsetMs.abs() <= 150;
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

  /// Accuracy percentage 0-100 for the current session.
  int get accuracy {
    if (tapResults.isEmpty) return 0;
    final accurate = tapResults.where((r) => r.isAccurate).length;
    return ((accurate / tapResults.length) * 100).round();
  }

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
      final storage = ref.read(storageServiceProvider);
      final best =
          await storage.get<int>(StorageService.userProgressBox, _keyBestScore) ?? 0;
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

    if (score > 0) {
      final newBest = max(score, state.bestScore);
      state = state.copyWith(bestScore: newBest);
      try {
        final storage = ref.read(storageServiceProvider);
        await storage.save(
            StorageService.userProgressBox, _keyBestScore, newBest);
        if (newBest >= 90) {
          await AchievementService.instance.unlock('rhythm_master');
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
