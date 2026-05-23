import '../../core/constants/music_theory.dart';
import '../../models/scale.dart';

/// Canonical policy used to accept/reject guitar scale patterns before UI render.
class ScalePatternPolicy {
  ScalePatternPolicy._();

  /// Single source-of-truth tuning baseline for pattern validation.
  static const tuningName = 'EADGBE_STANDARD';

  /// Standard tuning from low to high string.
  static const standardTuning = <String>['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];

  /// Supported pattern systems in the first rollout.
  static const supportedSystems = <ScalePatternSystem>{
    ScalePatternSystem.block,
    ScalePatternSystem.threeNps,
    ScalePatternSystem.caged,
    ScalePatternSystem.pentatonicBox,
    ScalePatternSystem.custom,
  };

  /// Conservative ergonomic range cap to avoid wide, hard-to-read shapes.
  static const maxRecommendedFretSpan = 6;

  /// Hard fretboard cap for current renderer.
  static const maxSupportedFret = 22;

  /// Minimum degrees expected per pattern family.
  static Set<int> requiredIntervalsFor(ScalePatternSystem system) {
    switch (system) {
      case ScalePatternSystem.block:
      case ScalePatternSystem.caged:
        return const {0, 4, 7}; // 1, 3, 5 (triad anchor)
      case ScalePatternSystem.threeNps:
        return const {0}; // root is mandatory
      case ScalePatternSystem.pentatonicBox:
      case ScalePatternSystem.custom:
        return const {0};
    }
  }

  static bool isBaselineCompatible(List<String> tuning) {
    if (tuning.length != standardTuning.length) return false;
    for (var i = 0; i < tuning.length; i++) {
      if (tuning[i] != standardTuning[i]) return false;
    }
    return true;
  }

  static String pitchClassFromNoteName(String noteWithOctave) {
    final regex = RegExp(r'^[A-G]#?');
    final match = regex.firstMatch(noteWithOctave.trim());
    return match?.group(0) ?? noteWithOctave;
  }

  static String noteAt(int stringNumber, int fret) {
    final stringIndex = 6 - stringNumber;
    return fretboardMap[stringIndex]?[fret] ?? '';
  }
}
