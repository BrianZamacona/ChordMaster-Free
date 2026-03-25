/// Represents a Greek / church mode with its theoretical properties.
///
/// Serializable to/from JSON for assets and Hive-backed storage.
class Mode {

  /// Creates a [Mode] with all required fields.
  const Mode({
    required this.name,
    required this.degree,
    required this.intervals,
    required this.mood,
    required this.examples,
    required this.parentScale,
  });

  /// Deserialises a [Mode] from a JSON map.
  factory Mode.fromJson(Map<String, dynamic> json) => Mode(
      name: json['name'] as String,
      degree: json['degree'] as int,
      intervals: List<int>.from(json['intervals'] as List),
      mood: json['mood'] as String,
      examples: List<String>.from(json['examples'] as List),
      parentScale: json['parentScale'] as String,
    );
  /// Display name of the mode (e.g. `"Dorian"`).
  final String name;

  /// Modal degree relative to the parent major scale (1–7).
  final int degree;

  /// Semitone intervals from the tonic.
  final List<int> intervals;

  /// Emotional / tonal character description (e.g. `"dark, mysterious"`).
  final String mood;

  /// Well-known songs or pieces that prominently feature this mode.
  final List<String> examples;

  /// The name of the parent major scale this mode is derived from.
  final String parentScale;

  /// Serialises this [Mode] to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'degree': degree,
        'intervals': intervals,
        'mood': mood,
        'examples': examples,
        'parentScale': parentScale,
      };

  /// Returns a copy of this [Mode] with the specified fields replaced.
  Mode copyWith({
    String? name,
    int? degree,
    List<int>? intervals,
    String? mood,
    List<String>? examples,
    String? parentScale,
  }) => Mode(
      name: name ?? this.name,
      degree: degree ?? this.degree,
      intervals: intervals ?? this.intervals,
      mood: mood ?? this.mood,
      examples: examples ?? this.examples,
      parentScale: parentScale ?? this.parentScale,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mode && other.name == name && other.degree == degree;
  }

  @override
  int get hashCode => Object.hash(name, degree);

  @override
  String toString() => 'Mode(name: $name, degree: $degree, parentScale: $parentScale)';
}
