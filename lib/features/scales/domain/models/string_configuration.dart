/// Guitar string configuration for fretboard calculation.
///
/// [openNotes] lists pitch classes from low string (index 0) to high string
/// (index n−1). Use [openNoteForString] to convert from the standard
/// 1-based high-to-low convention used in [NoteCoordinate].
class StringConfiguration {
  const StringConfiguration({
    required this.stringCount,
    required this.openNotes,
    required this.displayName,
  });

  // ── Presets ────────────────────────────────────────────────────────────────

  /// Standard 6-string guitar (EADGBE, low → high).
  static const StringConfiguration standard6 = StringConfiguration(
    stringCount: 6,
    openNotes: ['E', 'A', 'D', 'G', 'B', 'E'],
    displayName: '6-String Standard (EADGBE)',
  );

  /// Standard 7-string guitar (BEADGBE, low → high).
  static const StringConfiguration standard7 = StringConfiguration(
    stringCount: 7,
    openNotes: ['B', 'E', 'A', 'D', 'G', 'B', 'E'],
    displayName: '7-String Standard (BEADGBE)',
  );

  /// Standard 8-string guitar (F#BEADGBE, low → high).
  static const StringConfiguration standard8 = StringConfiguration(
    stringCount: 8,
    openNotes: ['F#', 'B', 'E', 'A', 'D', 'G', 'B', 'E'],
    displayName: '8-String Standard (F#BEADGBE)',
  );

  /// Drop-D 6-string guitar (DADGBE, low → high).
  static const StringConfiguration dropD = StringConfiguration(
    stringCount: 6,
    openNotes: ['D', 'A', 'D', 'G', 'B', 'E'],
    displayName: '6-String Drop D (DADGBE)',
  );

  /// All predefined configurations in display order.
  static const List<StringConfiguration> presets = [
    standard6,
    standard7,
    standard8,
    dropD,
  ];

  // ── Fields ─────────────────────────────────────────────────────────────────

  /// Total number of strings.
  final int stringCount;

  /// Open string pitch classes from low (index 0) to high (index n−1).
  final List<String> openNotes;

  /// Human-readable label for UI selectors.
  final String displayName;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the open pitch class for [stringNumber] (1 = highest string).
  ///
  /// Converts from 1-based high-to-low to the 0-based low-to-high index used
  /// internally: `index = stringCount − stringNumber`.
  String openNoteForString(int stringNumber) {
    final index = stringCount - stringNumber;
    if (index < 0 || index >= stringCount) return 'E';
    return openNotes[index];
  }
}
