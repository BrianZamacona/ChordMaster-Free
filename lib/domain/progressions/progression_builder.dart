import '../theory/double_stops.dart' show noteNames;
import '../voicing/barre_detection.dart';
import '../voicing/ergonomics.dart';
import '../voicing/voice_leading.dart';
import '../voicing/voicing_adapter.dart';
import 'progression_data.dart';

/// Digitaciones de un acorde de chords.json, en el orden del JSON (6ª → 1ª).
class ChordFingerings {
  const ChordFingerings({
    required this.name,
    required this.root,
    required this.type,
    required this.intervals,
    required this.fingerings,
    required this.fingers,
  });

  factory ChordFingerings.fromJson(Map<String, dynamic> json) {
    List<int> frets(Object? raw) => (raw! as List<dynamic>).cast<int>();
    final fingerings = [frets(json['fretPositions'])];
    final fingers = [frets(json['fingerPositions'])];
    for (final field in const [
      'cagedPositions',
      'voicings',
      'triadInversions',
    ]) {
      for (final item in (json[field] as List<dynamic>? ?? const [])) {
        final map = item as Map<String, dynamic>;
        fingerings.add(frets(map['fretPositions']));
        fingers.add(frets(map['fingerPositions']));
      }
    }
    return ChordFingerings(
      name: json['name'] as String,
      root: json['root'] as String,
      type: json['type'] as String,
      intervals: (json['intervals'] as List<dynamic>).cast<int>(),
      fingerings: fingerings,
      fingers: fingers,
    );
  }

  final String name;
  final String root;
  final String type;
  final List<int> intervals;
  final List<List<int>> fingerings;

  /// `fingerPositions` paralelo a [fingerings] (mismo orden 6ª → 1ª).
  final List<List<int>> fingers;
}

class ProgressionVoicing extends VoiceLeadingVoicing {
  const ProgressionVoicing({
    required super.fretPositions,
    required super.anchorFret,
    required double super.individualCost,
    required this.chord,
    required this.jsonFrets,
    super.barre,
  });

  final ChordFingerings chord;

  /// Misma digitación en el orden de chords.json (6ª → 1ª, -1 = muteada).
  final List<int> jsonFrets;
}

int _anchorFret(EngineFrets frets) {
  final fretted = [
    for (final f in frets)
      if (f != null && f > 0) f,
  ];
  return fretted.isEmpty ? 0 : fretted.reduce((a, b) => a < b ? a : b);
}

class ProgressionBuilder {
  ProgressionBuilder(Iterable<ChordFingerings> chords)
    : _chords = {for (final c in chords) '${c.root}|${c.type}': c};

  final Map<String, ChordFingerings> _chords;

  /// Candidatos ergonómicamente válidos de un acorde, sin duplicados y en el
  /// orden del JSON.
  List<ProgressionVoicing> candidatesFor(
    String root,
    String type, {
    bool beginner = false,
  }) {
    final chord = _chords['$root|$type'];
    if (chord == null) return [];
    final seen = <String>{};
    final result = <ProgressionVoicing>[];
    for (var i = 0; i < chord.fingerings.length; i++) {
      final raw = chord.fingerings[i];
      final frets = VoicingAdapter.fromChordJson(raw);
      if (!seen.add(frets.join(','))) continue;
      Barre? barre;
      var voicing = ErgonomicVoicing(fretPositions: frets);
      var options = const ErgonomicOptions();
      if (beginner) {
        final engineFingers = VoicingAdapter.fingersFromChordJson(
          chord.fingers[i],
        );
        barre = detectBarre(frets, engineFingers);
        voicing = ErgonomicVoicing(
          fretPositions: frets,
          fingerPositions: engineFingers,
          barre: barre,
        );
        options = const ErgonomicOptions(beginner: true);
      }
      final cost = calculateErgonomicCost(voicing, options);
      if (!cost.isFinite) continue;
      result.add(
        ProgressionVoicing(
          fretPositions: frets,
          anchorFret: _anchorFret(frets),
          individualCost: cost,
          chord: chord,
          jsonFrets: raw,
          barre: barre,
        ),
      );
    }
    return result;
  }

  List<List<ProgressionVoicing>> layersFor(
    Progression progression,
    int tonic, {
    bool beginner = false,
  }) => [
    for (final degree in progression.degrees)
      candidatesFor(
        noteNames[(tonic + degree.semitones) % 12],
        degree.type,
        beginner: beginner,
      ),
  ];

  /// Un acorde por grado, o lista vacía si algún grado no tiene candidatos.
  List<ProgressionVoicing> build(
    Progression progression,
    int tonic, {
    bool beginner = false,
  }) => findOptimalProgressionPath(
    layersFor(progression, tonic, beginner: beginner),
  );
}

/// Costo local de cada acorde más el costo de transición entre ellos.
double progressionPathCost(List<ProgressionVoicing> path) {
  var total = 0.0;
  for (var i = 0; i < path.length; i++) {
    total += path[i].individualCost!;
    if (i > 0) total += calculateVoiceLeadingCost(path[i - 1], path[i]);
  }
  return total;
}
