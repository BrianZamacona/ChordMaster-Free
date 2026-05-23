import '../../core/constants/music_theory.dart';
import '../../models/scale.dart';

/// Enriches scales with practical guitar fingerings and harmonized triads.
class ScaleEnrichment {
  static const List<String> _roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

  static Scale enrich(Scale scale) {
    final notes = _notesFor(scale.root, scale.intervals);

    return scale.copyWith(
      blockFingerings: scale.blockFingerings.isNotEmpty
          ? scale.blockFingerings
          : _buildBlockFingerings(scale.root, notes),
      threeNotePerStringFingerings:
          scale.threeNotePerStringFingerings.isNotEmpty
              ? scale.threeNotePerStringFingerings
              : _buildThreeNpsFingerings(scale.root, notes),
      cagedFingerings: scale.cagedFingerings.isNotEmpty
          ? scale.cagedFingerings
          : _buildCagedFingerings(scale.root, notes),
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

  static int _rootFret(String root) {
    final openLowE = chromaticNotes.indexOf('E');
    final note = chromaticNotes.indexOf(root);
    if (openLowE < 0 || note < 0) return 0;
    return (note - openLowE + 12) % 12;
  }

  static List<ScalePattern> _buildBlockFingerings(
      String root, List<String> notes) {
    final base = _rootFret(root);
    final starts = <int>[base, base + 4, base + 7]
        .map((value) => value.clamp(0, 15))
        .cast<int>()
        .toList(growable: false);

    return List<ScalePattern>.generate(
      starts.length,
      (index) {
        final s = starts[index];
        return ScalePattern(
          name: 'Block ${index + 1}',
          description: 'Position around fret $s',
          positions: [
            '6th string: $s-${s + 2}',
            '5th string: ${s + 1}-${s + 3}',
            '4th string: ${s + 1}-${s + 3}',
            '3rd string: ${s + 1}-${s + 3}',
            '2nd string: ${s + 2}-${s + 4}',
            '1st string: ${s + 2}-${s + 4}',
            'Scale tones: ${notes.join(' - ')}',
          ],
        );
      },
      growable: false,
    );
  }

  static List<ScalePattern> _buildThreeNpsFingerings(
      String root, List<String> notes) {
    final base = _rootFret(root).clamp(0, 14);
    return [
      ScalePattern(
        name: '3NPS Pattern 1',
        description: 'Ascending three-notes-per-string shape',
        positions: [
          '6th string: $base-${base + 2}-${base + 4}',
          '5th string: ${base + 1}-${base + 3}-${base + 5}',
          '4th string: ${base + 1}-${base + 3}-${base + 5}',
          '3rd string: ${base + 1}-${base + 3}-${base + 5}',
          '2nd string: ${base + 2}-${base + 4}-${base + 6}',
          '1st string: ${base + 2}-${base + 4}-${base + 6}',
        ],
      ),
      ScalePattern(
        name: '3NPS Pattern 2',
        description: 'Shifted 3NPS shape for lateral movement',
        positions: [
          '6th string: ${base + 2}-${base + 4}-${base + 6}',
          '5th string: ${base + 3}-${base + 5}-${base + 7}',
          '4th string: ${base + 3}-${base + 5}-${base + 7}',
          '3rd string: ${base + 3}-${base + 5}-${base + 7}',
          '2nd string: ${base + 4}-${base + 6}-${base + 8}',
          '1st string: ${base + 4}-${base + 6}-${base + 8}',
          'Scale tones: ${notes.join(' - ')}',
        ],
      ),
    ];
  }

  static List<ScalePattern> _buildCagedFingerings(
      String root, List<String> notes) {
    final base = _rootFret(root);
    final shapes = ['C', 'A', 'G', 'E', 'D'];
    final offsets = [0, 2, 4, 7, 9];

    return List<ScalePattern>.generate(
      shapes.length,
      (index) {
        final fret = (base + offsets[index]).clamp(0, 15);
        return ScalePattern(
          name: 'CAGED ${shapes[index]} shape',
          description: 'Root centered near fret $fret',
          positions: [
            'Anchor fret: $fret',
            'Use adjacent positions from fret ${fret - 1} to ${fret + 3}',
            'Emphasize chord tones over degree ${_roman[index % _roman.length]}',
            'Scale tones: ${notes.join(' - ')}',
          ],
        );
      },
      growable: false,
    );
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
