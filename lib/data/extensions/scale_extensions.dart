import '../models/scale_definition.dart';
import '../repository/scale_repository.dart';

extension ScaleDefinitionFiltering on List<ScaleDefinition> {
  List<ScaleDefinition> byCategory(String category) =>
      where((s) => s.category == category).toList(growable: false);
}

extension ScaleTheoryUtils on ScaleDefinition {
  bool get isPentatonic => intervals.length <= 5;
}

extension ResolvedPatternUtils on ResolvedPattern {
  bool isVisibleInRange(int start, int end) =>
      coordinates.any((c) => c.fret >= start && c.fret <= end);
}

class NoteResolver {
  static const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  String resolve(int semitone) => noteNames[semitone % 12];
}

class GuitarSettings {
  const GuitarSettings({
    this.stringCount = 6,
    this.fretCount = 22,
    this.viewportStartFret = 0,
    this.viewportEndFret = 12,
  });

  final int stringCount;
  final int fretCount;
  final int viewportStartFret;
  final int viewportEndFret;
}

enum Tuning {
  standard([4, 11, 7, 2, 9, 4]);

  const Tuning(this.openSemitones);
  final List<int> openSemitones;
}
