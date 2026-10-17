// Índice de cuerda 0 = 1ª cuerda (mi aguda).
const noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', //
];
const openStringMidi = [64, 59, 55, 50, 45, 40];

const _majorScaleSteps = [0, 2, 4, 5, 7, 9, 11];
const _intervalLabels = [
  '1', 'b2', '2', 'b3', '3', '4', 'b5', '5', 'b6', '6', 'b7', '7', //
];

enum DiatonicDoubleStopInterval {
  second('2nd'),
  third('3rd'),
  fourth('4th'),
  fifth('5th'),
  sixth('6th'),
  seventh('7th');

  const DiatonicDoubleStopInterval(this.label);

  final String label;

  static DiatonicDoubleStopInterval fromLabel(String label) =>
      values.firstWhere((v) => v.label == label);
}

enum DoubleStopStringPattern {
  adjacent,
  skipOne;

  static DoubleStopStringPattern fromLabel(String label) =>
      label == 'skip-one' ? skipOne : adjacent;
}

class FretRange {
  const FretRange(this.start, this.end);

  final int start;
  final int end;
}

class FretMark {
  const FretMark({
    required this.stringIndex,
    required this.fret,
    required this.note,
    required this.interval,
  });

  final int stringIndex;
  final int fret;
  final String note;
  final String interval;
}

class DoubleStopPair {
  const DoubleStopPair({
    required this.root,
    required this.interval,
    required this.distance,
    required this.quality,
    this.degree,
  });

  final FretMark root;
  final FretMark interval;
  final int distance;
  final String quality;
  final int? degree;
}

class DoubleStopGroup {
  DoubleStopGroup(this.stringPair) : pairs = [];

  final (int, int) stringPair;
  final List<DoubleStopPair> pairs;
}

class _IntervalDef {
  const _IntervalDef(this.distance, this.quality);

  final int distance;
  final String quality;
}

const _diatonicDefaultPattern = {
  DiatonicDoubleStopInterval.second: DoubleStopStringPattern.adjacent,
  DiatonicDoubleStopInterval.third: DoubleStopStringPattern.adjacent,
  DiatonicDoubleStopInterval.fourth: DoubleStopStringPattern.adjacent,
  DiatonicDoubleStopInterval.fifth: DoubleStopStringPattern.adjacent,
  DiatonicDoubleStopInterval.sixth: DoubleStopStringPattern.skipOne,
  DiatonicDoubleStopInterval.seventh: DoubleStopStringPattern.skipOne,
};

const _diatonicIntervals = {
  DiatonicDoubleStopInterval.second: [
    _IntervalDef(2, '2ª mayor'),
    _IntervalDef(2, '2ª mayor'),
    _IntervalDef(1, '2ª menor'),
    _IntervalDef(2, '2ª mayor'),
    _IntervalDef(2, '2ª mayor'),
    _IntervalDef(2, '2ª mayor'),
    _IntervalDef(1, '2ª menor'),
  ],
  DiatonicDoubleStopInterval.third: [
    _IntervalDef(4, '3ª mayor'),
    _IntervalDef(3, '3ª menor'),
    _IntervalDef(3, '3ª menor'),
    _IntervalDef(4, '3ª mayor'),
    _IntervalDef(4, '3ª mayor'),
    _IntervalDef(3, '3ª menor'),
    _IntervalDef(3, '3ª menor'),
  ],
  DiatonicDoubleStopInterval.fourth: [
    _IntervalDef(5, '4ª justa'),
    _IntervalDef(5, '4ª justa'),
    _IntervalDef(5, '4ª justa'),
    _IntervalDef(6, '4ª aumentada'),
    _IntervalDef(5, '4ª justa'),
    _IntervalDef(5, '4ª justa'),
    _IntervalDef(5, '4ª justa'),
  ],
  DiatonicDoubleStopInterval.fifth: [
    _IntervalDef(7, '5ª justa'),
    _IntervalDef(7, '5ª justa'),
    _IntervalDef(7, '5ª justa'),
    _IntervalDef(7, '5ª justa'),
    _IntervalDef(7, '5ª justa'),
    _IntervalDef(7, '5ª justa'),
    _IntervalDef(6, '5ª disminuida'),
  ],
  DiatonicDoubleStopInterval.sixth: [
    _IntervalDef(9, '6ª mayor'),
    _IntervalDef(9, '6ª mayor'),
    _IntervalDef(8, '6ª menor'),
    _IntervalDef(9, '6ª mayor'),
    _IntervalDef(9, '6ª mayor'),
    _IntervalDef(8, '6ª menor'),
    _IntervalDef(8, '6ª menor'),
  ],
  DiatonicDoubleStopInterval.seventh: [
    _IntervalDef(11, '7ª mayor'),
    _IntervalDef(10, '7ª menor'),
    _IntervalDef(10, '7ª menor'),
    _IntervalDef(11, '7ª mayor'),
    _IntervalDef(10, '7ª menor'),
    _IntervalDef(10, '7ª menor'),
    _IntervalDef(9, '7ª disminuida'),
  ],
};

