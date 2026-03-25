// ignore_for_file: invalid_annotation_target
import 'package:hive/hive.dart';

part 'scale.g.dart';

/// Represents a musical scale with its theory metadata.
///
/// Stored persistently via Hive (type id 1) and serialisable to/from JSON.
@HiveType(typeId: 1)
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
  });

  /// Deserialises a [Scale] from a JSON map.
  factory Scale.fromJson(Map<String, dynamic> json) => Scale(
      name: json['name'] as String,
      root: json['root'] as String,
      type: json['type'] as String,
      intervals: List<int>.from(json['intervals'] as List),
      description: json['description'] as String,
      relatedChords: List<String>.from(json['relatedChords'] as List),
      commonUsage: json['commonUsage'] as String,
    );
  /// Display name of the scale (e.g. `"C Major"`).
  @HiveField(0)
  final String name;

  /// Root note (e.g. `"C"`).
  @HiveField(1)
  final String root;

  /// Scale type key matching [scaleFormulas] (e.g. `"major"`).
  @HiveField(2)
  final String type;

  /// Semitone intervals from the root.
  @HiveField(3)
  final List<int> intervals;

  /// Short description of the scale's sound / character.
  @HiveField(4)
  final String description;

  /// Names of chords naturally derived from this scale.
  @HiveField(5)
  final List<String> relatedChords;

  /// Description of common musical contexts where this scale is used.
  @HiveField(6)
  final String commonUsage;

  /// Serialises this [Scale] to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'root': root,
        'type': type,
        'intervals': intervals,
        'description': description,
        'relatedChords': relatedChords,
        'commonUsage': commonUsage,
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
  }) => Scale(
      name: name ?? this.name,
      root: root ?? this.root,
      type: type ?? this.type,
      intervals: intervals ?? this.intervals,
      description: description ?? this.description,
      relatedChords: relatedChords ?? this.relatedChords,
      commonUsage: commonUsage ?? this.commonUsage,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scale && other.name == name && other.root == root && other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, root, type);

  @override
  String toString() => 'Scale(name: $name, root: $root, type: $type)';
}
