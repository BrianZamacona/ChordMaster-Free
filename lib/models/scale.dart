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
    this.activeTuningId,
    this.generationType,
    this.generationConstraints = const {},
    this.appliedVoicing,
    this.appliedInversion,
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
      activeTuningId: json['activeTuningId'] as String?,
      generationType: json['generationType'] as String?,
      generationConstraints: _optionalObjectMap(json, 'generationConstraints'),
      appliedVoicing: json['appliedVoicing'] as String?,
      appliedInversion: json['appliedInversion'] as String?,
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
  final List<ScaleFingering> blockFingerings;

  /// Three-notes-per-string (3NPS) fingering patterns.
  final List<ScaleFingering> threeNotePerStringFingerings;

  /// CAGED-oriented fingering patterns.
  final List<ScaleFingering> cagedFingerings;

  /// Harmonized triads by degree for this scale.
  final List<HarmonizedChord> harmonizedChords;

  /// Optional active tuning profile id used during generation.
  final String? activeTuningId;

  /// Optional generation engine type (scale/arpeggio/chord).
  final String? generationType;

  /// Optional algorithmic constraints used to generate current shape.
  final Map<String, dynamic> generationConstraints;

  /// Optional voicing label applied during generation.
  final String? appliedVoicing;

  /// Optional inversion label applied during generation.
  final String? appliedInversion;

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
        if (activeTuningId != null) 'activeTuningId': activeTuningId,
        if (generationType != null) 'generationType': generationType,
        if (generationConstraints.isNotEmpty)
          'generationConstraints': generationConstraints,
        if (appliedVoicing != null) 'appliedVoicing': appliedVoicing,
        if (appliedInversion != null) 'appliedInversion': appliedInversion,
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
    List<ScaleFingering>? blockFingerings,
    List<ScaleFingering>? threeNotePerStringFingerings,
    List<ScaleFingering>? cagedFingerings,
    List<HarmonizedChord>? harmonizedChords,
    Object? activeTuningId = _unset,
    Object? generationType = _unset,
    Map<String, dynamic>? generationConstraints,
    Object? appliedVoicing = _unset,
    Object? appliedInversion = _unset,
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
        activeTuningId: identical(activeTuningId, _unset)
            ? this.activeTuningId
            : activeTuningId as String?,
        generationType: identical(generationType, _unset)
            ? this.generationType
            : generationType as String?,
        generationConstraints:
            generationConstraints ?? this.generationConstraints,
        appliedVoicing: identical(appliedVoicing, _unset)
            ? this.appliedVoicing
            : appliedVoicing as String?,
        appliedInversion: identical(appliedInversion, _unset)
            ? this.appliedInversion
            : appliedInversion as String?,
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

  static const Object _unset = Object();

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

  static List<ScaleFingering> _optionalPatternList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value
        .map((entry) =>
            ScaleFingering.fromJson(Map<String, dynamic>.from(entry as Map)))
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

  static Map<String, dynamic> _optionalObjectMap(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const {};
    if (value is! Map) {
      throw FormatException('$key must be an object map');
    }
    return Map<String, dynamic>.from(value);
  }
}

/// A reusable guitar fingering pattern representation for a scale.
class ScaleFingering {
  const ScaleFingering({
    required this.name,
    this.id,
    this.system = ScalePatternSystem.custom,
    this.status = ScalePatternStatus.draft,
    this.tonic,
    this.tuningName,
    this.minFret,
    this.maxFret,
    this.positions = const [],
    this.notes = const [],
    this.description,
  });

  factory ScaleFingering.fromJson(Map<String, dynamic> json) {
    final rawSystem = json['system'] as String?;
    final rawStatus = json['status'] as String?;
    final positions = _optionalPatternStringList(json, 'positions');
    final notes = _optionalPatternNoteList(json, 'notes');
    if (positions.isEmpty && notes.isEmpty) {
      throw const FormatException(
        'ScalePattern requires at least one of positions or notes',
      );
    }

    return ScaleFingering(
      id: json['id'] as String?,
      name: _requirePatternString(json, 'name'),
      system: ScalePatternSystemX.fromJson(rawSystem),
      status: ScalePatternStatusX.fromJson(rawStatus),
      tonic: json['tonic'] as String?,
      tuningName: json['tuningName'] as String?,
      minFret: _optionalPositiveInt(json['minFret']),
      maxFret: _optionalPositiveInt(json['maxFret']),
      positions: positions,
      notes: notes,
      description: json['description'] as String?,
    );
  }

