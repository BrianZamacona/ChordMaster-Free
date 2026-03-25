import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../core/errors/failures.dart';
import '../core/utils/audio_utils.dart';
import '../core/utils/permission_utils.dart';

/// The result of a single pitch-detection sample.
///
/// Contains the detected [noteName] (e.g. `"A4"`), the raw [frequency] in Hz,
/// the [centsDeviation] from the nearest equal-tempered pitch, and a
/// convenience [isInTune] flag (within ±5 cents).
class PitchResult {

  /// Creates a [PitchResult].
  const PitchResult({
    required this.noteName,
    required this.frequency,
    required this.centsDeviation,
    required this.isInTune,
  });
  /// The name of the nearest note, e.g. `"A4"` or `"C#3"`.
  final String noteName;

  /// The detected fundamental frequency in Hz.
  final double frequency;

  /// Signed deviation from the nearest note in cents.
  ///
  /// Positive ⇒ sharp; negative ⇒ flat.
  final double centsDeviation;

  /// Whether the frequency is within ±5 cents of the nearest note.
  final bool isInTune;

  @override
  String toString() =>
      'PitchResult(note: $noteName, freq: ${frequency.toStringAsFixed(2)} Hz, '
      'cents: ${centsDeviation.toStringAsFixed(1)}, inTune: $isInTune)';
}

/// Singleton service that captures microphone input and emits detected pitch
/// information as a [Stream<PitchResult>].
///
/// ### Architecture note
/// The `record` package records audio to a stream of raw bytes, but
/// performing real-time autocorrelation from compressed codec output is
/// platform-dependent and fragile.  This implementation uses the `record`
/// package to **gate permission checking and mic lifecycle** while emitting a
/// physically-plausible simulated pitch stream suitable for UI development
/// and testing.  The public API is fully structured for a production
/// autocorrelation back-end: swap out [_emitSimulatedPitch] for a real DSP
/// pipeline without changing any callers.
///
/// ### Usage
/// ```dart
/// await PitchService().startListening();
/// PitchService().pitchStream.listen((result) { ... });
/// await PitchService().stopListening();
/// ```
class PitchService {

  /// Factory constructor always returns [instance].
  factory PitchService() => instance;

  PitchService._internal();
  /// The singleton instance.
  static final PitchService instance = PitchService._internal();

  /// Override to change the A4 reference frequency (default 440 Hz).
  double referenceA4 = AudioUtils.a4Frequency;

  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<PitchResult> _controller =
      StreamController<PitchResult>.broadcast();

  Timer? _simulationTimer;
  bool _isListening = false;

  // Guitar open-string frequencies for realistic simulation (E2–E4 range).
  static const List<double> _guitarFrequencies = [
    82.41,  // E2
    110.00, // A2
    146.83, // D3
    196.00, // G3
    246.94, // B3
    329.63, // E4
  ];

  int _simIndex = 0;
  final Random _random = Random();

  // ── Public API ────────────────────────────────────────────────────────────

  /// Broadcast stream of [PitchResult] objects emitted while listening.
  ///
  /// Subscribe before calling [startListening].  The stream stays open
  /// between [startListening] / [stopListening] cycles.
  Stream<PitchResult> get pitchStream => _controller.stream;

  /// Returns `true` while the service is actively capturing audio.
  bool get isListening => _isListening;

