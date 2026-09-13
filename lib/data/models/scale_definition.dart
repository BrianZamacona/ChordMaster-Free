import 'note_coordinate.dart';

const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const _standardTuningHighToLow = [4, 11, 7, 2, 9, 4];

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

  final String id;
  final String name;
  final String category;
  final String description;
  final List<int> intervals;
  final List<FingeringSystem> systems;
  final List<ScalePosition> positions;

  factory ScaleDefinition.fromJson(Map<String, dynamic> json) => ScaleDefinition(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    intervals: (json['intervals'] as List<dynamic>).map((e) => (e as num).toInt()).toList(growable: false),
    systems: (json['systems'] as List<dynamic>? ?? const [])
        .map((e) => FingeringSystem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    positions: (json['positions'] as List<dynamic>? ?? const [])
        .map((e) => ScalePosition.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class FingeringSystem {
  const FingeringSystem({required this.id, required this.name});

  final String id;
  final String name;

  factory FingeringSystem.fromJson(Map<String, dynamic> json) => FingeringSystem(
    id: json['id'] as String,
    name: json['name'] as String,
  );
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

  final String id;
  final String name;
  final String systemId;
  final int startingFret;
  final int fretSpan;
  final List<RelativeCoord> coordinates;
  final List<RootAnchor> rootAnchors;

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

  List<NoteCoordinate> resolveCoordinates(int rootSemitone) {
    final semitoneOffset = rootSemitone % 12;
    return coordinates
        .map((c) {
          final fret = c.fretOffset + semitoneOffset;
          final open = _standardTuningHighToLow[(c.string - 1).clamp(0, 5)];
          final noteSemitone = (open + fret) % 12;
          final intervalSemitone = (noteSemitone - rootSemitone + 12) % 12;
          return NoteCoordinate(
            string: c.string,
            fret: fret,
            isRoot: c.isRoot,
            note: c.note.isNotEmpty ? c.note : _noteNames[noteSemitone],
            interval: c.interval.isNotEmpty ? c.interval : _intervalName(intervalSemitone),
            finger: c.finger,
          );
        })
        .where((c) => c.fret >= 0)
        .toList(growable: false);
  }
}

String _intervalName(int interval) {
  const names = {
    0: '1',
    1: 'b2',
    2: '2',
    3: 'b3',
    4: '3',
    5: '4',
    6: 'b5',
    7: '5',
    8: '#5',
    9: '6',
    10: 'b7',
    11: '7',
  };
  return names[interval % 12] ?? '';
}

class StringPatterns {
  const StringPatterns({required this.patterns});

  final List<PatternData> patterns;

  factory StringPatterns.fromJson(Map<String, dynamic> json) => StringPatterns(
    patterns: (json['patterns'] as List<dynamic>? ?? const [])
        .map((e) => PatternData.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
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

  final int string;
  final int fretOffset;
  final String interval;
  final String note;
  final bool isRoot;
  final int? finger;

  factory PatternData.fromJson(Map<String, dynamic> json) => PatternData(
    string: (json['string'] as num).toInt(),
    fretOffset: (json['fret_offset'] as num).toInt(),
    interval: json['interval'] as String? ?? '',
    note: json['note'] as String? ?? '',
    isRoot: json['is_root'] as bool? ?? false,
    finger: (json['finger'] as num?)?.toInt(),
  );
}

class RootAnchor {
  const RootAnchor({required this.string, required this.fretOffset});

  final int string;
  final int fretOffset;

  factory RootAnchor.fromJson(Map<String, dynamic> json) => RootAnchor(
    string: (json['string'] as num).toInt(),
    fretOffset: (json['fret_offset'] as num).toInt(),
  );
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

  final int string;
  final int fretOffset;
  final String interval;
  final String note;
  final bool isRoot;
  final int? finger;

  factory RelativeCoord.fromJson(Map<String, dynamic> json) => RelativeCoord(
    string: (json['string'] as num).toInt(),
    fretOffset: (json['fret_offset'] as num).toInt(),
    interval: json['interval'] as String? ?? '',
    note: json['note'] as String? ?? '',
    isRoot: json['is_root'] as bool? ?? false,
    finger: (json['finger'] as num?)?.toInt(),
  );
}
