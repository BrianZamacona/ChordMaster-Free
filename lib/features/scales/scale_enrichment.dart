import '../../core/constants/music_theory.dart';
import '../../models/scale.dart';

/// Enriches scales with practical guitar fingerings and harmonized triads.
class ScaleEnrichment {
  static const List<String> _roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

  static Scale enrich(Scale scale) {
    final notes = _notesFor(scale.root, scale.intervals);

    return scale.copyWith(
      // Freeze policy: fingerings are source-of-truth data only.
      // Never auto-generate CAGED/3NPS/Block shapes from formulas.
      blockFingerings: scale.blockFingerings,
      threeNotePerStringFingerings: scale.threeNotePerStringFingerings,
      cagedFingerings: scale.cagedFingerings,
      harmonizedChords: scale.harmonizedChords.isNotEmpty
          ? scale.harmonizedChords
          : _buildHarmonizedChords(scale.intervals, notes),
    );
  }

  static List<String> _notesFor(String root, List<int> intervals) {
    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex < 0) return const [];
    return intervals
        .map((value) => chromaticNotes[(rootIndex + value) % 12])
        .toList(growable: false);
  }

  static List<HarmonizedChord> _buildHarmonizedChords(
    List<int> intervals,
    List<String> notes,
  ) {
    if (intervals.length < 5 || notes.length != intervals.length) {
      return const [];
    }

    final size = intervals.length;
    final result = <HarmonizedChord>[];

    for (var i = 0; i < size; i++) {
      final root = intervals[i];
      final thirdIndex = (i + 2) % size;
      final fifthIndex = (i + 4) % size;

      var third = intervals[thirdIndex] - root;
      var fifth = intervals[fifthIndex] - root;

      if (third <= 0) third += 12;
      if (fifth <= 0) fifth += 12;

      final quality = _triadQuality(third, fifth);
      final suffix = switch (quality) {
        'major' => '',
        'minor' => 'm',
        'diminished' => 'dim',
        'augmented' => 'aug',
        _ => '',
      };

      result.add(
        HarmonizedChord(
          degree: _roman[i % _roman.length],
          chord: '${notes[i]}$suffix',
          quality: quality,
        ),
      );
    }

    return result;
  }

  static String _triadQuality(int third, int fifth) {
    if (third == 4 && fifth == 7) return 'major';
    if (third == 3 && fifth == 7) return 'minor';
    if (third == 3 && fifth == 6) return 'diminished';
    if (third == 4 && fifth == 8) return 'augmented';
    return 'other';
  }
}
