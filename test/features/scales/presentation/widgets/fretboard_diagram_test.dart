import 'package:chordmaster_free/features/scales/data/models/note_coordinate.dart';
import 'package:chordmaster_free/features/scales/data/models/scale_pattern.dart';
import 'package:chordmaster_free/features/scales/presentation/widgets/fretboard_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a custom paint diagram from strict coordinates',
      (tester) async {
    const pattern = ScalePattern(
      scaleName: 'Major',
      root: 'C',
      patternType: 'CAGED',
      positionName: 'Forma de A',
      startingFret: 2,
      fretsSpan: 4,
      coordinates: [
        NoteCoordinate(
          string: 5,
          fret: 3,
          interval: '1',
          note: 'C',
          isRoot: true,
          finger: 2,
        ),
        NoteCoordinate(
          string: 5,
          fret: 5,
          interval: '2',
          note: 'D',
          isRoot: false,
          finger: 4,
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FretboardDiagram(pattern: pattern),
        ),
      ),
    );

    expect(find.byType(FretboardDiagram), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FretboardDiagram),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
