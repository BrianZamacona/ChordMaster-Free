import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/pitch_service.dart';

/// Provider for the [PitchService] singleton.
///
/// Exposing it through Riverpod allows tests to override it with a fake
/// implementation and prevents [TunerViewModel] from creating a second
/// instance on hot-reload / Notifier rebuild.
final pitchServiceProvider = Provider<PitchService>((ref) {
  ref.keepAlive();
  return PitchService.instance;
});

class TunerState {

  const TunerState({
    this.note,
    this.frequency,
    this.cents,
    this.isInTune = false,
    this.hasPermission = true,
    this.isListening = false,
    this.referenceHz = 440.0,
  });
  final String? note;
  final double? frequency;
  final double? cents;
  final bool isInTune;
  final bool hasPermission;
  final bool isListening;
  final double referenceHz;

  /// Sentinel used to distinguish "not provided" from an explicit `null`.
  static const Object _unset = Object();

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields ([note], [frequency], [cents]) accept an explicit `null`
  /// to reset them — pass nothing (or the sentinel default) to keep the
  /// current value.
  TunerState copyWith({
    Object? note = _unset,
    Object? frequency = _unset,
    Object? cents = _unset,
    bool? isInTune,
    bool? hasPermission,
    bool? isListening,
    double? referenceHz,
  }) => TunerState(
      note: identical(note, _unset) ? this.note : note as String?,
      frequency:
          identical(frequency, _unset) ? this.frequency : frequency as double?,
      cents: identical(cents, _unset) ? this.cents : cents as double?,
      isInTune: isInTune ?? this.isInTune,
      hasPermission: hasPermission ?? this.hasPermission,
      isListening: isListening ?? this.isListening,
      referenceHz: referenceHz ?? this.referenceHz,
    );
}

class TunerViewModel extends Notifier<TunerState> {
  @override
  TunerState build() {
    // Read from the provider so tests can inject a fake PitchService and so
    // a hot-reload never creates a second PitchService instance.
    _pitchService = ref.read(pitchServiceProvider);
    ref.onDispose(() {
      _debounce?.cancel();
      _sub?.cancel();
    });
    return const TunerState();
  }

  late final PitchService _pitchService;
  StreamSubscription<PitchResult>? _sub;
  Timer? _debounce;
  PitchResult? _pending;

  Future<void> startListening() async {
    if (state.isListening) return;
    try {
      await _pitchService.startListening();
      state = state.copyWith(isListening: true, hasPermission: true);
      _sub = _pitchService.pitchStream.listen(_onPitch, onError: _onError);
    } catch (e) {
      debugPrint('TunerViewModel.startListening error: $e');
      state = state.copyWith(hasPermission: false, isListening: false);
    }
  }

  void _onPitch(PitchResult result) {
    _pending = result;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      final r = _pending;
      if (r == null) return;
      state = state.copyWith(
        note: r.noteName,
        frequency: r.frequency,
        cents: r.centsDeviation,
        isInTune: r.isInTune,
      );
    });
  }

  void _onError(Object e) {
    debugPrint('TunerViewModel pitch stream error: $e');
    state = state.copyWith(hasPermission: false, isListening: false);
  }

  Future<void> stopListening() async {
    _debounce?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _pitchService.stopListening();
    // Reset pitch readings so the UI does not show stale data after stopping.
    state = state.copyWith(
      isListening: false,
      note: null,
      frequency: null,
      cents: null,
      isInTune: false,
    );
  }

  void setReference(double hz) {
    state = state.copyWith(referenceHz: hz);
  }

}

final tunerViewModelProvider =
    NotifierProvider<TunerViewModel, TunerState>(TunerViewModel.new);
