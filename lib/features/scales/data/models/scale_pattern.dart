import 'note_coordinate.dart';

/// A guitar fingering pattern for a scale, with strict fretboard coordinates.
/// Coordinates are generated algorithmically — never written by hand.
class ScalePattern {
  const ScalePattern({
    required this.scaleName,
    required this.root,
    required this.patternType,
    required this.positionName,
    required this.startingFret,
    required this.fretsSpan,
    required this.coordinates,
  });

  factory ScalePattern.fromJson(Map<String, dynamic> json) {
    final startingFret = _readInt(json, 'starting_fret');
    final fretsSpan = _readInt(json, 'frets_span');

    if (startingFret < 0) throw const FormatException('starting_fret must be >= 0');
    if (fretsSpan < 1) throw const FormatException('frets_span must be >= 1');

    final rawCoords = json['coordinates'];
    if (rawCoords is! List) throw const FormatException('coordinates must be a list');

    return ScalePattern(
      scaleName: _readString(json, 'scale_name'),
      root: _readString(json, 'root'),
      patternType: _readString(json, 'pattern_type'),
      positionName: _readString(json, 'position_name'),
      startingFret: startingFret,
      fretsSpan: fretsSpan,
      coordinates: rawCoords
          .map((e) => NoteCoordinate.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }

  /// Human-readable scale label (e.g. "Major", "Pentatonic Minor").
  final String scaleName;

  /// Root note for this shape (e.g. "C", "F#").
  final String root;

  /// Fingering system (e.g. "CAGED", "3NPS", "Berklee", "Posicional").
  final String patternType;

  /// Display name for this specific position/shape.
  final String positionName;

  /// First fret shown in the diagram grid.
  final int startingFret;

  /// Number of fret spaces rendered from [startingFret].
  final int fretsSpan;

  /// Computed note positions to draw on the fretboard.
  final List<NoteCoordinate> coordinates;

  Map<String, dynamic> toJson() => {
        'scale_name': scaleName,
        'root': root,
        'pattern_type': patternType,
        'position_name': positionName,
        'starting_fret': startingFret,
        'frets_span': fretsSpan,
        'coordinates': coordinates.map((c) => c.toJson()).toList(),
      };

  ScalePattern copyWith({
    String? scaleName,
    String? root,
    String? patternType,
    String? positionName,
    int? startingFret,
    int? fretsSpan,
    List<NoteCoordinate>? coordinates,
  }) =>
      ScalePattern(
        scaleName: scaleName ?? this.scaleName,
        root: root ?? this.root,
        patternType: patternType ?? this.patternType,
        positionName: positionName ?? this.positionName,
        startingFret: startingFret ?? this.startingFret,
        fretsSpan: fretsSpan ?? this.fretsSpan,
        coordinates: coordinates ?? this.coordinates,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScalePattern &&
          other.scaleName == scaleName &&
          other.root == root &&
          other.patternType == patternType &&
          other.positionName == positionName;

  @override
  int get hashCode => Object.hash(scaleName, root, patternType, positionName);

  @override
  String toString() =>
      'ScalePattern($patternType | $root $scaleName | $positionName | fret $startingFret–${startingFret + fretsSpan})';

  static String _readString(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is! String || v.trim().isEmpty) throw FormatException('$key must be a non-empty string');
    return v;
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is! num) throw FormatException('$key must be a number');
    return v.toInt();
  }
}
