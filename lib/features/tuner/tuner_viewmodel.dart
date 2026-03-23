import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/pitch_service.dart';

class TunerState {
  final String? note;
  final double? frequency;
  final double? cents;
  final bool isInTune;
  final bool hasPermission;
  final bool isListening;
  final double referenceHz;

  const TunerState({
    this.note,
    this.frequency,
    this.cents,
    this.isInTune = false,
    this.hasPermission = true,
    this.isListening = false,
    this.referenceHz = 440.0,
  });

  TunerState copyWith({
    String? note,
    double? frequency,
    double? cents,
    bool? isInTune,
    bool? hasPermission,
    bool? isListening,
    double? referenceHz,
  }) {
    return TunerState(
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      cents: cents ?? this.cents,
      isInTune: isInTune ?? this.isInTune,
      hasPermission: hasPermission ?? this.hasPermission,
      isListening: isListening ?? this.isListening,
      referenceHz: referenceHz ?? this.referenceHz,
    );
  }
}

class TunerViewModel extends StateNotifier<TunerState> {
  TunerViewModel() : super(const TunerState());

  final PitchService _pitchService = PitchService();
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
    state = state.copyWith(isListening: false);
  }

  void setReference(double hz) {
    state = state.copyWith(referenceHz: hz);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

final tunerViewModelProvider =
    StateNotifierProvider<TunerViewModel, TunerState>(
  (ref) => TunerViewModel(),
);