int noteIndex(String note) => noteNames.indexOf(note);

String noteAt(int stringIndex, int fret) =>
    noteNames[(openStringMidi[stringIndex] + fret) % 12];

String intervalLabel(int interval) =>
    interval >= 0 && interval < 12 ? _intervalLabels[interval] : '';

String _qualityForDistance(int distance) =>
    const {
      1: '2ª menor',
      2: '2ª mayor',
      3: '3ª menor',
      4: '3ª mayor',
      5: '4ª justa',
      6: '4ª aumentada',
      7: '5ª justa',
      8: '6ª menor',
      9: '6ª mayor',
      10: '7ª menor',
      11: '7ª mayor',
    }[distance] ??
    '$distance semitonos';

List<(int, int)> _stringPairs(DoubleStopStringPattern pattern) =>
    pattern == DoubleStopStringPattern.adjacent
    ? [for (var i = 0; i < 5; i++) (i, i + 1)]
    : [for (var i = 0; i < 4; i++) (i, i + 2)];

List<DoubleStopGroup> _search(
  String root,
  int distance,
  String quality,
  FretRange range,
  DoubleStopStringPattern pattern,
  int? degree,
) {
  final rootIndex = noteIndex(root);
  if (rootIndex < 0 || distance <= 0 || distance >= 12) return [];
  final groups = [for (final pair in _stringPairs(pattern)) DoubleStopGroup(pair)];

  for (final group in groups) {
    final (companionString, baseString) = group.stringPair;
    for (var fret = range.start; fret <= range.end; fret++) {
      final rootPitch = openStringMidi[baseString] + fret;
      final baseDistance = (rootPitch - rootIndex + 12) % 12;
      if (baseDistance != 0) continue;
      for (var cf = range.start; cf <= range.end; cf++) {
        final intervalPitch = openStringMidi[companionString] + cf;
        if (intervalPitch - rootPitch != distance) continue;
        if ((cf - fret).abs() > 4 && fret != 0 && cf != 0) continue;
        group.pairs.add(
          DoubleStopPair(
            root: FretMark(
              stringIndex: baseString,
              fret: fret,
              note: noteAt(baseString, fret),
              interval: intervalLabel(baseDistance),
            ),
            interval: FretMark(
              stringIndex: companionString,
              fret: cf,
              note: noteAt(companionString, cf),
              interval: intervalLabel(distance),
            ),
            distance: distance,
            quality: quality,
            degree: degree,
          ),
        );
      }
    }
  }
  return groups;
}

List<DoubleStopGroup> findDoubleStopPairs(
  String root,
  int distance,
  FretRange range, [
  DoubleStopStringPattern pattern = DoubleStopStringPattern.adjacent,
]) => _search(root, distance, _qualityForDistance(distance), range, pattern, null);

List<DoubleStopGroup> findDiatonicDoubleStopPairs(
  String key,
  DiatonicDoubleStopInterval intervalType,
  FretRange range, [
  DoubleStopStringPattern? pattern,
]) {
  final keyIndex = noteIndex(key);
  if (keyIndex < 0) return [];
  final resolved = pattern ?? _diatonicDefaultPattern[intervalType]!;
  final groups = [for (final pair in _stringPairs(resolved)) DoubleStopGroup(pair)];
  final defs = _diatonicIntervals[intervalType]!;
  for (var index = 0; index < defs.length; index++) {
    final degreeRoot = noteNames[(keyIndex + _majorScaleSteps[index]) % 12];
    final degreeGroups = _search(
      degreeRoot,
      defs[index].distance,
      defs[index].quality,
      range,
      resolved,
      index + 1,
    );
    for (var g = 0; g < degreeGroups.length; g++) {
      groups[g].pairs.addAll(degreeGroups[g].pairs);
    }
  }
  return groups;
}
