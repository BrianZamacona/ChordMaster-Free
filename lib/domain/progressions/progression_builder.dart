import '../theory/double_stops.dart' show noteNames;
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
  });

  factory ChordFingerings.fromJson(Map<String, dynamic> json) {
    List<int> frets(Object? raw) => (raw! as List<dynamic>).cast<int>();
    final fingerings = [frets(json['fretPositions'])];
    for (final field in const [
      'cagedPositions',
      'voicings',
      'triadInversions',
    ]) {
      for (final item in (json[field] as List<dynamic>? ?? const [])) {
        fingerings.add(frets((item as Map<String, dynamic>)['fretPositions']));
      }
    }
    return ChordFingerings(
      name: json['name'] as String,
      root: json['root'] as String,
      type: json['type'] as String,
      intervals: (json['intervals'] as List<dynamic>).cast<int>(),
      fingerings: fingerings,
    );
  }

  final String name;
  final String root;
  final String type;
  final List<int> intervals;
  final List<List<int>> fingerings;
}

class ProgressionVoicing extends VoiceLeadingVoicing {
  const ProgressionVoicing({
    required super.fretPositions,
    required super.anchorFret,
    required double super.individualCost,
    required this.chord,
  });

  final ChordFingerings chord;
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
  List<ProgressionVoicing> candidatesFor(String root, String type) {
    final chord = _chords['$root|$type'];
    if (chord == null) return [];
    final seen = <String>{};
    final result = <ProgressionVoicing>[];
    for (final raw in chord.fingerings) {
      final frets = VoicingAdapter.fromChordJson(raw);
      if (!seen.add(frets.join(','))) continue;
      final cost = calculateErgonomicCost(ErgonomicVoicing(fretPositions: frets));
      if (!cost.isFinite) continue;
      result.add(
        ProgressionVoicing(
          fretPositions: frets,
          anchorFret: _anchorFret(frets),
          individualCost: cost,
          chord: chord,
        ),
      );
    }
    return result;
  }

  List<List<ProgressionVoicing>> layersFor(Progression progression, int tonic) => [
    for (final degree in progression.degrees)
      candidatesFor(
        noteNames[(tonic + degree.semitones) % 12],
        degree.type,
      ),
  ];

  /// Un acorde por grado, o lista vacía si algún grado no tiene candidatos.
  List<ProgressionVoicing> build(Progression progression, int tonic) =>
      findOptimalProgressionPath(layersFor(progression, tonic));
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
