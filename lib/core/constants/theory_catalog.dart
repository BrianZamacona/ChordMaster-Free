/// Canonical music-theory catalog used as the single source of truth.
///
/// Keep all interval formulas centralized here and reference this catalog from
/// constants, domain engines, and feature layers to avoid drift.
class TheoryCatalog {
  TheoryCatalog._();

  /// The twelve chromatic pitches using sharp notation.
  static const List<String> chromaticNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Canonical chord formulas expressed as semitone offsets from the root.
  static const Map<String, List<int>> chordFormulas = {
    'major': [0, 4, 7],
    'minor': [0, 3, 7],
    'dominant7': [0, 4, 7, 10],
    'major7': [0, 4, 7, 11],
    'minor7': [0, 3, 7, 10],
    'diminished': [0, 3, 6],
    'augmented': [0, 4, 8],
    'sus2': [0, 2, 7],
    'sus4': [0, 5, 7],
    'add9': [0, 4, 7, 14],
    'sixth': [0, 4, 7, 9],
    'minor6': [0, 3, 7, 9],
    'sixth9': [0, 4, 7, 9, 14],
    'ninth': [0, 4, 7, 10, 14],
    'dominant9': [0, 4, 7, 10, 14],
    'major9': [0, 4, 7, 11, 14],
    'minor9': [0, 3, 7, 10, 14],
    'eleventh': [0, 4, 7, 10, 14, 17],
    'minor11': [0, 3, 7, 10, 14, 17],
    'thirteenth': [0, 4, 7, 10, 14, 17, 21],
    'halfDiminished': [0, 3, 6, 10],
    'diminished7': [0, 3, 6, 9],
    'major7Sharp11': [0, 4, 7, 11, 18],
    'dominant7Flat9': [0, 4, 7, 10, 13],
    'dominant7Sharp9': [0, 4, 7, 10, 15],
    'power5': [0, 7],
  };

  /// Canonical base scale formulas.
  static const Map<String, List<int>> scaleFormulas = {
    'major': [0, 2, 4, 5, 7, 9, 11],
    'naturalMinor': [0, 2, 3, 5, 7, 8, 10],
    'harmonicMinor': [0, 2, 3, 5, 7, 8, 11],
    'melodicMinor': [0, 2, 3, 5, 7, 9, 11],
    'pentatonicMajor': [0, 2, 4, 7, 9],
    'pentatonicMinor': [0, 3, 5, 7, 10],
    'extendedPentatonic': [0, 2, 3, 5, 7, 9, 10],
    'chromatic': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    'blues': [0, 3, 5, 6, 7, 10],
    'wholeTone': [0, 2, 4, 6, 8, 10],
  };

  /// Canonical Greek mode formulas.
  static const Map<String, List<int>> modeFormulas = {
    'ionian': [0, 2, 4, 5, 7, 9, 11],
    'dorian': [0, 2, 3, 5, 7, 9, 10],
    'phrygian': [0, 1, 3, 5, 7, 8, 10],
    'lydian': [0, 2, 4, 6, 7, 9, 11],
    'mixolydian': [0, 2, 4, 5, 7, 9, 10],
    'aeolian': [0, 2, 3, 5, 7, 8, 10],
    'locrian': [0, 1, 3, 5, 6, 8, 10],
  };

  /// Canonical exotic / world scale formulas.
  static const Map<String, List<int>> exoticScales = {
    'hungarianMinor': [0, 2, 3, 6, 7, 8, 11],
    'phrygianDominant': [0, 1, 4, 5, 7, 8, 10],
    'doubleHarmonic': [0, 1, 4, 5, 7, 8, 11],
    'neapolitan': [0, 1, 3, 5, 7, 9, 11],
  };
}
