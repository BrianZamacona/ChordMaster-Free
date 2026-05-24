import '../../../../core/constants/music_theory.dart';

/// Represents a musical scale or mode family with its semitone intervals.
///
/// Covers diatonic scales, pentatonic scales, Greek modes, and exotic scales.
enum ScaleMode {
  // ── Diatonic Scales ────────────────────────────────────────────────────────
  major,
  naturalMinor,
  harmonicMinor,
  melodicMinor,

  // ── Pentatonic / Blues ─────────────────────────────────────────────────────
  pentatonicMajor,
  pentatonicMinor,
  blues,

  // ── Symmetric ─────────────────────────────────────────────────────────────
  wholeTone,

  // ── Greek Modes ───────────────────────────────────────────────────────────
  ionian,
  dorian,
  phrygian,
  lydian,
  mixolydian,
  aeolian,
  locrian,

  // ── Exotic / World ─────────────────────────────────────────────────────────
  hungarianMinor,
  phrygianDominant,
  doubleHarmonic,
  neapolitan,
}

extension ScaleModeX on ScaleMode {
  /// Semitone intervals from the root for this mode.
  List<int> get intervals => switch (this) {
        ScaleMode.major => scaleFormulas['major']!,
        ScaleMode.naturalMinor => scaleFormulas['naturalMinor']!,
        ScaleMode.harmonicMinor => scaleFormulas['harmonicMinor']!,
        ScaleMode.melodicMinor => scaleFormulas['melodicMinor']!,
        ScaleMode.pentatonicMajor => scaleFormulas['pentatonicMajor']!,
        ScaleMode.pentatonicMinor => scaleFormulas['pentatonicMinor']!,
        ScaleMode.blues => scaleFormulas['blues']!,
        ScaleMode.wholeTone => scaleFormulas['wholeTone']!,
        ScaleMode.ionian => modeFormulas['ionian']!,
        ScaleMode.dorian => modeFormulas['dorian']!,
        ScaleMode.phrygian => modeFormulas['phrygian']!,
        ScaleMode.lydian => modeFormulas['lydian']!,
        ScaleMode.mixolydian => modeFormulas['mixolydian']!,
        ScaleMode.aeolian => modeFormulas['aeolian']!,
        ScaleMode.locrian => modeFormulas['locrian']!,
        ScaleMode.hungarianMinor => exoticScales['hungarianMinor']!,
        ScaleMode.phrygianDominant => exoticScales['phrygianDominant']!,
        ScaleMode.doubleHarmonic => exoticScales['doubleHarmonic']!,
        ScaleMode.neapolitan => exoticScales['neapolitan']!,
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        ScaleMode.major => 'Major',
        ScaleMode.naturalMinor => 'Natural Minor',
        ScaleMode.harmonicMinor => 'Harmonic Minor',
        ScaleMode.melodicMinor => 'Melodic Minor',
        ScaleMode.pentatonicMajor => 'Pentatonic Major',
        ScaleMode.pentatonicMinor => 'Pentatonic Minor',
        ScaleMode.blues => 'Blues',
        ScaleMode.wholeTone => 'Whole Tone',
        ScaleMode.ionian => 'Ionian',
        ScaleMode.dorian => 'Dorian',
        ScaleMode.phrygian => 'Phrygian',
        ScaleMode.lydian => 'Lydian',
        ScaleMode.mixolydian => 'Mixolydian',
        ScaleMode.aeolian => 'Aeolian',
        ScaleMode.locrian => 'Locrian',
        ScaleMode.hungarianMinor => 'Hungarian Minor',
        ScaleMode.phrygianDominant => 'Phrygian Dominant',
        ScaleMode.doubleHarmonic => 'Double Harmonic',
        ScaleMode.neapolitan => 'Neapolitan',
      };

  /// Returns the [ScaleMode] matching the [scales.json] type key, or `null`.
  static ScaleMode? fromTypeKey(String key) {
    for (final mode in ScaleMode.values) {
      if (mode.name == key) return mode;
    }
    return null;
  }
}
