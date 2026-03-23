// ignore_for_file: invalid_annotation_target
import 'package:hive/hive.dart';

part 'progression.g.dart';

/// Represents a chord progression with its theoretical context.
///
/// Stored persistently via Hive (type id 3) and serialisable to/from JSON.
@HiveType(typeId: 3)
class Progression {
  /// Unique identifier (UUID).
  @HiveField(0)
  final String id;

  /// Display name of the progression (e.g. `"I–V–vi–IV"`).
  @HiveField(1)
  final String name;

  /// Musical style or genre (e.g. `"Pop"`, `"Jazz"`, `"Blues"`).
  @HiveField(2)
  final String style;

  /// Roman numeral notation for each chord in the progression.
  @HiveField(3)
  final List<String> numerals;

  /// Concrete chord names in the current [key] (e.g. `["C", "G", "Am", "F"]`).
  @HiveField(4)
  final List<String> chords;

  /// The tonic / key note (e.g. `"C"`).
  @HiveField(5)
  final String key;

  /// Whether the progression is in a major (`true`) or minor (`false`) key.
  @HiveField(6)
  final bool isMajor;

  /// Creates a [Progression] with all required fields.
  const Progression({
    required this.id,
    required this.name,
    required this.style,
    required this.numerals,
    required this.chords,
    required this.key,
    required this.isMajor,
  });

  /// Deserialises a [Progression] from a JSON map.
  factory Progression.fromJson(Map<String, dynamic> json) {
    return Progression(
      id: json['id'] as String,
      name: json['name'] as String,
      style: json['style'] as String,
      numerals: List<String>.from(json['numerals'] as List),
      chords: List<String>.from(json['chords'] as List),
      key: json['key'] as String,
      isMajor: json['isMajor'] as bool,
    );
  }

  /// Serialises this [Progression] to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style,
        'numerals': numerals,
        'chords': chords,
        'key': key,
        'isMajor': isMajor,
      };

  /// Returns a copy of this [Progression] with the specified fields replaced.
  Progression copyWith({
    String? id,
    String? name,
    String? style,
    List<String>? numerals,
    List<String>? chords,
    String? key,
    bool? isMajor,
  }) {
    return Progression(
      id: id ?? this.id,
      name: name ?? this.name,
      style: style ?? this.style,
      numerals: numerals ?? this.numerals,
      chords: chords ?? this.chords,
      key: key ?? this.key,
      isMajor: isMajor ?? this.isMajor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Progression && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Progression(id: $id, name: $name, key: $key, isMajor: $isMajor)';
}
