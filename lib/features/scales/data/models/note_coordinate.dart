/// Single note coordinate for a fretboard diagram position.
class NoteCoordinate {
  /// Creates a strongly-typed note coordinate.
  const NoteCoordinate({
    required this.string,
    required this.fret,
    required this.interval,
    required this.note,
    required this.isRoot,
    this.finger,
  });

  /// Parses [NoteCoordinate] from strict JSON contract.
  factory NoteCoordinate.fromJson(Map<String, dynamic> json) {
    final string = _readRequiredInt(json, 'string');
    final fret = _readRequiredInt(json, 'fret');
    final interval = _readRequiredString(json, 'interval');
    final note = _readRequiredString(json, 'note');
    final isRoot = _readRequiredBool(json, 'is_root');
    final finger = _readOptionalInt(json, 'finger');

    if (string < 1 || string > 6) {
      throw const FormatException('string must be between 1 and 6');
    }
    if (fret < 0) {
      throw const FormatException('fret must be greater than or equal to 0');
    }
    if (finger != null && (finger < 1 || finger > 4)) {
      throw const FormatException('finger must be between 1 and 4');
    }

    return NoteCoordinate(
      string: string,
      fret: fret,
      interval: interval,
      note: note,
      isRoot: isRoot,
      finger: finger,
    );
  }

  /// Guitar string number (1..6), where 1 is high E and 6 is low E.
  final int string;

  /// Absolute fret number in the instrument.
  final int fret;

  /// Interval label relative to root (e.g. "1", "b3", "5").
  final String interval;

  /// Note label (e.g. "C", "F#").
  final String note;

  /// Whether this coordinate is tonic/root.
  final bool isRoot;

  /// Suggested left-hand finger (1..4).
  final int? finger;

  Map<String, dynamic> toJson() => {
        'string': string,
        'fret': fret,
        'interval': interval,
        'note': note,
        'is_root': isRoot,
        if (finger != null) 'finger': finger,
      };

  static int _readRequiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('$key must be a number');
    }
    return value.toInt();
  }

  static int? _readOptionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num) {
      throw FormatException('$key must be a number');
    }
    return value.toInt();
  }

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  static bool _readRequiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('$key must be a boolean');
    }
    return value;
  }
}
