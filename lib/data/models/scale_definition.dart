import '../../domain/theory/intervals.dart';
import 'note_coordinate.dart';

const _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B'
];
const _standardTuningHighToLow = [4, 11, 7, 2, 9, 4];
const maxFret = 24;

class ScaleDefinition {
  const ScaleDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.intervals,
    required this.systems,
    required this.positions,
    this.description = '',
  });

  factory ScaleDefinition.fromJson(Map<String, dynamic> json) =>
      ScaleDefinition(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        intervals: (json['intervals'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(growable: false),
        systems: (json['systems'] as List<dynamic>? ?? const [])
            .map((e) => FingeringSystem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        positions: (json['positions'] as List<dynamic>? ?? const [])
            .map((e) => ScalePosition.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String id;
  final String name;
  final String category;
  final String description;
  final List<int> intervals;
  final List<FingeringSystem> systems;
  final List<ScalePosition> positions;
}

class FingeringSystem {
  const FingeringSystem({required this.id, required this.name});

  factory FingeringSystem.fromJson(Map<String, dynamic> json) =>
      FingeringSystem(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;
}

class ScalePosition {
  const ScalePosition({
    required this.id,
    required this.name,
    required this.systemId,
    required this.startingFret,
    required this.fretSpan,
    required this.coordinates,
    this.rootAnchors = const [],
  });

  factory ScalePosition.fromJson(Map<String, dynamic> json) => ScalePosition(
        id: json['id'] as String,
        name: json['name'] as String,
        systemId: json['system_id'] as String,
        startingFret: (json['starting_fret'] as num?)?.toInt() ?? 0,
        fretSpan: (json['fret_span'] as num?)?.toInt() ?? 4,
        coordinates: (json['coordinates'] as List<dynamic>? ?? const [])
            .map((e) => RelativeCoord.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        rootAnchors: (json['root_anchors'] as List<dynamic>? ?? const [])
            .map((e) => RootAnchor.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String id;
  final String name;
  final String systemId;
  final int startingFret;
  final int fretSpan;
  final List<RelativeCoord> coordinates;
  final List<RootAnchor> rootAnchors;

  /// Posición completa dentro de los trastes 0..24; nunca recortada.
  ///
  /// [scaleIntervals] (los `intervals` de la escala) sirve para nombrar cada
  /// nota por su grado (`b6` en la menor, no `#5`); ver [spellInterval].
  List<NoteCoordinate> resolveCoordinates(
    int rootSemitone, {
    List<int> scaleIntervals = const [],
  }) {
    if (coordinates.isEmpty) return const [];
    var shift = rootSemitone % 12;
    final offsets = coordinates.map((c) => c.fretOffset);
    if (offsets.reduce((a, b) => a > b ? a : b) + shift > maxFret) shift -= 12;
    if (offsets.reduce((a, b) => a < b ? a : b) + shift < 0) shift += 12;
    return resolveShifted(rootSemitone, shift, scaleIntervals: scaleIntervals);
  }

  /// Instancia con desplazamiento absoluto [shift]; vacía si no cabe en 0..24.
  List<NoteCoordinate> resolveShifted(
    int rootSemitone,
    int shift, {
    List<int> scaleIntervals = const [],
  }) {
    for (final c in coordinates) {
      final fret = c.fretOffset + shift;
      if (fret < 0 || fret > maxFret) return const [];
    }
    return _resolveWithShift(rootSemitone, shift, scaleIntervals);
  }

  List<NoteCoordinate> _resolveWithShift(
          int rootSemitone, int semitoneOffset, List<int> scaleIntervals) =>
      coordinates.map((c) {
        final fret = c.fretOffset + semitoneOffset;
        final open = _standardTuningHighToLow[(c.string - 1).clamp(0, 5)];
        final noteSemitone = (open + fret) % 12;
        final intervalSemitone = (noteSemitone - rootSemitone + 12) % 12;
        return NoteCoordinate(
          string: c.string,
          fret: fret,
          isRoot: c.isRoot,
          note: c.note.isNotEmpty ? c.note : _noteNames[noteSemitone],
          interval: c.interval.isNotEmpty
              ? c.interval
              : spellInterval(intervalSemitone, scaleIntervals),
          finger: c.finger,
        );
      }).toList(growable: false);
}


class StringPatterns {
  const StringPatterns({required this.patterns});

  factory StringPatterns.fromJson(Map<String, dynamic> json) => StringPatterns(
        patterns: (json['patterns'] as List<dynamic>? ?? const [])
            .map((e) => PatternData.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final List<PatternData> patterns;
}

class PatternData {
  const PatternData({
    required this.string,
    required this.fretOffset,
    this.interval = '',
    this.note = '',
    this.isRoot = false,
    this.finger,
  });

  factory PatternData.fromJson(Map<String, dynamic> json) => PatternData(
        string: (json['string'] as num).toInt(),
        fretOffset: (json['fret_offset'] as num).toInt(),
        interval: json['interval'] as String? ?? '',
        note: json['note'] as String? ?? '',
        isRoot: json['is_root'] as bool? ?? false,
        finger: (json['finger'] as num?)?.toInt(),
      );

  final int string;
  final int fretOffset;
  final String interval;
  final String note;
  final bool isRoot;
  final int? finger;
}

class RootAnchor {
  const RootAnchor({required this.string, required this.fretOffset});

  factory RootAnchor.fromJson(Map<String, dynamic> json) => RootAnchor(
        string: (json['string'] as num).toInt(),
        fretOffset: (json['fret_offset'] as num).toInt(),
      );

  final int string;
  final int fretOffset;
}

class RelativeCoord {
  const RelativeCoord({
    required this.string,
    required this.fretOffset,
    this.interval = '',
    this.note = '',
    this.isRoot = false,
    this.finger,
  });

  factory RelativeCoord.fromJson(Map<String, dynamic> json) => RelativeCoord(
        string: (json['string'] as num).toInt(),
        fretOffset: (json['fret_offset'] as num).toInt(),
        interval: json['interval'] as String? ?? '',
        note: json['note'] as String? ?? '',
        isRoot: json['is_root'] as bool? ?? false,
        finger: (json['finger'] as num?)?.toInt(),
      );

  final int string;
  final int fretOffset;
  final String interval;
  final String note;
  final bool isRoot;
  final int? finger;
}
