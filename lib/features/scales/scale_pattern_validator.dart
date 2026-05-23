import '../../core/constants/music_theory.dart';
import '../../models/scale.dart';
import 'scale_pattern_policy.dart';

class ScalePatternValidationIssue {
  const ScalePatternValidationIssue({
    required this.patternName,
    required this.reason,
  });

  final String patternName;
  final String reason;
}

class ScalePatternValidationResult {
  const ScalePatternValidationResult({
    required this.validPatterns,
    required this.issues,
  });

  final List<ScalePattern> validPatterns;
  final List<ScalePatternValidationIssue> issues;
}

class ScalePatternValidator {
  const ScalePatternValidator();

  ScalePatternValidationResult validate({
    required Scale scale,
    required List<ScalePattern> patterns,
    required ScalePatternSystem system,
  }) {
    final valid = <ScalePattern>[];
    final issues = <ScalePatternValidationIssue>[];

    for (final pattern in patterns) {
      if (pattern.status == ScalePatternStatus.draft) {
        issues.add(
          ScalePatternValidationIssue(
            patternName: pattern.name,
            reason: 'Pattern status is draft and cannot be rendered.',
          ),
        );
        continue;
      }
      if (!ScalePatternPolicy.supportedSystems.contains(pattern.system)) {
        issues.add(
          ScalePatternValidationIssue(
            patternName: pattern.name,
            reason: 'Pattern system ${pattern.system.jsonValue} is not supported.',
          ),
        );
        continue;
      }

      final notes = _extractPatternNotes(pattern);
      if (notes.isEmpty) {
        issues.add(
          ScalePatternValidationIssue(
            patternName: pattern.name,
            reason: 'Pattern has no parseable string/fret notes.',
          ),
        );
        continue;
      }

      final span = _fretSpan(notes);
      if (span > ScalePatternPolicy.maxRecommendedFretSpan) {
        issues.add(
          ScalePatternValidationIssue(
            patternName: pattern.name,
            reason:
                'Pattern fret span $span exceeds ${ScalePatternPolicy.maxRecommendedFretSpan}.',
          ),
        );
        continue;
      }

      final scalePitchClasses = scale.intervals
          .map((i) => getNoteAtInterval(scale.root, i))
          .toSet();

      final representedIntervals = <int>{};
      var allNotesInScale = true;
      for (final note in notes) {
        if (note.fret < 0 || note.fret > ScalePatternPolicy.maxSupportedFret) {
          allNotesInScale = false;
          issues.add(
            ScalePatternValidationIssue(
              patternName: pattern.name,
              reason: 'Fret ${note.fret} is outside supported range 0-22.',
            ),
          );
          break;
        }
        final sounding = ScalePatternPolicy.noteAt(note.stringNumber, note.fret);
        final pitchClass = ScalePatternPolicy.pitchClassFromNoteName(sounding);
        if (!scalePitchClasses.contains(pitchClass)) {
          allNotesInScale = false;
          issues.add(
            ScalePatternValidationIssue(
              patternName: pattern.name,
              reason:
                  'Note $pitchClass at string ${note.stringNumber}, fret ${note.fret} is outside ${scale.name}.',
            ),
          );
          break;
        }
        final interval =
            (chromaticNotes.indexOf(pitchClass) - chromaticNotes.indexOf(scale.root) + 12) %
                12;
        representedIntervals.add(interval);
      }
      if (!allNotesInScale) continue;

      final required = ScalePatternPolicy.requiredIntervalsFor(system);
      if (!representedIntervals.containsAll(required)) {
        final missing = required.difference(representedIntervals).toList()..sort();
        issues.add(
          ScalePatternValidationIssue(
            patternName: pattern.name,
            reason: 'Pattern misses required intervals: $missing.',
          ),
        );
        continue;
      }

      if (system == ScalePatternSystem.threeNps &&
          !_threeNotesPerStringConstraint(notes)) {
        issues.add(
          ScalePatternValidationIssue(
            patternName: pattern.name,
            reason: '3NPS pattern must contain exactly three notes per used string.',
          ),
        );
        continue;
      }

      valid.add(pattern);
    }

    return ScalePatternValidationResult(validPatterns: valid, issues: issues);
  }

  List<ScalePatternNote> _extractPatternNotes(ScalePattern pattern) {
    if (pattern.notes.isNotEmpty) {
      return pattern.notes;
    }

    final extracted = <ScalePatternNote>[];
    final regex = RegExp(r'^(\d)(?:st|nd|rd|th)\s+string:\s*([\d-]+)$');
    for (final line in pattern.positions) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;
      final stringNumber = int.tryParse(match.group(1)!);
      if (stringNumber == null || stringNumber < 1 || stringNumber > 6) {
        continue;
      }
      final frets = match
          .group(2)!
          .split('-')
          .map((part) => int.tryParse(part))
          .whereType<int>();
      for (final fret in frets) {
        extracted.add(ScalePatternNote(stringNumber: stringNumber, fret: fret));
      }
    }
    return extracted;
  }

  int _fretSpan(List<ScalePatternNote> notes) {
    var minFret = 999;
    var maxFret = 0;
    for (final note in notes) {
      if (note.fret < minFret) minFret = note.fret;
      if (note.fret > maxFret) maxFret = note.fret;
    }
    if (minFret == 999) return 0;
    return maxFret - minFret;
  }

  bool _threeNotesPerStringConstraint(List<ScalePatternNote> notes) {
    final byString = <int, int>{};
    for (final note in notes) {
      byString.update(note.stringNumber, (count) => count + 1, ifAbsent: () => 1);
    }
    return byString.values.every((count) => count == 3);
  }
}
