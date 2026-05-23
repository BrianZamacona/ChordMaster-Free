import 'package:flutter_test/flutter_test.dart';

import 'package:chordmaster_free/features/scales/scale_enrichment.dart';
import 'package:chordmaster_free/features/scales/scale_pattern_validator.dart';
import 'package:chordmaster_free/models/scale.dart';

void main() {
  group('ScaleEnrichment fingerings freeze', () {
    test('does not auto-generate block/3NPS/CAGED fingerings', () {
      const scale = Scale(
        name: 'C Major',
        root: 'C',
        type: 'major',
        intervals: [0, 2, 4, 5, 7, 9, 11],
        description: 'desc',
        relatedChords: ['C', 'Dm', 'Em'],
        commonUsage: 'usage',
      );

      final enriched = ScaleEnrichment.enrich(scale);
      expect(enriched.blockFingerings, isEmpty);
      expect(enriched.threeNotePerStringFingerings, isEmpty);
      expect(enriched.cagedFingerings, isEmpty);
    });
  });

  group('ScalePatternValidator', () {
    const validator = ScalePatternValidator();

    test('accepts validated C major pattern in standard tuning', () {
      final scale = Scale(
        name: 'C Major',
        root: 'C',
        type: 'major',
        intervals: const [0, 2, 4, 5, 7, 9, 11],
        description: 'desc',
        relatedChords: const ['C', 'Dm', 'Em'],
        commonUsage: 'usage',
        blockFingerings: const [
          ScalePattern(
            name: 'Validated block',
            status: ScalePatternStatus.validated,
            system: ScalePatternSystem.block,
            notes: [
              ScalePatternNote(stringNumber: 6, fret: 8), // C
              ScalePatternNote(stringNumber: 6, fret: 12), // E
              ScalePatternNote(stringNumber: 5, fret: 10), // G
            ],
          ),
        ],
      );

      final result = validator.validate(
        scale: scale,
        patterns: scale.blockFingerings,
        system: ScalePatternSystem.block,
      );

      expect(result.validPatterns, hasLength(1));
      expect(result.issues, isEmpty);
    });

    test('rejects draft patterns', () {
      final scale = Scale(
        name: 'C Major',
        root: 'C',
        type: 'major',
        intervals: const [0, 2, 4, 5, 7, 9, 11],
        description: 'desc',
        relatedChords: const ['C', 'Dm', 'Em'],
        commonUsage: 'usage',
        blockFingerings: const [
          ScalePattern(
            name: 'Draft block',
            status: ScalePatternStatus.draft,
            system: ScalePatternSystem.block,
            notes: [
              ScalePatternNote(stringNumber: 6, fret: 8),
              ScalePatternNote(stringNumber: 5, fret: 10),
            ],
          ),
        ],
      );

      final result = validator.validate(
        scale: scale,
        patterns: scale.blockFingerings,
        system: ScalePatternSystem.block,
      );

      expect(result.validPatterns, isEmpty);
      expect(result.issues, hasLength(1));
    });
  });
}
