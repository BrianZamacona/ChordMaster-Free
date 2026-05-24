import '../../../../core/constants/music_theory.dart';

/// Transposes roman-degree progressions to pitch classes.
class RomanProgressionService {
  const RomanProgressionService();

  static const _romanToDegree = {
    'I': 0,
    'II': 1,
    'III': 2,
    'IV': 3,
    'V': 4,
    'VI': 5,
    'VII': 6,
  };

  /// Resolves [degrees] against [scaleIntervals] from [root].
  List<String> transpose({
    required String root,
    required List<int> scaleIntervals,
    required List<String> degrees,
  }) {
    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex == -1 || scaleIntervals.isEmpty) return const [];

    return degrees.map((rawDegree) {
      final upper = rawDegree.toUpperCase();
      final normalized = upper.replaceAll('°', '').replaceAll('+', '');
      final idx = _romanToDegree[normalized];
      if (idx == null || idx >= scaleIntervals.length) return root;
      final semitone = scaleIntervals[idx];
      return chromaticNotes[(rootIndex + semitone) % 12];
    }).toList(growable: false);
  }
}
