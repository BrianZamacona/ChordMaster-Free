import 'models/note_coordinate.dart';
import 'models/scale_pattern.dart';

// Standard tuning: open string semitone for each string.
// Index 0 = string 1 (low E = 4 semitones from C).
const List<int> _standardTuning = [4, 9, 2, 7, 11, 4];

const List<String> _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F',
  'F#', 'G', 'G#', 'A', 'A#', 'B',
];

const Map<int, String> _intervalNames = {
  0: '1',   1: 'b2',  2: '2',   3: 'b3',
  4: '3',   5: '4',   6: 'b5',  7: '5',
  8: 'b6',  9: '6',  10: 'b7', 11: '7',
};

int _noteAt(int stringNum, int fret) =>
    (_standardTuning[stringNum - 1] + fret) % 12;

int _rootSemitone(String root) {
  final idx = _noteNames.indexOf(root);
  if (idx == -1) throw ArgumentError('Unknown root: $root');
  return idx;
}

String _noteName(int semitone) => _noteNames[semitone % 12];
String _intervalName(int semitone) => _intervalNames[semitone % 12] ?? '?';

NoteCoordinate? _coord(
  int stringNum,
  int fret,
  int rootNote,
  Set<int> scaleSet,
  List<int> intervals,
) {
  final note = _noteAt(stringNum, fret);
  if (!scaleSet.contains(note)) return null;
  final semitoneFromRoot = (note - rootNote + 12) % 12;
  return NoteCoordinate(
    string: stringNum,
    fret: fret,
    isRoot: note == rootNote,
    note: _noteName(note),
    interval: _intervalName(semitoneFromRoot),
  );
}

({int startingFret, int fretsSpan}) _bounds(List<NoteCoordinate> coords) {
  if (coords.isEmpty) return (startingFret: 0, fretsSpan: 4);
  final frets = coords.map((c) => c.fret);
  final min = frets.reduce((a, b) => a < b ? a : b);
  final max = frets.reduce((a, b) => a > b ? a : b);
  return (startingFret: min, fretsSpan: (max - min).clamp(1, 24));
}

class ScalePatternGenerator {
  ScalePatternGenerator._();

  // 1. POSITIONAL — base for all systems
  static ScalePattern positional({
    required String scaleName,
    required String root,
    required List<int> intervals,
    required int startFret,
    int fretsSpan = 4,
    String patternType = 'Posicional',
    String positionName = '',
  }) {
    final rootNote = _rootSemitone(root);
    final scaleSet = intervals.map((i) => (rootNote + i) % 12).toSet();
    final coords = <NoteCoordinate>[];

    for (var s = 1; s <= 6; s++) {
      for (var f = startFret; f <= startFret + fretsSpan; f++) {
        final c = _coord(s, f, rootNote, scaleSet, intervals);
        if (c != null) coords.add(c);
      }
    }

    return ScalePattern(
      scaleName: scaleName,
      root: root,
      patternType: patternType,
      positionName: positionName.isEmpty
          ? '$root $scaleName — fret $startFret'
          : positionName,
      startingFret: startFret,
      fretsSpan: fretsSpan,
      coordinates: coords,
    );
  }

  // 2. CAGED — 5 shapes
  static List<ScalePattern> caged({
    required String scaleName,
    required String root,
    required List<int> intervals,
  }) {
    final rootNote = _rootSemitone(root);
    const cagedOffsets = [0, 2, 5, 7, 10];
    const cagedNames = ['C', 'A', 'G', 'E', 'D'];

    return List.generate(5, (i) {
      var startFret = (cagedOffsets[i] + rootNote) % 12;
      if (startFret == 0) startFret = 12;
      if (startFret > 12) startFret -= 12;

      return positional(
        scaleName: scaleName,
        root: root,
        intervals: intervals,
        startFret: startFret,
        fretsSpan: 4,
        patternType: 'CAGED',
        positionName: 'Forma ${cagedNames[i]} — traste $startFret',
      );
    });
  }

  // 3. THREE NOTES PER STRING (3NPS) — single pattern
  static ScalePattern threeNps({
    required String scaleName,
    required String root,
    required List<int> intervals,
    required int startFret,
    String positionName = '',
  }) {
    final rootNote = _rootSemitone(root);
    final scaleSet = intervals.map((i) => (rootNote + i) % 12).toSet();
    final coords = <NoteCoordinate>[];

    for (var s = 1; s <= 6; s++) {
      var count = 0;
      for (var f = startFret; f <= startFret + 8 && count < 3; f++) {
        final c = _coord(s, f, rootNote, scaleSet, intervals);
        if (c != null) { coords.add(c); count++; }
      }
    }

    final b = _bounds(coords);
    return ScalePattern(
      scaleName: scaleName,
      root: root,
      patternType: '3NPS',
      positionName: positionName.isEmpty
          ? '$root $scaleName — 3NPS fret $startFret'
          : positionName,
      startingFret: b.startingFret,
      fretsSpan: b.fretsSpan,
      coordinates: coords,
    );
  }

