import '../../../../core/constants/music_theory.dart';

/// One harmonized diatonic chord entry for a scale degree.
class HarmonizedDegree {
  const HarmonizedDegree({
    required this.degree,
    required this.chord,
    required this.quality,
  });

  final String degree;
  final String chord;
  final String quality;
}

/// Direct harmonization: scale -> diatonic triads in thirds.
class DirectHarmonizationService {
  const DirectHarmonizationService();

  static const _roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

  List<HarmonizedDegree> harmonizeTriads({
    required String root,
    required List<int> scaleIntervals,
  }) {
    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex < 0 || scaleIntervals.length < 5) return const [];

    final notes = scaleIntervals
        .map((i) => chromaticNotes[(rootIndex + i) % 12])
        .toList(growable: false);

    final result = <HarmonizedDegree>[];
    for (var i = 0; i < scaleIntervals.length; i++) {
      final rootSemitone = scaleIntervals[i];
      final thirdSemitone = scaleIntervals[(i + 2) % scaleIntervals.length];
      final fifthSemitone = scaleIntervals[(i + 4) % scaleIntervals.length];

      var third = thirdSemitone - rootSemitone;
      var fifth = fifthSemitone - rootSemitone;
      if (third <= 0) third += 12;
      if (fifth <= 0) fifth += 12;

      final quality = _qualityForTriad(third, fifth);
      final suffix = switch (quality) {
        'major' => '',
        'minor' => 'm',
        'diminished' => 'dim',
        'augmented' => 'aug',
        _ => '',
      };
      result.add(
        HarmonizedDegree(
          degree: _roman[i % _roman.length],
          chord: '${notes[i]}$suffix',
          quality: quality,
        ),
      );
    }
    return result;
  }

  String _qualityForTriad(int third, int fifth) {
    if (third == 4 && fifth == 7) return 'major';
    if (third == 3 && fifth == 7) return 'minor';
    if (third == 3 && fifth == 6) return 'diminished';
    if (third == 4 && fifth == 8) return 'augmented';
    return 'other';
  }
}
