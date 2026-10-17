const _majorDegrees = {
  'I': (semitones: 0, type: 'major'),
  'ii': (semitones: 2, type: 'minor'),
  'iii': (semitones: 4, type: 'minor'),
  'IV': (semitones: 5, type: 'major'),
  'V': (semitones: 7, type: 'major'),
  'vi': (semitones: 9, type: 'minor'),
  'vii°': (semitones: 11, type: 'diminished'),
};

class ProgressionDegree {
  const ProgressionDegree(this.numeral, this.semitones, this.type);

  final String numeral;

  /// Semitonos desde la tónica.
  final int semitones;

  /// Valor `type` de chords.json (`major`, `minor`, `diminished`).
  final String type;
}

class Progression {
  Progression(this.id, this.label, List<String> numerals)
    : degrees = [
        for (final n in numerals)
          ProgressionDegree(
            n,
            _majorDegrees[n]!.semitones,
            _majorDegrees[n]!.type,
          ),
      ];

  final String id;
  final String label;
  final List<ProgressionDegree> degrees;
}

final progressions = [
  Progression('v1-1', 'I - vi - IV - V', ['I', 'vi', 'IV', 'V']),
  Progression('v1-2', 'I - V - vi - IV', ['I', 'V', 'vi', 'IV']),
  Progression('v1-3', 'I - IV - V', ['I', 'IV', 'V']),
  Progression('v2-1', 'I - vi - ii - V', ['I', 'vi', 'ii', 'V']),
  Progression('v2-2', 'I - IV - vi - V', ['I', 'IV', 'vi', 'V']),
  Progression('v2-3', 'I - IV - I - V', ['I', 'IV', 'I', 'V']),
  Progression('v3-1', 'I - V - vi - iii', ['I', 'V', 'vi', 'iii']),
  Progression('v3-2', 'I - IV - ii - V', ['I', 'IV', 'ii', 'V']),
  Progression('v3-3', 'I - iii - IV - V', ['I', 'iii', 'IV', 'V']),
];
