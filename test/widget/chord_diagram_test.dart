import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/core/widgets/interval_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('describe cada cuerda con dedo, nota e intervalo', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        ChordDiagramWidget(
          chordName: 'C',
          fretPositions: const [-1, 3, 2, 0, 1, 0],
          fingerPositions: const [0, 3, 2, 0, 1, 0],
          root: 'C',
          toneRow: DiagramToneRow.intervalsAndNotes,
        ),
      ),
    );

    final label = tester.getSemantics(find.byType(ChordDiagramWidget)).label;
    expect(label, contains('cuerda 6 muteada'));
    expect(label, contains('cuerda 5 traste 3, dedo 3, C (R)'));
    expect(label, contains('cuerda 4 traste 2, dedo 2, E (3)'));
    expect(label, contains('cuerda 3 al aire, G (5)'));
    handle.dispose();
  });

  testWidgets('las filas de tonos agrandan el diagrama', (tester) async {
    Future<Size> sizeWith(DiagramToneRow row) async {
      await tester.pumpWidget(
        _wrap(
          ChordDiagramWidget(
            chordName: 'C',
            fretPositions: const [-1, 3, 2, 0, 1, 0],
            root: 'C',
            toneRow: row,
          ),
        ),
      );
      return tester.getSize(find.byType(CustomPaint).last);
    }

    final none = await sizeWith(DiagramToneRow.none);
    final one = await sizeWith(DiagramToneRow.intervals);
    final two = await sizeWith(DiagramToneRow.intervalsAndNotes);
    expect(one.height, greaterThan(none.height));
    expect(two.height, greaterThan(one.height));
    expect(two.width, none.width);
  });

  testWidgets('sin raíz sigue funcionando (sin intervalos)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ChordDiagramWidget(
          chordName: 'X',
          fretPositions: const [8, -1, 10, 9, -1, -1],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('la leyenda solo muestra las familias presentes', (tester) async {
    await tester.pumpWidget(_wrap(const IntervalLegend(labels: ['R', '3', '5'])));
    expect(find.text('Raíz'), findsOneWidget);
    expect(find.text('3ª'), findsOneWidget);
    expect(find.text('5ª'), findsOneWidget);
    expect(find.text('7ª'), findsNothing);
    expect(find.text('Tensión'), findsNothing);
  });
}
