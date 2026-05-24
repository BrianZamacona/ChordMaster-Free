import '../../core/constants/music_theory.dart';
import '../../models/scale.dart';
import 'domain/services/direct_harmonization_service.dart';

/// Enriches scales with practical guitar fingerings and harmonized triads.
class ScaleEnrichment {
  static const _harmonizer = DirectHarmonizationService();

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
          : _buildHarmonizedChords(
              root: scale.root,
              intervals: scale.intervals,
              notes: notes,
            ),
    );
  }

  static List<String> _notesFor(String root, List<int> intervals) {
    final rootIndex = chromaticNotes.indexOf(root);
    if (rootIndex < 0) return const [];
    return intervals
        .map((value) => chromaticNotes[(rootIndex + value) % 12])
        .toList(growable: false);
  }

  static List<HarmonizedChord> _buildHarmonizedChords({
    required String root,
    required List<int> intervals,
    required List<String> notes,
  }) {
    if (intervals.length < 5 ||
        notes.length != intervals.length ||
        notes.isEmpty) {
      return const [];
    }
    final harmonized = _harmonizer.harmonizeTriads(
      root: root,
      scaleIntervals: intervals,
    );
    return harmonized
        .map(
          (entry) => HarmonizedChord(
            degree: entry.degree,
            chord: entry.chord,
            quality: entry.quality,
          ),
        )
        .toList(growable: false);
  }
}
