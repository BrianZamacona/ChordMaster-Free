// Music theory constants and helpers for ChordMaster Free.

// ── Chromatic Notes ────────────────────────────────────────────────────────

/// The twelve chromatic pitches using sharp notation.
const List<String> chromaticNotes = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

// ── Chord Formulas (semitone intervals from root) ─────────────────────────

/// Chord formulas expressed as semitone offsets from the root.
///
/// Each entry maps a chord quality name to its interval set.
const Map<String, List<int>> chordFormulas = {
  'major':        [0, 4, 7],
  'minor':        [0, 3, 7],
  'dominant7':    [0, 4, 7, 10],
  'major7':       [0, 4, 7, 11],
  'minor7':       [0, 3, 7, 10],
  'diminished':   [0, 3, 6],
  'augmented':    [0, 4, 8],
  'sus2':         [0, 2, 7],
  'sus4':         [0, 5, 7],
  'add9':         [0, 4, 7, 14],
  'ninth':        [0, 4, 7, 10, 14],
  'eleventh':     [0, 4, 7, 10, 14, 17],
  'thirteenth':   [0, 4, 7, 10, 14, 17, 21],
};

// ── Scale Formulas ─────────────────────────────────────────────────────────

/// Scale formulas expressed as semitone offsets from the root.
const Map<String, List<int>> scaleFormulas = {
  'major':              [0, 2, 4, 5, 7, 9, 11],
  'naturalMinor':       [0, 2, 3, 5, 7, 8, 10],
  'harmonicMinor':      [0, 2, 3, 5, 7, 8, 11],
  'melodicMinor':       [0, 2, 3, 5, 7, 9, 11],
  'pentatonicMajor':    [0, 2, 4, 7, 9],
  'pentatonicMinor':    [0, 3, 5, 7, 10],
  'extendedPentatonic': [0, 2, 3, 5, 7, 9, 10],
  'chromatic':          [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  'blues':              [0, 3, 5, 6, 7, 10],
  'wholeTone':          [0, 2, 4, 6, 8, 10],
};

// ── Mode Formulas ──────────────────────────────────────────────────────────

/// Greek mode formulas expressed as semitone offsets from the tonic.
const Map<String, List<int>> modeFormulas = {
  'ionian':      [0, 2, 4, 5, 7, 9, 11],
  'dorian':      [0, 2, 3, 5, 7, 9, 10],
  'phrygian':    [0, 1, 3, 5, 7, 8, 10],
  'lydian':      [0, 2, 4, 6, 7, 9, 11],
  'mixolydian':  [0, 2, 4, 5, 7, 9, 10],
  'aeolian':     [0, 2, 3, 5, 7, 8, 10],
  'locrian':     [0, 1, 3, 5, 6, 8, 10],
};

// ── Exotic / World Scales ──────────────────────────────────────────────────

/// Exotic scale formulas expressed as semitone offsets from the root.
const Map<String, List<int>> exoticScales = {
  'hungarianMinor':    [0, 2, 3, 6, 7, 8, 11],
  'phrygianDominant':  [0, 1, 4, 5, 7, 8, 10],
  'doubleHarmonic':    [0, 1, 4, 5, 7, 8, 11],
  'neapolitan':        [0, 1, 3, 5, 7, 9, 11],
};

// ── Guitar Tunings ─────────────────────────────────────────────────────────

/// Standard guitar tuning from low to high (string 0 = low E).
const List<String> standardTuning = ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];

/// Alternate guitar tunings keyed by name.
const Map<String, List<String>> alternateTunings = {
  'dropD':  ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
  'openG':  ['D2', 'G2', 'D3', 'G3', 'B3', 'D4'],
  'dadgad': ['D2', 'A2', 'D3', 'G3', 'A3', 'D4'],
};

// ── Note / MIDI Helpers ────────────────────────────────────────────────────

/// Converts a note name with octave (e.g. `"E2"`) to its MIDI number.
///
/// Middle C (C4) = MIDI 60.  Returns `-1` for unrecognised notes.
/// Octave numbering follows MIDI convention: C(−1) = MIDI 0.
int noteNameToMidi(String noteWithOctave) {
  if (noteWithOctave.length < 2) return -1;
  final octaveStr = noteWithOctave[noteWithOctave.length - 1];
  final notePart = noteWithOctave.substring(0, noteWithOctave.length - 1);
  final octave = int.tryParse(octaveStr);
  if (octave == null) return -1;
  final index = chromaticNotes.indexOf(notePart);
  if (index == -1) return -1;
  return (octave + 1) * 12 + index; // +1: C(-1)=MIDI 0 → octave offset
}

