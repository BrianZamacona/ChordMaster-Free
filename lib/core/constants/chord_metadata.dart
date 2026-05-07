import 'music_theory.dart';

/// Central metadata describing supported chord qualities and musical categories.
class ChordTypeDefinition {
  const ChordTypeDefinition({
    required this.key,
    required this.displayName,
    required this.shortLabel,
    required this.intervals,
    this.aliases = const [],
    this.defaultTags = const ['standard'],
    this.description,
    this.order = 0,
  });

  final String key;
  final String displayName;
  final String shortLabel;
  final List<int> intervals;
  final List<String> aliases;
  final List<String> defaultTags;
  final String? description;
  final int order;
}

const Map<String, String> chordTagLabels = {
  'standard': 'All-Purpose',
  'jazz': 'Jazz',
  'blues': 'Blues',
  'power': 'Power',
  'exotic': 'Exotic',
  'rock': 'Rock',
  'funk': 'Funk',
};

const List<String> chordPrimaryTagOrder = [
  'standard',
  'jazz',
  'blues',
  'power',
  'exotic',
  'rock',
  'funk',
];

const Map<String, ChordTypeDefinition> chordTypeMetadata = {
  'major': ChordTypeDefinition(
    key: 'major',
    displayName: 'Major',
    shortLabel: '',
    intervals: [0, 4, 7],
    defaultTags: ['standard'],
    description: 'Bright, stable major triad.',
    order: 0,
  ),
  'minor': ChordTypeDefinition(
    key: 'minor',
    displayName: 'Minor',
    shortLabel: 'm',
    intervals: [0, 3, 7],
    defaultTags: ['standard'],
    description: 'Darker minor triad with a melancholic color.',
    order: 1,
  ),
  'dominant7': ChordTypeDefinition(
    key: 'dominant7',
    displayName: 'Dominant 7th',
    shortLabel: '7',
    intervals: [0, 4, 7, 10],
    defaultTags: ['standard', 'blues', 'rock'],
    description: 'Classic tension chord for blues, rock, and cadences.',
    order: 2,
  ),
  'major7': ChordTypeDefinition(
    key: 'major7',
    displayName: 'Major 7th',
    shortLabel: 'maj7',
    intervals: [0, 4, 7, 11],
    defaultTags: ['standard', 'jazz'],
    description: 'Smooth and sophisticated major seventh sound.',
    order: 3,
  ),
  'minor7': ChordTypeDefinition(
    key: 'minor7',
    displayName: 'Minor 7th',
    shortLabel: 'm7',
    intervals: [0, 3, 7, 10],
    defaultTags: ['standard', 'jazz', 'blues'],
    description: 'Warm, modal minor seventh used across jazz and soul.',
    order: 4,
  ),
  'diminished': ChordTypeDefinition(
    key: 'diminished',
    displayName: 'Diminished',
    shortLabel: 'dim',
    intervals: [0, 3, 6],
    defaultTags: ['standard', 'jazz', 'exotic'],
    description: 'Tense diminished triad with unstable color.',
    order: 5,
  ),
  'augmented': ChordTypeDefinition(
    key: 'augmented',
    displayName: 'Augmented',
    shortLabel: 'aug',
    intervals: [0, 4, 8],
    defaultTags: ['standard', 'jazz', 'exotic'],
    description: 'Expansive augmented triad with raised fifth tension.',
    order: 6,
  ),
  'sus2': ChordTypeDefinition(
    key: 'sus2',
    displayName: 'Suspended 2nd',
    shortLabel: 'sus2',
    intervals: [0, 2, 7],
    defaultTags: ['standard', 'exotic'],
    description: 'Open suspended color replacing the third with a second.',
    order: 7,
  ),
  'sus4': ChordTypeDefinition(
    key: 'sus4',
    displayName: 'Suspended 4th',
    shortLabel: 'sus4',
    intervals: [0, 5, 7],
    defaultTags: ['standard', 'blues', 'rock', 'exotic'],
    description: 'Suspended fourth tension resolving naturally to major.',
    order: 8,
  ),
  'add9': ChordTypeDefinition(
    key: 'add9',
    displayName: 'Add 9',
    shortLabel: 'add9',
    intervals: [0, 4, 7, 14],
    defaultTags: ['standard', 'rock', 'exotic'],
    description: 'Major triad colored with a bright ninth.',
    order: 9,
  ),
  'sixth': ChordTypeDefinition(
    key: 'sixth',
    displayName: '6th',
    shortLabel: '6',
    intervals: [0, 4, 7, 9],
    defaultTags: ['standard', 'jazz', 'blues'],
    description: 'Swing-friendly major sixth voicing.',
    order: 10,
  ),
  'minor6': ChordTypeDefinition(
    key: 'minor6',
    displayName: 'Minor 6th',
    shortLabel: 'm6',
    intervals: [0, 3, 7, 9],
    defaultTags: ['jazz', 'exotic'],
    description: 'Minor chord with a bittersweet sixth extension.',
    order: 11,
  ),
  'sixth9': ChordTypeDefinition(
    key: 'sixth9',
    displayName: '6/9',
    shortLabel: '6/9',
    intervals: [0, 4, 7, 9, 14],
    defaultTags: ['jazz', 'blues'],
    description: 'Lush major sixth chord with added ninth color.',
    order: 12,
  ),
  'dominant9': ChordTypeDefinition(
    key: 'dominant9',
    displayName: 'Dominant 9th',
    shortLabel: '9',
    intervals: [0, 4, 7, 10, 14],
    defaultTags: ['jazz', 'blues', 'funk'],
    description: 'Extended dominant chord central to blues and funk comping.',
    order: 13,
  ),
  'major9': ChordTypeDefinition(
    key: 'major9',
    displayName: 'Major 9th',
    shortLabel: 'maj9',
    intervals: [0, 4, 7, 11, 14],
    defaultTags: ['jazz'],
    description: 'Glossy, modern major sound with a natural ninth.',
    order: 14,
  ),
  'minor9': ChordTypeDefinition(
    key: 'minor9',
    displayName: 'Minor 9th',
    shortLabel: 'm9',
    intervals: [0, 3, 7, 10, 14],
    defaultTags: ['jazz', 'blues'],
    description: 'Expressive minor ninth voicing used in neo-soul and jazz.',
    order: 15,
  ),
  'halfDiminished': ChordTypeDefinition(
    key: 'halfDiminished',
    displayName: 'Half-Diminished',
    shortLabel: 'm7b5',
    intervals: [0, 3, 6, 10],
    aliases: ['Half-Diminished', 'Minor 7 Flat 5'],
    defaultTags: ['jazz', 'exotic'],
    description: 'Minor seventh flat five sonority used in ii-V-i progressions.',
    order: 16,
  ),
  'diminished7': ChordTypeDefinition(
    key: 'diminished7',
    displayName: 'Diminished 7th',
    shortLabel: 'dim7',
    intervals: [0, 3, 6, 9],
    defaultTags: ['jazz', 'exotic'],
    description: 'Symmetrical diminished seventh with strong passing tension.',
    order: 17,
  ),
  'dominant7Sharp9': ChordTypeDefinition(
    key: 'dominant7Sharp9',
    displayName: '7#9',
    shortLabel: '7#9',
    intervals: [0, 4, 7, 10, 15],
    aliases: ['Hendrix Chord'],
    defaultTags: ['blues', 'jazz', 'rock', 'exotic'],
    description: 'Altered dominant color famous in Hendrix, blues, and fusion.',
    order: 18,
  ),
  'thirteenth': ChordTypeDefinition(
    key: 'thirteenth',
    displayName: '13th',
    shortLabel: '13',
    intervals: [0, 4, 7, 10, 14, 17, 21],
    defaultTags: ['jazz', 'blues', 'funk'],
    description: 'Full dominant extension with a smooth thirteenth color.',
    order: 19,
  ),
  'major7Sharp11': ChordTypeDefinition(
    key: 'major7Sharp11',
    displayName: 'Maj7#11',
    shortLabel: 'maj7#11',
    intervals: [0, 4, 7, 11, 18],
    defaultTags: ['jazz', 'exotic'],
    description: 'Lydian-flavored major seventh with raised eleventh shimmer.',
    order: 20,
  ),
  'dominant7Flat9': ChordTypeDefinition(
    key: 'dominant7Flat9',
    displayName: '7b9',
    shortLabel: '7b9',
    intervals: [0, 4, 7, 10, 13],
    defaultTags: ['jazz', 'exotic'],
    description: 'Altered dominant with a dramatic flat ninth bite.',
    order: 21,
  ),
  'minor11': ChordTypeDefinition(
    key: 'minor11',
    displayName: 'Minor 11th',
    shortLabel: 'm11',
    intervals: [0, 3, 7, 10, 14, 17],
    defaultTags: ['jazz', 'blues'],
    description: 'Modern minor extension blending ninth and eleventh color.',
    order: 22,
  ),
  'power5': ChordTypeDefinition(
    key: 'power5',
    displayName: 'Power Chord',
    shortLabel: '5',
    intervals: [0, 7],
    aliases: ['Power Chord'],
    defaultTags: ['power', 'rock', 'blues'],
    description: 'Root-and-fifth rock voicing with no third.',
    order: 23,
  ),
};

