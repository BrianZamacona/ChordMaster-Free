import 'note_coordinate.dart';

/// Strongly-typed scale shape with strict fretboard coordinates.
class ScalePattern {
  /// Creates a scale pattern with precomputed coordinates.
  const ScalePattern({
    required this.scaleName,
    required this.root,
    required this.patternType,
    required this.positionName,
    required this.startingFret,
    required this.fretsSpan,
    required this.coordinates,
  });

  /// Parses [ScalePattern] from strict JSON contract.
  factory ScalePattern.fromJson(Map<String, dynamic> json) {
    final scaleName = _readRequiredString(json, 'scale_name');
    final root = _readRequiredString(json, 'root');
    final patternType = _readRequiredString(json, 'pattern_type');
    final positionName = _readRequiredString(json, 'position_name');
    final startingFret = _readRequiredInt(json, 'starting_fret');
    final fretsSpan = _readRequiredInt(json, 'frets_span');

    if (startingFret < 0) {
      throw const FormatException('starting_fret must be >= 0');
    }
    if (fretsSpan < 1) {
      throw const FormatException('frets_span must be >= 1');
    }

    final rawCoordinates = json['coordinates'];
    if (rawCoordinates is! List) {
      throw const FormatException('coordinates must be a list');
    }

    final coordinates = rawCoordinates
        .map((entry) {
          if (entry is! Map) {
            throw const FormatException('coordinates must contain objects');
          }
          return NoteCoordinate.fromJson(Map<String, dynamic>.from(entry));
        })
        .toList(growable: false);

    return ScalePattern(
      scaleName: scaleName,
      root: root,
      patternType: patternType,
      positionName: positionName,
      startingFret: startingFret,
      fretsSpan: fretsSpan,
      coordinates: coordinates,
    );
  }

  /// Human-readable scale label (e.g. "Major").
  final String scaleName;

  /// Root note for this shape (e.g. "C").
  final String root;

  /// Pattern family (e.g. "CAGED", "3NPS").
  final String patternType;

  /// Position/shape display name.
  final String positionName;

  /// First absolute fret displayed by the diagram grid.
  final int startingFret;

  /// Number of fret spaces to render from [startingFret].
  final int fretsSpan;

  /// Strict note coordinates to draw.
  final List<NoteCoordinate> coordinates;

  Map<String, dynamic> toJson() => {
        'scale_name': scaleName,
        'root': root,
        'pattern_type': patternType,
        'position_name': positionName,
        'starting_fret': startingFret,
        'frets_span': fretsSpan,
        'coordinates': coordinates.map((entry) => entry.toJson()).toList(),
      };

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  static int _readRequiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException('$key must be a number');
    }
    return value.toInt();
  }
}
