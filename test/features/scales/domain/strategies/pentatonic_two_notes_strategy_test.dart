import 'package:chordmaster_free/features/scales/domain/models/string_configuration.dart';
import 'package:chordmaster_free/features/scales/domain/strategies/fingering_strategy.dart';
import 'package:chordmaster_free/features/scales/domain/strategies/pentatonic_two_notes_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps blues 4-b5-5 cluster on a string', () {
    const strategy = PentatonicTwoNotesStrategy();

    final selected = strategy.select(
      availableByString: {
        2: const [
          PositionedNote(stringNumber: 2, fret: 5, semitoneFromRoot: 5), // 4
          PositionedNote(stringNumber: 2, fret: 6, semitoneFromRoot: 6), // b5
          PositionedNote(stringNumber: 2, fret: 7, semitoneFromRoot: 7), // 5
        ],
      },
      config: StringConfiguration.standard6,
      startingFret: 5,
      maxFretSpan: 4,
    );

    final frets = selected.map((n) => n.fret).toList()..sort();
    expect(frets, [5, 6, 7]);
  });
}
