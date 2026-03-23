import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio_service.dart';

/// State for [MetronomeViewModel].
class MetronomeState {
  /// Current BPM (20–300).
  final int bpm;

  /// Active time signature, e.g. "4/4".
  final String timeSignature;

  /// Active subdivision: quarter / eighth / sixteenth / triplet.
  final String subdivision;

  /// Whether the metronome is currently ticking.
  final bool isPlaying;

  /// Current beat index (0-indexed).
  final int currentBeat;

  /// Total beats per bar (numerator of time signature).
  final int totalBeats;

  const MetronomeState({
    this.bpm = 120,
    this.timeSignature = '4/4',
    this.subdivision = 'quarter',
    this.isPlaying = false,
    this.currentBeat = 0,
    this.totalBeats = 4,
  });

  /// Creates a copy with the given fields replaced.
  MetronomeState copyWith({
    int? bpm,
    String? timeSignature,
    String? subdivision,
    bool? isPlaying,
    int? currentBeat,
    int? totalBeats,
  }) =>
      MetronomeState(
        bpm: bpm ?? this.bpm,
        timeSignature: timeSignature ?? this.timeSignature,
        subdivision: subdivision ?? this.subdivision,
        isPlaying: isPlaying ?? this.isPlaying,
        currentBeat: currentBeat ?? this.currentBeat,
        totalBeats: totalBeats ?? this.totalBeats,
      );
}

/// ViewModel for the Metronome feature.
class MetronomeViewModel extends StateNotifier<MetronomeState> {
  MetronomeViewModel() : super(const MetronomeState());

  Timer? _timer;
  final List<DateTime> _taps = [];

  // Subdivision multiplier map.
  static const Map<String, double> _multipliers = {
    'quarter': 1,
    'eighth': 2,
    'sixteenth': 4,
    'triplet': 3,
  };

  /// Interval in milliseconds for one tick.
  int get _tickInterval {
    final mult = _multipliers[state.subdivision] ?? 1;
    return (60000 / state.bpm / mult).round();
  }

  /// Starts the metronome with drift compensation.
  void startMetronome() {
    if (state.isPlaying) return;
    state = state.copyWith(isPlaying: true, currentBeat: 0);
    _scheduleNext();
  }

  int _beat = 0;
  DateTime? _nextTick;

  void _scheduleNext() {
    _nextTick ??= DateTime.now();
    _nextTick = _nextTick!.add(Duration(milliseconds: _tickInterval));
    final delay = _nextTick!.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, _onTick);
  }

  void _onTick() {
    if (!state.isPlaying) return;
    final isAccent = _beat == 0;
    AudioService.instance.playMetronomeTick(isAccent: isAccent);
    state = state.copyWith(currentBeat: _beat);
    _beat = (_beat + 1) % state.totalBeats;
    _scheduleNext();
  }

  /// Stops the metronome.
  void stopMetronome() {
    _timer?.cancel();
    _timer = null;
    _nextTick = null;
    _beat = 0;
    state = state.copyWith(isPlaying: false, currentBeat: 0);
  }

  /// Records a tap and recalculates BPM from last 4 taps.
  void tapTempo(DateTime tapTime) {
    _taps.add(tapTime);
    if (_taps.length > 4) _taps.removeAt(0);
    if (_taps.length >= 2) {
      final intervals = <int>[];
      for (var i = 1; i < _taps.length; i++) {
        intervals.add(_taps[i].difference(_taps[i - 1]).inMilliseconds);
      }
      final avg = intervals.reduce((a, b) => a + b) / intervals.length;
      final newBpm = (60000 / avg).round().clamp(20, 300);
      setBpm(newBpm);
    }
  }

  /// Sets BPM, clamped to [20, 300].
  void setBpm(int bpm) {
    final clamped = bpm.clamp(20, 300);
    state = state.copyWith(bpm: clamped);
    if (state.isPlaying) {
      stopMetronome();
      startMetronome();
    }
  }

  /// Sets the time signature (e.g. "5/4").
  void setTimeSignature(String ts) {
    final parts = ts.split('/');
    final beats = int.tryParse(parts.first) ?? 4;
    state = state.copyWith(timeSignature: ts, totalBeats: beats, currentBeat: 0);
    _beat = 0;
    if (state.isPlaying) {
      stopMetronome();
      startMetronome();
    }
  }

  /// Sets the subdivision.
  void setSubdivision(String sub) {
    state = state.copyWith(subdivision: sub);
    if (state.isPlaying) {
      stopMetronome();
      startMetronome();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for [MetronomeViewModel].
final metronomeViewModelProvider =
    StateNotifierProvider<MetronomeViewModel, MetronomeState>(
  (ref) => MetronomeViewModel(),
);