const List<String> allowedChordTags = [
  'standard',
  'jazz',
  'blues',
  'power',
  'exotic',
  'rock',
  'funk',
];

String chordTypeLabel(String type) =>
    chordTypeMetadata[type]?.displayName ?? chordQualityDisplayNames[type] ?? type;

String chordShortLabel(String type) =>
    chordTypeMetadata[type]?.shortLabel ?? chordTypeLabel(type);

List<String> chordAliases(String type, [List<String> explicitAliases = const []]) {
  final aliases = <String>[];
  for (final alias in [...?chordTypeMetadata[type]?.aliases, ...explicitAliases]) {
    final trimmed = alias.trim();
    if (trimmed.isEmpty || aliases.contains(trimmed)) continue;
    aliases.add(trimmed);
  }
  return aliases;
}

List<String> chordTags(String type, [List<String> explicitTags = const []]) {
  final ordered = <String>[];
  final merged = [
    ...?chordTypeMetadata[type]?.defaultTags,
    ...explicitTags,
  ];
  for (final tag in chordPrimaryTagOrder) {
    if (merged.contains(tag) && !ordered.contains(tag)) {
      ordered.add(tag);
    }
  }
  for (final tag in merged) {
    if (!ordered.contains(tag) && tag.trim().isNotEmpty) {
      ordered.add(tag);
    }
  }
  return ordered;
}

String chordTagLabel(String tag) => chordTagLabels[tag] ?? tag;

String chordDisplayName({
  required String root,
  required String type,
  String? explicitDisplayName,
}) {
  final trimmed = explicitDisplayName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  final shortLabel = chordShortLabel(type);
  if (shortLabel.isEmpty) return root;
  return '$root$shortLabel';
}

String? chordDescription(String type, [String? explicitDescription]) {
  final trimmed = explicitDescription?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return chordTypeMetadata[type]?.description;
}

List<ChordTypeDefinition> orderedChordTypes(Iterable<String> availableTypes) {
  final types = availableTypes.toSet().toList()
    ..sort((a, b) {
      final aOrder = chordTypeMetadata[a]?.order ?? 999;
      final bOrder = chordTypeMetadata[b]?.order ?? 999;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return a.compareTo(b);
    });
  return types
      .map((type) => chordTypeMetadata[type])
      .whereType<ChordTypeDefinition>()
      .toList(growable: false);
}
