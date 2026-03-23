// ignore_for_file: invalid_annotation_target
import 'package:hive/hive.dart';

part 'chord.g.dart';

/// Represents a guitar chord with its theory, fingering, and metadata.
///
/// Chord objects are stored persistently via Hive (type id 0) and can be
/// serialised to/from JSON for asset bundling and network interchange.
@HiveType(typeId: 0)
class Chord {
  /// Display name of the chord (e.g. `"C Major"`).
  @HiveField(0)
  final String name;

  /// Root note of the chord (e.g. `"C"`).
  @HiveField(1)
  final String root;

  /// Quality / type of the chord (e.g. `"major"`, `"minor7"`).
  @HiveField(2)
  final String type;

  /// Semitone intervals that make up the chord, relative to the root.
  @HiveField(3)
  final List<int> intervals;

  /// Six fret positions, one per guitar string (low E → high E).
  ///
  /// `-1` means the string is muted; `0` means open.
  @HiveField(4)
  final List<int> fretPositions;

  /// Suggested finger numbers (1–4) for each fret position.
  ///
  /// `0` means no finger (open or muted).
  @HiveField(5)
  final List<int> fingerPositions;

  /// Optional path to a bundled audio preview file.
  @HiveField(6)
  final String? audioFile;

  /// Subjective difficulty rating from 1 (easy) to 5 (expert).
  @HiveField(7)
  final int difficulty;

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
  });

  /// Deserialises a [Chord] from a JSON map.
  factory Chord.fromJson(Map<String, dynamic> json) {
    return Chord(
      name: json['name'] as String,
      root: json['root'] as String,
      type: json['type'] as String,
      intervals: List<int>.from(json['intervals'] as List),
      fretPositions: List<int>.from(json['fretPositions'] as List),
      fingerPositions: List<int>.from(json['fingerPositions'] as List),
      audioFile: json['audioFile'] as String?,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }

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
      };

  /// Sentinel used by [copyWith] to distinguish "clear to null" from "keep existing".
  static const Object _unset = Object();

  /// Returns a copy of this [Chord] with the specified fields replaced.
  ///
  /// To explicitly clear the optional [audioFile] field, pass
  /// `audioFile: null` together with `clearAudioFile: true`.
  Chord copyWith({
    String? name,
    String? root,
    String? type,
    List<int>? intervals,
    List<int>? fretPositions,
    List<int>? fingerPositions,
    Object? audioFile = _unset,
    int? difficulty,
  }) {
    return Chord(
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
    );
  }

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
  String toString() => 'Chord(name: $name, root: $root, type: $type, difficulty: $difficulty)';
}
