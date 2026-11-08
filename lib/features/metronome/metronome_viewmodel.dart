import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio_service.dart';

/// State for [MetronomeViewModel].
class MetronomeState {

  const MetronomeState({
    this.bpm = 120,
    this.timeSignature = '4/4',
    this.subdivision = 'quarter',
    this.isPlaying = false,
    this.currentBeat = 0,
    this.totalBeats = 4,
  });
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

/// El metrónomo. El sonido es un bucle sintetizado con el tiempo exacto
/// (`AudioService.startMetronome`); aquí solo se lleva la cuenta de los
/// tiempos para la pantalla, con el reloj desde que empezó a sonar.
class MetronomeViewModel extends Notifier<MetronomeState> {
  @override
  MetronomeState build() {
    _audio = ref.read(audioServiceProvider);
    ref.onDispose(() {
      _cancelTimers();
      _audio.stopMetronome();
    });
    return const MetronomeState();
  }

  late AudioService _audio;
  Timer? _beatTimer;
  Timer? _restart;
  final _clock = Stopwatch();

  /// Cuenta cada arranque o parada: un arranque que termina de cargar
  /// después de otra orden ya no cuenta.
  int _order = 0;
  final List<DateTime> _taps = [];

  /// Tras un cambio de tempo, compás o subdivisión sonando, cuánto se
  /// espera a que deje de cambiar (p. ej. al arrastrar el deslizador) antes
  /// de volver a arrancar el sonido.
  static const restartDelay = Duration(milliseconds: 200);

  /// Clics por tiempo de cada subdivisión.
  static const Map<String, int> clicksPerBeat = {
    'quarter': 1,
    'eighth': 2,
    'triplet': 3,
    'sixteenth': 4,
  };

  void startMetronome() {
    if (state.isPlaying) return;
    state = state.copyWith(isPlaying: true, currentBeat: 0);
    _begin();
  }

  Future<void> _begin() async {
    final order = ++_order;
    _cancelTimers();
    await _audio.startMetronome(
      bpm: state.bpm,
      beats: state.totalBeats,
      perBeat: clicksPerBeat[state.subdivision] ?? 1,
    );
    if (order != _order || !state.isPlaying) return;
    _clock
      ..reset()
      ..start();
    state = state.copyWith(currentBeat: 0);
    _scheduleBeat();
  }

  /// Programa el tiempo siguiente contra el reloj (no suma intervalos, así
  /// que la pantalla no se desfasa del sonido).
  void _scheduleBeat() {
    final beatMicros = 60e6 / state.bpm;
    final elapsed = _clock.elapsedMicroseconds;
    final next = (elapsed / beatMicros).floor() + 1;
    _beatTimer = Timer(
      Duration(microseconds: (next * beatMicros - elapsed).round()),
      () {
        if (!state.isPlaying) return;
        state = state.copyWith(currentBeat: next % state.totalBeats);
        _scheduleBeat();
      },
    );
  }

  void _cancelTimers() {
    _beatTimer?.cancel();
    _restart?.cancel();
    _beatTimer = _restart = null;
  }

  /// Sonando, aplica un cambio cuando deja de cambiar.
  void _restartSoon() {
    if (!state.isPlaying) return;
    _cancelTimers();
    _restart = Timer(restartDelay, () {
      if (state.isPlaying) _begin();
    });
  }

  /// Stops the metronome.
  void stopMetronome() {
    _order++;
    _cancelTimers();
    _clock.stop();
    // Sin cambio de estado si ya estaba parado: se llama al ocultar o
    // desmontar la pantalla y no debe notificar a widgets que se desmontan.
    if (!state.isPlaying && state.currentBeat == 0) return;
    _audio.stopMetronome();
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
    if (clamped == state.bpm) return;
    state = state.copyWith(bpm: clamped);
    _restartSoon();
  }

  /// Sets the time signature (e.g. "5/4").
  void setTimeSignature(String ts) {
    final parts = ts.split('/');
    final beats = int.tryParse(parts.first) ?? 4;
    state = state.copyWith(timeSignature: ts, totalBeats: beats, currentBeat: 0);
    _restartSoon();
  }

  /// Sets the subdivision.
  void setSubdivision(String sub) {
    state = state.copyWith(subdivision: sub);
    _restartSoon();
  }
}

/// Riverpod provider for [MetronomeViewModel].
final metronomeViewModelProvider =
    NotifierProvider<MetronomeViewModel, MetronomeState>(MetronomeViewModel.new);
