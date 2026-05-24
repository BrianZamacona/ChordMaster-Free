import '../../../../core/constants/music_theory.dart';

/// Instrument family for tuning profiles.
enum InstrumentFamily {
  guitar,
  bass,
  banjo,
  ukulele,
  other,
}

/// Full tuning profile used by scale/chord/arpeggio engines.
///
/// [openNotes] lists pitch classes from low string (index 0) to high string
/// (index n−1). String numbers are 1-based (1 = lowest).
class StringConfiguration {
  const StringConfiguration({
    required this.id,
    required this.stringCount,
    required this.openNotes,
    required this.displayName,
    this.instrument = InstrumentFamily.guitar,
    this.capoByString = const {},
    this.mutedStrings = const {},
    this.droneStrings = const {},
  });

  // ── Presets ────────────────────────────────────────────────────────────────

  /// Standard 6-string guitar (EADGBE, low → high).
  static const StringConfiguration standard6 = StringConfiguration(
    id: 'standard6',
    stringCount: 6,
    openNotes: ['E', 'A', 'D', 'G', 'B', 'E'],
    displayName: '6-String Standard (EADGBE)',
  );

  /// Standard 7-string guitar (BEADGBE, low → high).
  static const StringConfiguration standard7 = StringConfiguration(
    id: 'standard7',
    stringCount: 7,
    openNotes: ['B', 'E', 'A', 'D', 'G', 'B', 'E'],
    displayName: '7-String Standard (BEADGBE)',
  );

  /// Standard 8-string guitar (F#BEADGBE, low → high).
  static const StringConfiguration standard8 = StringConfiguration(
    id: 'standard8',
    stringCount: 8,
    openNotes: ['F#', 'B', 'E', 'A', 'D', 'G', 'B', 'E'],
    displayName: '8-String Standard (F#BEADGBE)',
  );

  /// Drop-D 6-string guitar (DADGBE, low → high).
  static const StringConfiguration dropD = StringConfiguration(
    id: 'dropD',
    stringCount: 6,
    openNotes: ['D', 'A', 'D', 'G', 'B', 'E'],
    displayName: '6-String Drop D (DADGBE)',
  );

  /// 5-string banjo with short high-G drone.
  static const StringConfiguration banjo5Drone = StringConfiguration(
    id: 'banjo5Drone',
    instrument: InstrumentFamily.banjo,
    stringCount: 5,
    openNotes: ['G', 'D', 'G', 'B', 'D'],
    droneStrings: {5},
    displayName: '5-String Banjo (gDGBD)',
  );

  /// All predefined configurations in display order.
  static const List<StringConfiguration> presets = [
    standard6,
    standard7,
    standard8,
    dropD,
    banjo5Drone,
  ];

  // ── Fields ─────────────────────────────────────────────────────────────────

  /// Stable id for persistence and provider lookup.
  final String id;

  /// Instrument family metadata.
  final InstrumentFamily instrument;

  /// Total number of strings.
  final int stringCount;

  /// Open string pitch classes from low (index 0) to high (index n−1).
  final List<String> openNotes;

  /// Human-readable label for UI selectors.
  final String displayName;

  /// Per-string capo values in semitones (1-based string number).
  final Map<int, int> capoByString;

  /// Strings disabled for generated fingerings.
  final Set<int> mutedStrings;

  /// Strings flagged as drone strings.
  final Set<int> droneStrings;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the effective open pitch class for [stringNumber].
  ///
  /// This applies per-string capo offsets over [openNotes].
  String openNoteForString(int stringNumber) {
    final index = stringNumber - 1;
    if (index < 0 || index >= stringCount) return 'E';
    final base = openNotes[index];
    final baseIdx = chromaticNotes.indexOf(base);
    if (baseIdx == -1) return base;
    final capo = capoForString(stringNumber);
    return chromaticNotes[(baseIdx + capo) % 12];
  }

  /// Returns the capo semitone offset for [stringNumber].
  int capoForString(int stringNumber) => capoByString[stringNumber] ?? 0;

  /// Whether [stringNumber] can be used by pattern generators.
  bool isStringPlayable(int stringNumber) => !mutedStrings.contains(stringNumber);

  /// Returns a copy with a uniform capo applied to all playable strings.
  StringConfiguration withGlobalCapo(int capo) {
    final normalized = capo < 0 ? 0 : capo;
    return copyWith(
      capoByString: {
        for (var s = 1; s <= stringCount; s++)
          if (isStringPlayable(s)) s: normalized,
      },
    );
  }

  /// Copy helper for tuning evolution while preserving compatibility.
  StringConfiguration copyWith({
    String? id,
    InstrumentFamily? instrument,
    int? stringCount,
    List<String>? openNotes,
    String? displayName,
    Map<int, int>? capoByString,
    Set<int>? mutedStrings,
    Set<int>? droneStrings,
  }) =>
      StringConfiguration(
        id: id ?? this.id,
        instrument: instrument ?? this.instrument,
        stringCount: stringCount ?? this.stringCount,
        openNotes: openNotes ?? this.openNotes,
        displayName: displayName ?? this.displayName,
        capoByString: capoByString ?? this.capoByString,
        mutedStrings: mutedStrings ?? this.mutedStrings,
        droneStrings: droneStrings ?? this.droneStrings,
      );
}
