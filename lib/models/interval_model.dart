/// Represents a musical interval with its theoretical and aural properties.
///
/// Used by the ear training module to teach interval recognition.
class IntervalModel {

  /// Creates an [IntervalModel] with all required fields.
  const IntervalModel({
    required this.name,
    required this.shortName,
    required this.semitones,
    required this.sound,
    required this.examples,
  });

  /// Deserialises an [IntervalModel] from a JSON map.
  factory IntervalModel.fromJson(Map<String, dynamic> json) => IntervalModel(
      name: json['name'] as String,
      shortName: json['shortName'] as String,
      semitones: json['semitones'] as int,
      sound: json['sound'] as String,
      examples: List<String>.from(json['examples'] as List),
    );
  /// Full name of the interval (e.g. `"Perfect Fifth"`).
  final String name;

  /// Abbreviated name (e.g. `"P5"`).
  final String shortName;

  /// Number of semitones in the interval.
  final int semitones;

  /// Description of the characteristic sound or feel of the interval.
  final String sound;

  /// Famous songs that open with or prominently feature this interval.
  final List<String> examples;

  /// Serialises this [IntervalModel] to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'shortName': shortName,
        'semitones': semitones,
        'sound': sound,
        'examples': examples,
      };

  /// Returns a copy of this [IntervalModel] with the specified fields replaced.
  IntervalModel copyWith({
    String? name,
    String? shortName,
    int? semitones,
    String? sound,
    List<String>? examples,
  }) => IntervalModel(
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      semitones: semitones ?? this.semitones,
      sound: sound ?? this.sound,
      examples: examples ?? this.examples,
    );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IntervalModel &&
        other.shortName == shortName &&
        other.semitones == semitones;
  }

  @override
  int get hashCode => Object.hash(shortName, semitones);

  @override
  String toString() =>
      'IntervalModel(name: $name, shortName: $shortName, semitones: $semitones)';
}

/// The standard set of twelve intervals used in ear training exercises.
const List<Map<String, dynamic>> defaultIntervals = [
  {
    'name': 'Unison',
    'shortName': 'P1',
    'semitones': 0,
    'sound': 'Same pitch — complete stillness',
    'examples': ['Same note played twice'],
  },
  {
    'name': 'Minor 2nd',
    'shortName': 'm2',
    'semitones': 1,
    'sound': 'Tense, dissonant, half-step clash',
    'examples': ['Jaws Theme', 'Pink Panther Theme'],
  },
  {
    'name': 'Major 2nd',
    'shortName': 'M2',
    'semitones': 2,
    'sound': 'Bright step, slightly open',
    'examples': ['Happy Birthday (opening)', 'Frère Jacques'],
  },
  {
    'name': 'Minor 3rd',
    'shortName': 'm3',
    'semitones': 3,
    'sound': 'Melancholy, minor feel',
    'examples': ['Smoke on the Water', 'Greensleeves'],
  },
  {
    'name': 'Major 3rd',
    'shortName': 'M3',
    'semitones': 4,
    'sound': 'Bright, happy, open',
    'examples': ['When the Saints Go Marching In', 'Oh! Susanna'],
  },
  {
    'name': 'Perfect 4th',
    'shortName': 'P4',
    'semitones': 5,
    'sound': 'Strong, somewhat suspended',
    'examples': ['Here Comes the Bride', 'Amazing Grace'],
  },
  {
    'name': 'Tritone',
    'shortName': 'TT',
    'semitones': 6,
    'sound': 'Unstable, dissonant, restless',
    'examples': ['The Simpsons Theme', 'Maria (West Side Story)'],
  },
  {
    'name': 'Perfect 5th',
    'shortName': 'P5',
    'semitones': 7,
    'sound': 'Powerful, stable, open',
    'examples': ['Star Wars Theme', 'Twinkle Twinkle Little Star'],
  },
  {
    'name': 'Minor 6th',
    'shortName': 'm6',
    'semitones': 8,
    'sound': 'Bittersweet, slightly dark',
    'examples': ['The Entertainer', 'Theme from Schindler\'s List'],
  },
  {
    'name': 'Major 6th',
    'shortName': 'M6',
    'semitones': 9,
    'sound': 'Warm, nostalgic, sweet',
    'examples': ['My Bonnie Lies Over the Ocean', 'NBC Chime'],
  },
  {
    'name': 'Minor 7th',
    'shortName': 'm7',
    'semitones': 10,
    'sound': 'Bluesy, jazzy, unresolved',
    'examples': ['Somewhere (West Side Story)', 'Star Trek Theme'],
  },
  {
    'name': 'Major 7th',
    'shortName': 'M7',
    'semitones': 11,
    'sound': 'Dreamy, slightly tense, romantic',
    'examples': ['Take On Me', 'Don\'t Know Why'],
  },
  {
    'name': 'Octave',
    'shortName': 'P8',
    'semitones': 12,
    'sound': 'Complete resolution, same pitch class',
    'examples': ['Somewhere Over the Rainbow', 'Singing in the Rain'],
  },
];
