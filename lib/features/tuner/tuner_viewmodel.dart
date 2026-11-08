import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/permission_utils.dart';
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
    this.permanentlyDenied = false,
  });

  /// El micrófono se negó para siempre: hay que ir a los ajustes.
  final bool permanentlyDenied;
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
    bool? permanentlyDenied,
  }) => TunerState(
      note: identical(note, _unset) ? this.note : note as String?,
      frequency:
          identical(frequency, _unset) ? this.frequency : frequency as double?,
      cents: identical(cents, _unset) ? this.cents : cents as double?,
      isInTune: isInTune ?? this.isInTune,
      hasPermission: hasPermission ?? this.hasPermission,
      isListening: isListening ?? this.isListening,
      referenceHz: referenceHz ?? this.referenceHz,
      permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
    );
}

class TunerViewModel extends Notifier<TunerState> {
  @override
  TunerState build() {
    // Read from the provider so tests can inject a fake PitchService and so
    // a hot-reload never creates a second PitchService instance.
    _pitchService = ref.read(pitchServiceProvider);
    ref.onDispose(() {
      _throttle?.cancel();
      _sub?.cancel();
    });
    return const TunerState();
  }

  late final PitchService _pitchService;
  StreamSubscription<PitchResult>? _sub;
  Timer? _throttle;
  PitchResult? _pending;

  /// Cada cuánto, como mucho, se actualiza la pantalla.
  static const refresh = Duration(milliseconds: 80);

  /// Lo que pidió la pantalla por última vez. Si se oculta mientras el
  /// micrófono arranca, al terminar de arrancar se vuelve a apagar.
  bool _wanted = false;

  Future<void> startListening() async {
    if (_wanted) return;
    _wanted = true;
    try {
      await _pitchService.startListening();
      if (!_wanted) {
        await _pitchService.stopListening();
        return;
      }
      state = state.copyWith(
        isListening: true,
        hasPermission: true,
        permanentlyDenied: false,
      );
      _sub = _pitchService.pitchStream.listen(_onPitch, onError: _onError);
    } catch (e) {
      debugPrint('TunerViewModel.startListening error: $e');
      _wanted = false;
      state = state.copyWith(
        hasPermission: false,
        isListening: false,
        permanentlyDenied: await PermissionUtils.isMicrophonePermanentlyDenied(),
      );
    }
  }

  /// Muestra cada lectura en cuanto llega, pero a lo sumo una cada
  /// [refresh]: la que llega mientras tanto se muestra al cumplirse. (Antes
  /// se esperaba a que dejaran de llegar lecturas, y con una nota sonando
  /// llegan cada ~46 ms: la aguja no se movía hasta que la cuerda callaba.)
  void _onPitch(PitchResult result) {
    if (_throttle?.isActive ?? false) {
      _pending = result;
      return;
    }
    _show(result);
    _throttle = Timer(refresh, () {
      final r = _pending;
      _pending = null;
      if (r != null) _onPitch(r);
    });
  }

  void _show(PitchResult r) {
    if (!state.isListening) return;
    state = state.copyWith(
      note: r.noteName,
      frequency: r.frequency,
      cents: r.centsDeviation,
      isInTune: r.isInTune,
    );
  }

  void _onError(Object e) {
    debugPrint('TunerViewModel pitch stream error: $e');
    _wanted = false;
    state = state.copyWith(hasPermission: false, isListening: false);
  }

  Future<void> stopListening() async {
    _wanted = false;
    _throttle?.cancel();
    _pending = null;
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

  /// Cambia el La de referencia; las lecturas siguientes ya lo usan.
  void setReference(double hz) {
    _pitchService.referenceA4 = hz;
    state = state.copyWith(referenceHz: hz);
  }

  /// Abre los ajustes de la app (micrófono negado para siempre).
  Future<void> openSettings() => PermissionUtils.openAppSettings();

}

final tunerViewModelProvider =
    NotifierProvider<TunerViewModel, TunerState>(TunerViewModel.new);
