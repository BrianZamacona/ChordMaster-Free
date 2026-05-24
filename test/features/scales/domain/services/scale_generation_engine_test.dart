import 'package:chordmaster_free/features/scales/domain/models/string_configuration.dart';
import 'package:chordmaster_free/features/scales/domain/models/tablature_constraints.dart';
import 'package:chordmaster_free/features/scales/domain/services/fretboard_calculator.dart';
import 'package:chordmaster_free/features/scales/domain/services/scale_generation_engine.dart';
import 'package:chordmaster_free/features/scales/domain/strategies/three_notes_per_string_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate returns filtered notes inside constraints', () {
    const engine = ScaleGenerationEngine(calculator: FretboardCalculator());

    final notes = engine.generate(
      root: 'C',
      intervals: const [0, 2, 4, 5, 7, 9, 11],
      strategy: const ThreeNotesPerStringStrategy(),
      tuning: StringConfiguration.standard6,
      startingFret: 1,
      constraints: const TablatureConstraints(
        minFret: 1,
        maxFret: 8,
        maxSpanPerString: 5,
      ),
    );

    expect(notes, isNotEmpty);
    expect(notes.every((n) => n.fret >= 1 && n.fret <= 8), isTrue);
  });
}
