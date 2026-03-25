import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../constants/music_theory.dart';

/// Utility helpers for audio-related calculations used by the tuner and
/// ear-training features.
///
/// All frequency math is based on the standard A4 = 440 Hz reference pitch
/// and the equal-temperament formula: `f = 440 × 2^((midi − 69) / 12)`.
class AudioUtils {
  AudioUtils._();

  /// The reference frequency for A4 in Hz.
  static const double a4Frequency = 440;

  /// The MIDI number of A4.
  static const int a4Midi = 69;

  // ── Core Conversions ───────────────────────────────────────────────────────

  /// Converts a [frequency] in Hz to the nearest MIDI note number.
  ///
  /// Uses `midi = round(69 + 12 × log₂(f / 440))`.
  static int frequencyToMidi(double frequency) {
    if (frequency <= 0) return 0;
    return (a4Midi + 12 * (math.log(frequency / a4Frequency) / math.ln2))
        .round();
  }

  /// Converts a MIDI note number to its equal-temperament frequency in Hz.
  ///
  /// Uses `f = 440 × 2^((midi − 69) / 12)`.
  static double midiToFrequency(int midi) => a4Frequency * math.pow(2, (midi - a4Midi) / 12).toDouble();

  /// Converts a [frequency] to the name of the nearest note (e.g. `"A4"`).
  static String frequencyToNote(double frequency) {
    try {
      if (frequency <= 0) return '--';
  final midi = frequencyToMidi(frequency);
      return noteNameFromMidi(midi);
    } catch (e, st) {
      debugPrint('AudioUtils.frequencyToNote error: $e\n$st');
      return '--';
    }
  }

  // ── Tuning Accuracy ────────────────────────────────────────────────────────

  /// Computes the cents deviation between [frequency] and [targetNote].
  ///
  /// A positive result means [frequency] is sharp; negative means flat.
  /// Returns `0.0` if [targetNote] is unrecognised.
  static double centsDeviation(double frequency, String targetNote) {
    try {
      if (frequency <= 0) return 0;
      final midi = _noteToMidi(targetNote);
      if (midi < 0) return 0;
      final targetFreq = midiToFrequency(midi);
      return 1200 * (math.log(frequency / targetFreq) / math.ln2);
    } catch (e, st) {
      debugPrint('AudioUtils.centsDeviation error: $e\n$st');
      return 0;
    }
  }

  /// Returns `true` when [cents] deviation is within [threshold] cents.
  ///
  /// Default [threshold] is ±5 cents, matching typical professional tuners.
  static bool isInTune(double cents, {double threshold = 5.0}) => cents.abs() <= threshold;

  /// Returns the note name for a given MIDI number (e.g. MIDI 69 → `"A4"`).
  ///
  /// Uses MIDI convention: C-1 = 0, C4 = 60 (middle C), A4 = 69.
  /// The `+1` octave offset corrects for MIDI's C(-1) base.
  static String noteNameFromMidi(int midi) {
    final octave = (midi ~/ 12) - 1; // +1 offset: MIDI C(-1)=0, so octave=(midi/12)-1
    final noteIndex = midi % 12;
    return '${chromaticNotes[noteIndex]}$octave';
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────

  /// Delegates to the shared [noteNameToMidi] helper in `music_theory.dart`.
  ///
  /// Returns `-1` when the string cannot be parsed.
  static int _noteToMidi(String noteWithOctave) => noteNameToMidi(noteWithOctave);
}
