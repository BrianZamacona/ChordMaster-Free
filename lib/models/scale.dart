/// Represents a musical scale with its theory metadata.
///
/// Serializable to/from JSON for assets and Hive-backed storage.
class Scale {
  /// Creates a [Scale] with all required fields.
  const Scale({
    required this.name,
    required this.root,
    required this.type,
    required this.intervals,
    required this.description,
    required this.relatedChords,
    required this.commonUsage,
    this.blockFingerings = const [],
    this.threeNotePerStringFingerings = const [],
    this.cagedFingerings = const [],
    this.harmonizedChords = const [],
  });

  /// Deserialises a [Scale] from a JSON map.
  factory Scale.fromJson(Map<String, dynamic> json) {
    final intervals = _requireIntList(json, 'intervals', min: 0, max: 24);
    final relatedChords = _requireStringList(json, 'relatedChords');

    return Scale(
      name: _requireString(json, 'name'),
      root: _requireString(json, 'root'),
      type: _requireString(json, 'type'),
      intervals: intervals,
      description: _requireString(json, 'description'),
      relatedChords: relatedChords,
      commonUsage: _requireString(json, 'commonUsage'),
      blockFingerings: _optionalPatternList(json, 'blockFingerings'),
      threeNotePerStringFingerings:
          _optionalPatternList(json, 'threeNotePerStringFingerings'),
      cagedFingerings: _optionalPatternList(json, 'cagedFingerings'),
      harmonizedChords: _optionalHarmonizedChordList(json, 'harmonizedChords'),
    );
  }

  /// Display name of the scale (e.g. `"C Major"`).
  final String name;

  /// Root note (e.g. `"C"`).
  final String root;

  /// Scale type key matching [scaleFormulas] (e.g. `"major"`).
  final String type;

  /// Semitone intervals from the root.
  final List<int> intervals;

  /// Short description of the scale's sound / character.
  final String description;

  /// Names of chords naturally derived from this scale.
  final List<String> relatedChords;

  /// Description of common musical contexts where this scale is used.
  final String commonUsage;

  /// Position-based block fingerings for guitar practice.
  final List<ScalePattern> blockFingerings;

  /// Three-notes-per-string (3NPS) fingering patterns.
  final List<ScalePattern> threeNotePerStringFingerings;

  /// CAGED-oriented fingering patterns.
  final List<ScalePattern> cagedFingerings;

  /// Harmonized triads by degree for this scale.
  final List<HarmonizedChord> harmonizedChords;

  /// Serialises this [Scale] to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'root': root,
        'type': type,
        'intervals': intervals,
        'description': description,
        'relatedChords': relatedChords,
        'commonUsage': commonUsage,
        'blockFingerings': blockFingerings.map((e) => e.toJson()).toList(),
        'threeNotePerStringFingerings':
            threeNotePerStringFingerings.map((e) => e.toJson()).toList(),
        'cagedFingerings': cagedFingerings.map((e) => e.toJson()).toList(),
        'harmonizedChords': harmonizedChords.map((e) => e.toJson()).toList(),
      };

  /// Returns a copy of this [Scale] with the specified fields replaced.
  Scale copyWith({
    String? name,
    String? root,
    String? type,
    List<int>? intervals,
    String? description,
    List<String>? relatedChords,
    String? commonUsage,
    List<ScalePattern>? blockFingerings,
    List<ScalePattern>? threeNotePerStringFingerings,
    List<ScalePattern>? cagedFingerings,
    List<HarmonizedChord>? harmonizedChords,
  }) =>
      Scale(
        name: name ?? this.name,
        root: root ?? this.root,
        type: type ?? this.type,
        intervals: intervals ?? this.intervals,
        description: description ?? this.description,
        relatedChords: relatedChords ?? this.relatedChords,
        commonUsage: commonUsage ?? this.commonUsage,
        blockFingerings: blockFingerings ?? this.blockFingerings,
        threeNotePerStringFingerings:
            threeNotePerStringFingerings ?? this.threeNotePerStringFingerings,
        cagedFingerings: cagedFingerings ?? this.cagedFingerings,
        harmonizedChords: harmonizedChords ?? this.harmonizedChords,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scale &&
        other.name == name &&
        other.root == root &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, root, type);

  @override
  String toString() => 'Scale(name: $name, root: $root, type: $type)';

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  static List<int> _requireIntList(
    Map<String, dynamic> json,
    String key, {
    required int min,
    required int max,
  }) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value.map((entry) {
      if (entry is! num) {
        throw FormatException('$key must contain only numbers');
      }
      final intValue = entry.toInt();
      if (intValue < min || intValue > max) {
        throw FormatException('$key values must be between $min and $max');
      }
      return intValue;
    }).toList(growable: false);
  }

  static List<String> _requireStringList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value.map((entry) {
      if (entry is! String || entry.trim().isEmpty) {
        throw FormatException('$key must contain only non-empty strings');
      }
      return entry;
    }).toList(growable: false);
  }

  static List<ScalePattern> _optionalPatternList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value
        .map((entry) =>
            ScalePattern.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList(growable: false);
  }

  static List<HarmonizedChord> _optionalHarmonizedChordList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value
        .map((entry) =>
            HarmonizedChord.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList(growable: false);
  }
}

/// A reusable guitar fingering pattern representation for a scale.
class ScalePattern {
  const ScalePattern({
    required this.name,
    required this.positions,
    this.description,
  });

  factory ScalePattern.fromJson(Map<String, dynamic> json) => ScalePattern(
        name: _requirePatternString(json, 'name'),
        positions: _requirePatternStringList(json, 'positions'),
        description: json['description'] as String?,
      );

  final String name;
  final List<String> positions;
  final String? description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'positions': positions,
        if (description != null) 'description': description,
      };

  static String _requirePatternString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  static List<String> _requirePatternStringList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value.map((entry) {
      if (entry is! String || entry.trim().isEmpty) {
        throw FormatException('$key must contain only non-empty strings');
      }
      return entry;
    }).toList(growable: false);
  }
}

/// A harmonized chord entry for one degree of a scale.
class HarmonizedChord {
  const HarmonizedChord({
    required this.degree,
    required this.chord,
    required this.quality,
  });

  factory HarmonizedChord.fromJson(Map<String, dynamic> json) =>
      HarmonizedChord(
        degree: _requireString(json, 'degree'),
        chord: _requireString(json, 'chord'),
        quality: _requireString(json, 'quality'),
      );

  final String degree;
  final String chord;
  final String quality;

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'chord': chord,
        'quality': quality,
      };

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }
}