  final String? id;
  final String name;
  final ScalePatternSystem system;
  final ScalePatternStatus status;
  final String? tonic;
  final String? tuningName;
  final int? minFret;
  final int? maxFret;
  final List<String> positions;
  final List<ScalePatternNote> notes;
  final String? description;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'system': system.jsonValue,
        'status': status.jsonValue,
        if (tonic != null) 'tonic': tonic,
        if (tuningName != null) 'tuningName': tuningName,
        if (minFret != null) 'minFret': minFret,
        if (maxFret != null) 'maxFret': maxFret,
        if (positions.isNotEmpty) 'positions': positions,
        if (notes.isNotEmpty) 'notes': notes.map((n) => n.toJson()).toList(),
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

  static List<String> _optionalPatternStringList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    return _requirePatternStringList(json, key);
  }

  static List<ScalePatternNote> _optionalPatternNoteList(
      Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('$key must be a list');
    }
    return value
        .map((entry) =>
            ScalePatternNote.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList(growable: false);
  }

  static int? _optionalPositiveInt(Object? value) {
    if (value == null) return null;
    if (value is! num) {
      throw const FormatException('Expected numeric fret value');
    }
    final intValue = value.toInt();
    if (intValue < 0) {
      throw const FormatException('Fret value must be >= 0');
    }
    return intValue;
  }
}

enum ScalePatternSystem {
  block,
  threeNps,
  caged,
  pentatonicBox,
  custom,
}

extension ScalePatternSystemX on ScalePatternSystem {
  String get jsonValue => switch (this) {
        ScalePatternSystem.block => 'block',
        ScalePatternSystem.threeNps => 'threeNps',
        ScalePatternSystem.caged => 'caged',
        ScalePatternSystem.pentatonicBox => 'pentatonicBox',
        ScalePatternSystem.custom => 'custom',
      };

  static ScalePatternSystem fromJson(String? raw) =>
      ScalePatternSystem.values.firstWhere(
        (value) => value.jsonValue == raw,
        orElse: () => ScalePatternSystem.custom,
      );
}

enum ScalePatternStatus { draft, validated, published }

extension ScalePatternStatusX on ScalePatternStatus {
  String get jsonValue => switch (this) {
        ScalePatternStatus.draft => 'draft',
        ScalePatternStatus.validated => 'validated',
        ScalePatternStatus.published => 'published',
      };

  static ScalePatternStatus fromJson(String? raw) =>
      ScalePatternStatus.values.firstWhere(
        (value) => value.jsonValue == raw,
        orElse: () => ScalePatternStatus.draft,
      );
}

class ScalePatternNote {
  const ScalePatternNote({
    required this.stringNumber,
    required this.fret,
    this.interval,
    this.noteName,
    this.suggestedFinger,
  });

  factory ScalePatternNote.fromJson(Map<String, dynamic> json) {
    final stringNumber = (json['stringNumber'] as num?)?.toInt();
    final fret = (json['fret'] as num?)?.toInt();
    if (stringNumber == null || stringNumber < 1 || stringNumber > 12) {
      throw const FormatException(
          'ScalePatternNote.stringNumber must be 1..12');
    }
    if (fret == null || fret < 0 || fret > 24) {
      throw const FormatException('ScalePatternNote.fret must be 0..24');
    }
    final interval = (json['interval'] as num?)?.toInt();
    if (interval != null && (interval < 0 || interval > 24)) {
      throw const FormatException('ScalePatternNote.interval must be 0..24');
    }
    final suggestedFinger = (json['suggestedFinger'] as num?)?.toInt();
    if (suggestedFinger != null &&
        (suggestedFinger < 1 || suggestedFinger > 4)) {
      throw const FormatException(
          'ScalePatternNote.suggestedFinger must be 1..4');
    }
    return ScalePatternNote(
      stringNumber: stringNumber,
      fret: fret,
      interval: interval,
      noteName: json['noteName'] as String?,
      suggestedFinger: suggestedFinger,
    );
  }

  final int stringNumber;
  final int fret;
  final int? interval;
  final String? noteName;
  final int? suggestedFinger;

  Map<String, dynamic> toJson() => {
        'stringNumber': stringNumber,
        'fret': fret,
        if (interval != null) 'interval': interval,
        if (noteName != null) 'noteName': noteName,
        if (suggestedFinger != null) 'suggestedFinger': suggestedFinger,
      };
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