  // 4. SEVEN PATTERNS (complete 3NPS system)
  static List<ScalePattern> sevenPatterns({
    required String scaleName,
    required String root,
    required List<int> intervals,
  }) {
    final rootNote = _rootSemitone(root);
    final startFrets = <int>[];

    for (var fret = 0; fret <= 12; fret++) {
      final note = _noteAt(1, fret);
      final semitoneFromRoot = (note - rootNote + 12) % 12;
      if (intervals.contains(semitoneFromRoot) && startFrets.length < 7) {
        startFrets.add(fret);
      }
    }

    const degreeRomans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

    return List.generate(startFrets.length, (i) {
      final roman = degreeRomans[i < degreeRomans.length ? i : i % degreeRomans.length];
      final p = threeNps(
        scaleName: scaleName,
        root: root,
        intervals: intervals,
        startFret: startFrets[i],
        positionName: '$roman — $root $scaleName fret ${startFrets[i]}',
      );
      return p.copyWith(patternType: '7 Patrones');
    });
  }

  // 5. FOUR NOTES PER STRING (4NPS)
  static ScalePattern fourNps({
    required String scaleName,
    required String root,
    required List<int> intervals,
    required int startFret,
    String positionName = '',
  }) {
    final rootNote = _rootSemitone(root);
    final scaleSet = intervals.map((i) => (rootNote + i) % 12).toSet();
    final coords = <NoteCoordinate>[];

    for (var s = 1; s <= 6; s++) {
      var count = 0;
      for (var f = startFret; f <= startFret + 10 && count < 4; f++) {
        final c = _coord(s, f, rootNote, scaleSet, intervals);
        if (c != null) { coords.add(c); count++; }
      }
    }

    final b = _bounds(coords);
    return ScalePattern(
      scaleName: scaleName,
      root: root,
      patternType: '4NPS',
      positionName: positionName.isEmpty
          ? '$root $scaleName — 4NPS fret $startFret'
          : positionName,
      startingFret: b.startingFret,
      fretsSpan: b.fretsSpan,
      coordinates: coords,
    );
  }

  // 6. PENTATONIC BOXES (5 classic boxes)
  static List<ScalePattern> pentatonicBoxes({
    required String scaleName,
    required String root,
    required List<int> intervals,
  }) {
    final rootNote = _rootSemitone(root);
    final startFrets = <int>[];

    for (var fret = 0; fret <= 12; fret++) {
      final note = _noteAt(1, fret);
      final semitoneFromRoot = (note - rootNote + 12) % 12;
      if (intervals.contains(semitoneFromRoot)) {
        startFrets.add(fret);
        if (startFrets.length == 5) break;
      }
    }

    return List.generate(startFrets.length, (i) => positional(
      scaleName: scaleName,
      root: root,
      intervals: intervals,
      startFret: startFrets[i],
      fretsSpan: 4,
      patternType: 'Pentatónica',
      positionName: 'Caja ${i + 1} — traste ${startFrets[i]}',
    ));
  }

  // 7. BERKLEE POSITIONAL — 7 positions
  static List<ScalePattern> berklee({
    required String scaleName,
    required String root,
    required List<int> intervals,
  }) {
    final rootNote = _rootSemitone(root);
    final anchorFrets = <int>[];

    for (var fret = 0; fret <= 12; fret++) {
      final note = _noteAt(1, fret);
      final semitoneFromRoot = (note - rootNote + 12) % 12;
      if (intervals.contains(semitoneFromRoot)) anchorFrets.add(fret);
    }

    const degreeRomans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

    return List.generate(anchorFrets.length.clamp(0, 7), (i) {
      final startFret = anchorFrets[i] == 0 ? 0 : anchorFrets[i] - 1;
      final roman = degreeRomans[i < degreeRomans.length ? i : i % degreeRomans.length];
      return positional(
        scaleName: scaleName,
        root: root,
        intervals: intervals,
        startFret: startFret,
        fretsSpan: 4,
        patternType: 'Berklee',
        positionName: 'Posición $roman — traste ${anchorFrets[i]}',
      );
    });
  }

  // 8. FULL NECK — user-configurable range
  static ScalePattern fullNeck({
    required String scaleName,
    required String root,
    required List<int> intervals,
    int fromFret = 0,
    int toFret = 12,
  }) {
    assert(fromFret >= 0 && toFret <= 24 && fromFret < toFret);
    return positional(
      scaleName: scaleName,
      root: root,
      intervals: intervals,
      startFret: fromFret,
      fretsSpan: toFret - fromFret,
      patternType: 'Mástil completo',
      positionName: '$root $scaleName — fret $fromFret–$toFret',
    );
  }

  // 9. ALL SYSTEMS at once
  static Map<String, List<ScalePattern>> allSystems({
    required String scaleName,
    required String root,
    required List<int> intervals,
    int userStartFret = 0,
    int userEndFret = 12,
  }) {
    final isPentatonic = intervals.length <= 5;
    return {
      'CAGED': caged(scaleName: scaleName, root: root, intervals: intervals),
      '3NPS': List.generate(
        intervals.length.clamp(5, 7),
        (i) => threeNps(scaleName: scaleName, root: root, intervals: intervals, startFret: i * 2),
      ),
      '4NPS': List.generate(
        intervals.length.clamp(4, 6),
        (i) => fourNps(scaleName: scaleName, root: root, intervals: intervals, startFret: i * 3),
      ),
      '7 Patrones': sevenPatterns(scaleName: scaleName, root: root, intervals: intervals),
      if (isPentatonic)
        'Pentatónica': pentatonicBoxes(scaleName: scaleName, root: root, intervals: intervals),
      'Berklee': berklee(scaleName: scaleName, root: root, intervals: intervals),
      'Mástil completo': [
        fullNeck(scaleName: scaleName, root: root, intervals: intervals,
            fromFret: userStartFret, toFret: userEndFret),
      ],
    };
  }
}