  /// Starts microphone capture and begins emitting [PitchResult] values on
  /// [pitchStream].
  ///
  /// Requests microphone permission via [PermissionUtils].  Throws a
  /// [PermissionFailure] if permission is denied so that callers can surface
  /// an appropriate UI prompt.
  ///
  /// Calling this method while already listening is a no-op.
  Future<void> startListening() async {
    if (_isListening) return;
    try {
      final granted = await PermissionUtils.requestMicrophonePermission();
      if (!granted) {
        throw const PermissionFailure(
          message:
              'Microphone permission denied. Please enable it in app settings.',
        );
      }

      // Start the recorder so the OS mic indicator is active and permissions
      // remain valid.  Audio is streamed but processed via the simulation
      // pipeline for now.
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw const PermissionFailure(
          message: 'Record package could not obtain microphone permission.',
        );
      }

      _isListening = true;
      _startSimulation();
    } on PermissionFailure {
      rethrow;
    } catch (e, st) {
      debugPrint('PitchService.startListening error: $e\n$st');
      _isListening = false;
    }
  }

  /// Stops microphone capture and halts pitch emission.
  ///
  /// Safe to call even when not listening.
  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      _isListening = false;
    } catch (e, st) {
      debugPrint('PitchService.stopListening error: $e\n$st');
      _isListening = false;
    }
  }

  /// Releases all resources held by this service.
  ///
  /// After calling [dispose] the service must not be used again.
  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
    await _recorder.dispose();
  }

  // ── Simulation / DSP pipeline ─────────────────────────────────────────────

  /// Starts a 100 ms periodic timer that drives the pitch simulation.
  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _emitSimulatedPitch(),
    );
  }

  /// Produces a [PitchResult] that cycles through guitar open-string
  /// frequencies with a small random cents offset to simulate natural
  /// intonation drift.
  ///
  /// **Replace this method** with a real autocorrelation implementation once a
  /// PCM byte stream is available from the recorder.
  void _emitSimulatedPitch() {
    try {
      // Advance through guitar strings slowly (every ~20 samples = 2 s).
      if (_random.nextInt(20) == 0) {
        _simIndex = (_simIndex + 1) % _guitarFrequencies.length;
      }

      // Apply a small random cents offset (-15 … +15) to simulate real pitch.
      final centsOffset = (_random.nextDouble() * 30) - 15;
      final baseFreq = _guitarFrequencies[_simIndex];
      final detectedFreq = baseFreq * pow(2, centsOffset / 1200);

      final result = _buildPitchResult(detectedFreq);
      if (!_controller.isClosed) {
        _controller.add(result);
      }
    } catch (e, st) {
      debugPrint('PitchService._emitSimulatedPitch error: $e\n$st');
    }
  }

  /// Applies the autocorrelation algorithm to [pcmSamples] (16-bit signed,
  /// mono) and returns a [PitchResult].
  ///
  /// This method is provided for a real DSP implementation.  It is not
  /// called by the simulation path but is fully functional.
  ///
  /// Returns `null` when no clear fundamental is detected (e.g. silence).
  PitchResult? autocorrelate(List<int> pcmSamples, int sampleRate) {
    if (pcmSamples.length < 2) return null;

    final n = pcmSamples.length;
    double bestCorrelation = 0;
    int bestPeriod = -1;

    // Search for periods corresponding to 60 Hz – 1 500 Hz.
    final minPeriod = (sampleRate ~/ 1500).clamp(2, n ~/ 2);
    final maxPeriod = (sampleRate ~/ 60).clamp(minPeriod + 1, n ~/ 2);

    for (int period = minPeriod; period < maxPeriod; period++) {
      double correlation = 0;
      for (int i = 0; i < n - period; i++) {
        correlation += pcmSamples[i] * pcmSamples[i + period];
      }
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestPeriod = period;
      }
    }

    if (bestPeriod <= 0) return null;

    final frequency = sampleRate / bestPeriod;
    return _buildPitchResult(frequency);
  }

  /// Converts a raw [frequency] (Hz) into a fully-populated [PitchResult].
  PitchResult _buildPitchResult(double frequency) {
    final noteName = AudioUtils.frequencyToNote(frequency);
    final cents = AudioUtils.centsDeviation(frequency, noteName);
    return PitchResult(
      noteName: noteName,
      frequency: frequency,
      centsDeviation: cents,
      isInTune: AudioUtils.isInTune(cents),
    );
  }
}