/// Returns the note name for a given MIDI number (e.g. MIDI 69 → `"A4"`).
///
/// Uses MIDI convention: C-1 = 0, C4 = 60 (middle C), A4 = 69.
/// The `−1` octave shift corrects for MIDI's C(−1) base (C(−1)=MIDI 0).
String noteNameFromMidi(int midi) {
  final octave = (midi ~/ 12) - 1; // -1 offset: C(-1) starts at MIDI 0
  final noteIndex = midi % 12;
  return '${chromaticNotes[noteIndex]}$octave';
}

// ── Fretboard Map ──────────────────────────────────────────────────────────

/// Precomputed fretboard note map for standard tuning.
///
/// Structure: `fretboardMap[stringIndex][fretNumber]` → note name with octave.
/// `stringIndex` 0 = low E string; frets 0–22.
final Map<int, Map<int, String>> fretboardMap = _buildFretboardMap(standardTuning);

/// Builds a fretboard map from a given [tuning] list (6 open-string notes).
Map<int, Map<int, String>> _buildFretboardMap(List<String> tuning) {
  final map = <int, Map<int, String>>{};
  for (var s = 0; s < tuning.length; s++) {
    final openMidi = noteNameToMidi(tuning[s]);
    map[s] = {};
    for (var fret = 0; fret <= 22; fret++) {
      map[s]![fret] = noteNameFromMidi(openMidi + fret);
    }
  }
  return map;
}

// ── Transposition Utilities ────────────────────────────────────────────────

/// Returns the note name [semitones] above [root] (without octave).
///
/// Example: `getNoteAtInterval('C', 7)` → `'G'`.
String getNoteAtInterval(String root, int semitones) {
  final rootIndex = chromaticNotes.indexOf(root);
  if (rootIndex == -1) return root;
  return chromaticNotes[(rootIndex + semitones) % 12];
}

/// Transposes a note name with octave by [semitones].
///
/// Example: `transposeNote('A4', 2)` → `'B4'`.
/// If [note] does not include an octave digit the note is transposed
/// chromatically without octave tracking.
String transposeNote(String note, int semitones) {
  // Attempt to parse trailing octave digit.
  if (note.length >= 2) {
    final lastChar = note[note.length - 1];
    final octave = int.tryParse(lastChar);
    if (octave != null) {
      final midi = noteNameToMidi(note);
      if (midi != -1) {
        return noteNameFromMidi(midi + semitones);
      }
    }
  }
  // Fallback: no octave, chromatic wrap.
  return getNoteAtInterval(note, semitones);
}

// ── Interval Names ─────────────────────────────────────────────────────────

/// Maps semitone counts (0–12) to their standard interval names.
const Map<int, String> intervalNames = {
  0:  'Unison',
  1:  'Minor 2nd',
  2:  'Major 2nd',
  3:  'Minor 3rd',
  4:  'Major 3rd',
  5:  'Perfect 4th',
  6:  'Tritone',
  7:  'Perfect 5th',
  8:  'Minor 6th',
  9:  'Major 6th',
  10: 'Minor 7th',
  11: 'Major 7th',
  12: 'Octave',
};

// ── Chord Quality Display Names ────────────────────────────────────────────

/// Human-readable display names for chord quality keys.
const Map<String, String> chordQualityDisplayNames = {
  'major':        'Major',
  'minor':        'Minor',
  'dominant7':    'Dominant 7th',
  'major7':       'Major 7th',
  'minor7':       'Minor 7th',
  'diminished':   'Diminished',
  'augmented':    'Augmented',
  'sus2':         'Sus2',
  'sus4':         'Sus4',
  'add9':         'Add 9',
  'ninth':        '9th',
  'eleventh':     '11th',
  'thirteenth':   '13th',
};

// ── Scale Quality Display Names ────────────────────────────────────────────

/// Human-readable display names for scale formula keys.
const Map<String, String> scaleDisplayNames = {
  'major':              'Major',
  'naturalMinor':       'Natural Minor',
  'harmonicMinor':      'Harmonic Minor',
  'melodicMinor':       'Melodic Minor',
  'pentatonicMajor':    'Pentatonic Major',
  'pentatonicMinor':    'Pentatonic Minor',
  'extendedPentatonic': 'Extended Pentatonic',
  'chromatic':          'Chromatic',
  'blues':              'Blues',
  'wholeTone':          'Whole Tone',
};
