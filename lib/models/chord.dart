/// Represents a guitar chord with its theory, fingering, and metadata.
///
/// Chord objects can be serialised to/from JSON for asset bundling and
/// persistence in Hive-backed storage.
class Chord {
  /// Creates a [Chord] with all required fields.
  const Chord({
    required this.name,
    required this.root,
    required this.type,
    required this.intervals,
    required this.fretPositions,
    required this.fingerPositions,
    this.audioFile,
    this.difficulty = 1,
    this.displayName,
    this.aliases = const [],
    this.tags = const [],
    this.description,
    this.baseFret,
    this.voicingName,
  });

  /// Deserialises a [Chord] from a JSON map.
  factory Chord.fromJson(Map<String, dynamic> json) {
    final name = _readRequiredString(json, 'name');
    final root = _readRequiredString(json, 'root');
    final type = _readRequiredString(json, 'type');
    final intervals = _readIntList(json, 'intervals');
    final fretPositions = _readFixedIntList(json, 'fretPositions');
    final fingerPositions = _readFixedIntList(json, 'fingerPositions');
    final difficulty = (json['difficulty'] as num?)?.toInt() ?? 1;
    if (difficulty < 1 || difficulty > 5) {
      throw const FormatException('difficulty must be between 1 and 5');
    }
    for (final fret in fretPositions) {
      if (fret < -1 || fret > 24) {
        throw const FormatException('fretPositions values must be between -1 and 24');
      }
    }
    for (final finger in fingerPositions) {
      if (finger < 0 || finger > 4) {
        throw const FormatException('fingerPositions values must be between 0 and 4');
      }
    }

    return Chord(
      name: name,
      root: root,
      type: type,
      intervals: intervals,
      fretPositions: fretPositions,
      fingerPositions: fingerPositions,
      audioFile: json['audioFile'] as String?,
      difficulty: difficulty,
      displayName: _readOptionalString(json, 'displayName'),
      aliases: _readStringList(json, 'aliases'),
      tags: _readStringList(json, 'tags'),
      description: _readOptionalString(json, 'description'),
      baseFret: (json['baseFret'] as num?)?.toInt(),
      voicingName: _readOptionalString(json, 'voicingName'),
    );
  }

  /// Display name of the chord (e.g. `"C Major"`).
  final String name;

  /// Root note of the chord (e.g. `"C"`).
  final String root;

  /// Quality / type of the chord (e.g. `"major"`, `"minor7"`).
  final String type;

  /// Semitone intervals that make up the chord, relative to the root.
  final List<int> intervals;

  /// Six fret positions, one per guitar string (low E → high E).
  ///
  /// `-1` means the string is muted; `0` means open.
  final List<int> fretPositions;

  /// Suggested finger numbers (1–4) for each fret position.
  ///
  /// `0` means no finger (open or muted).
  final List<int> fingerPositions;

  /// Optional path to a bundled audio preview file.
  final String? audioFile;

  /// Subjective difficulty rating from 1 (easy) to 5 (expert).
  final int difficulty;

  /// Optional compact display name (e.g. `"Cmaj9"`).
  final String? displayName;

  /// Alternate names that should be discoverable via search.
  final List<String> aliases;

  /// Musical categories such as jazz, blues, exotic, or power.
  final List<String> tags;

  /// Short description or musical usage note for the chord.
  final String? description;

  /// Explicit base fret for rendering movable shapes.
  final int? baseFret;

  /// Optional voicing label, e.g. open, movable, shell, or barre.
  final String? voicingName;

  /// Serialises this [Chord] to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'root': root,
        'type': type,
        'intervals': intervals,
        'fretPositions': fretPositions,
        'fingerPositions': fingerPositions,
        'audioFile': audioFile,
        'difficulty': difficulty,
        'displayName': displayName,
        'aliases': aliases,
        'tags': tags,
        'description': description,
        'baseFret': baseFret,
        'voicingName': voicingName,
      };

  /// Sentinel used by [copyWith] to distinguish "clear to null" from "keep existing".
  static const Object _unset = Object();

  /// Returns a copy of this [Chord] with the specified fields replaced.
  Chord copyWith({
    String? name,
    String? root,
    String? type,
    List<int>? intervals,
    List<int>? fretPositions,
    List<int>? fingerPositions,
    Object? audioFile = _unset,
    int? difficulty,
    Object? displayName = _unset,
    List<String>? aliases,
    List<String>? tags,
    Object? description = _unset,
    Object? baseFret = _unset,
    Object? voicingName = _unset,
  }) =>
      Chord(
        name: name ?? this.name,
        root: root ?? this.root,
        type: type ?? this.type,
        intervals: intervals ?? this.intervals,
        fretPositions: fretPositions ?? this.fretPositions,
        fingerPositions: fingerPositions ?? this.fingerPositions,
        audioFile: identical(audioFile, _unset)
            ? this.audioFile
            : audioFile as String?,
        difficulty: difficulty ?? this.difficulty,
        displayName: identical(displayName, _unset)
            ? this.displayName
            : displayName as String?,
        aliases: aliases ?? this.aliases,
        tags: tags ?? this.tags,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
        baseFret: identical(baseFret, _unset) ? this.baseFret : baseFret as int?,
        voicingName: identical(voicingName, _unset)
            ? this.voicingName
            : voicingName as String?,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chord &&
        other.name == name &&
        other.root == root &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, root, type);

  @override
  String toString() =>
      'Chord(name: $name, root: $root, type: $type, difficulty: $difficulty)';

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = _readOptionalString(json, key);
    if (value == null || value.trim().isEmpty) {
      throw FormatException('$key is required');
    }
    return value.trim();
  }

  static String? _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$key must be a string');
    }
    return value;
  }

  static List<int> _readIntList(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw is! List) {
      throw FormatException('$key must be a list');
    }
    return raw.map((value) {
      if (value is! num) {
        throw FormatException('$key must contain only numbers');
      }
      return value.toInt();
    }).toList(growable: false);
  }

  static List<int> _readFixedIntList(Map<String, dynamic> json, String key) {
    final values = _readIntList(json, key);
    if (values.length != 6) {
      throw FormatException('$key must contain exactly 6 values');
    }
    return values;
  }

  static List<String> _readStringList(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw == null) return const [];
    if (raw is! List) {
      throw FormatException('$key must be a list');
    }
    return raw.map((value) {
      if (value is! String) {
        throw FormatException('$key must contain only strings');
      }
      return value.trim();
    }).where((value) => value.isNotEmpty).toSet().toList(growable: false);
  }
}
