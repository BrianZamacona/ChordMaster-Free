// ignore_for_file: invalid_annotation_target
import 'package:hive/hive.dart';

part 'song.g.dart';

/// Represents a song in the ChordMaster Free song library.
///
/// Stored persistently via Hive (type id 4) and serialisable to/from JSON.
@HiveType(typeId: 4)
class Song {

  /// Creates a [Song] with all required fields.
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.chordProgression,
    required this.strummingPattern,
    required this.tempo,
    required this.timeSignature,
    this.difficulty = 1,
    this.notes = '',
  });

  /// Deserialises a [Song] from a JSON map.
  factory Song.fromJson(Map<String, dynamic> json) => Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      genre: json['genre'] as String,
      chordProgression: List<String>.from(json['chordProgression'] as List),
      strummingPattern: json['strummingPattern'] as String,
      tempo: json['tempo'] as int,
      timeSignature: json['timeSignature'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
    );
  /// Unique identifier (UUID).
  @HiveField(0)
  final String id;

  /// Song title.
  @HiveField(1)
  final String title;

  /// Artist or band name.
  @HiveField(2)
  final String artist;

  /// Musical genre (e.g. `"Rock"`, `"Jazz"`).
  @HiveField(3)
  final String genre;

  /// Ordered list of chord names that make up the main progression.
  @HiveField(4)
  final List<String> chordProgression;

  /// Text description of the strumming pattern (e.g. `"D DU UDU"`).
  @HiveField(5)
  final String strummingPattern;

  /// Song tempo in beats per minute.
  @HiveField(6)
  final int tempo;

  /// Time signature as a string (e.g. `"4/4"`, `"3/4"`).
  @HiveField(7)
  final String timeSignature;

  /// Subjective difficulty rating from 1 (beginner) to 5 (expert).
  @HiveField(8)
  final int difficulty;

  /// Freeform practice notes for the learner.
  @HiveField(9)
  final String notes;

  /// Serialises this [Song] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'genre': genre,
        'chordProgression': chordProgression,
        'strummingPattern': strummingPattern,
        'tempo': tempo,
        'timeSignature': timeSignature,
        'difficulty': difficulty,
        'notes': notes,
      };

  /// Returns a copy of this [Song] with the specified fields replaced.
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? genre,
    List<String>? chordProgression,
    String? strummingPattern,
    int? tempo,
    String? timeSignature,
    int? difficulty,
    String? notes,
  }) => Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      chordProgression: chordProgression ?? this.chordProgression,
      strummingPattern: strummingPattern ?? this.strummingPattern,
      tempo: tempo ?? this.tempo,
      timeSignature: timeSignature ?? this.timeSignature,
      difficulty: difficulty ?? this.difficulty,
      notes: notes ?? this.notes,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Song(id: $id, title: $title, artist: $artist, tempo: $tempo bpm)';
}
