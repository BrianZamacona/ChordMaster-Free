import 'dart:io';

import 'package:chordmaster_free/data/models/note_coordinate.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:chordmaster_free/ui/widgets/fret_grid_geometry.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/paint_matchers.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}

ResolvedPattern _pattern(int start, int end, List<NoteCoordinate> coords) =>
    ResolvedPattern(
      scaleId: '',
      scaleName: '',
      systemId: '',
      systemName: '',
      positionId: '',
      positionName: '',
      startingFret: start,
      endFret: end,
      coordinates: coords,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FretGridGeometry grid(int start, int end) => FretGridGeometry(
    width: 328,
    height: 180,
    startFret: start,
    endFret: end,
  );

  group('geometría', () {
    test('el aire queda antes de la cejuela y el traste 1 después', () {
      final g = grid(0, 4);
      for (var s = 1; s <= 6; s++) {
        expect(g.noteOffset(s, 0).dx, lessThan(g.nutX));
        expect(g.noteOffset(s, 1).dx, greaterThan(g.nutX));
      }
    });

    test('el traste N está centrado entre los alambres N-1 y N', () {
      final g = grid(0, 12);
      expect(g.fretLineX(0), g.nutX);
      for (var n = 1; n <= 12; n++) {
        expect(
          g.noteOffset(1, n).dx,
          closeTo((g.fretLineX(n - 1) + g.fretLineX(n)) / 2, 1e-9),
        );
      }
    });

    test('cada traste está a un ancho de celda del siguiente', () {
      for (final g in [grid(0, 12), grid(5, 9), grid(13, 24)]) {
        for (var n = g.firstFret; n < g.lastFret; n++) {
          expect(
            g.noteOffset(1, n + 1).dx - g.noteOffset(1, n).dx,
            closeTo(g.fretWidth, 1e-9),
          );
        }
      }
    });

    test('una nota al aire no cambia las celdas de los demás trastes', () {
      final withOpen = grid(0, 4);
      final withoutOpen = grid(1, 4);
      expect(withOpen.fretWidth, withoutOpen.fretWidth);
      expect(withOpen.cellCount, 4);
      for (var n = 1; n <= 4; n++) {
        expect(withOpen.noteOffset(3, n), withoutOpen.noteOffset(3, n));
      }
    });

    test('el número de traste no toca las notas de la 6ª cuerda', () {
      const neck = FretGridGeometry(
        width: 744,
        height: 200,
        startFret: 1,
        endFret: 24,
        fixedFretWidth: FretboardNeck.minFretWidth,
        maxNoteRadius: 14,
      );
      for (final g in [grid(0, 4), grid(5, 9), neck]) {
        // El número mide unos 13 de alto: 6.5 sobre su centro.
        expect(g.fretNumberY - 6.5, greaterThanOrEqualTo(g.boardBottom + g.radius));
      }
    });

    test('la cejuela solo está junto al traste 1', () {
      expect(grid(0, 4).hasNut, isTrue);
      expect(grid(1, 4).hasNut, isTrue);
      expect(grid(5, 9).hasNut, isFalse);
    });

    test('la afinación va de la 1ª a la 6ª, solo con sostenidos', () {
      expect(tuningLabels, ['e', 'B', 'G', 'D', 'A', 'E']);
      expect(FretGridGeometry.tuningLabelX, lessThan(grid(5, 9).nutX));
    });
  });

  group('dibujo', () {
    Future<RenderObject> board(
      WidgetTester tester,
      ResolvedPattern pattern,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 328,
                child: FretboardDiagram(pattern: pattern),
              ),
            ),
          ),
        ),
      );
      return tester.renderObject(
        find.descendant(
          of: find.byType(FretboardDiagram),
          matching: find.byType(CustomPaint),
        ),
      );
    }

    // Las posiciones de scales_master.json están dadas para C y solo suben: en
    // E la pentatónica menor empieza en el traste 4, así que las notas al aire
    // de una posición salen con raíz C. E al aire se ve en el mástil completo.
    testWidgets('C menor pentatónica, primera posición: notas en la columna de '
        'aire y la afinación completa', (tester) async {
      final positions = await tester.runAsync(
        () => ScaleRepository(bundle: _FileBundle()).getPositions(
          scaleId: 'pentatonic_minor',
          rootSemitone: 0,
        ),
      );
      final first = positions!.first;
      expect(first.startingFret, 0);
      final open = first.coordinates.where((c) => c.fret == 0).toList();
      expect(open, isNotEmpty);

      final render = await board(tester, first);
      // Seis nombres de cuerda más el número de traste y una etiqueta por nota.
      expect(
        render,
        paintsExactlyCountTimes(
          #drawParagraph,
          tuningLabels.length + 1 + first.coordinates.length,
        ),
      );
      expect(openRingCount(render), open.length);
      expect(render, paintsNut);
    });

    testWidgets('sin notas al aire la afinación sigue ahí, sin anillos', (
      tester,
    ) async {
      final render = await board(
        tester,
        _pattern(5, 9, const [
          NoteCoordinate(string: 1, fret: 5, isRoot: true, interval: '1'),
        ]),
      );
      expect(
        render,
        paintsExactlyCountTimes(#drawParagraph, tuningLabels.length + 2),
      );
      expect(openRingCount(render), 0);
    });

    group('la nota al aire no se duplica con la afinación', () {
      const open = NoteCoordinate(
        string: 1,
        fret: 0,
        isRoot: false,
        note: 'E',
        interval: '3',
      );

      Future<RenderObject> labelled(
        WidgetTester tester,
        FretboardLabel label,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: lightTheme,
            home: Scaffold(
              body: SizedBox(
                width: 328,
                child: FretboardDiagram(
                  pattern: _pattern(0, 4, const [open]),
                  label: label,
                ),
              ),
            ),
          ),
        );
        return tester.renderObject(
          find.descendant(
            of: find.byType(FretboardDiagram),
            matching: find.byType(CustomPaint),
          ),
        );
      }

      testWidgets('con notas, esa cuerda ya no repite su nombre', (tester) async {
        // Cinco nombres de cuerda, el número de traste y la nota.
        expect(
          await labelled(tester, FretboardLabel.note),
          paintsExactlyCountTimes(#drawParagraph, 5 + 1 + 1),
        );
      });

      testWidgets('con intervalos, la nota no dice la afinación: se conserva', (
        tester,
      ) async {
        expect(
          await labelled(tester, FretboardLabel.interval),
          paintsExactlyCountTimes(#drawParagraph, 6 + 1 + 1),
        );
      });
    });

    testWidgets('una posición desde el traste 5 no dibuja cejuela', (
      tester,
    ) async {
      final render = await board(
        tester,
        _pattern(5, 9, const [
          NoteCoordinate(string: 1, fret: 5, isRoot: true, interval: '1'),
        ]),
      );
      expect(render, isNot(paintsNut));
    });

    testWidgets('los enlaces llegan a la columna de aire', (tester) async {
      await board(
        tester,
        _pattern(0, 12, const [
          NoteCoordinate(string: 6, fret: 0, isRoot: true, interval: '1'),
          NoteCoordinate(string: 4, fret: 2, isRoot: true, interval: '1'),
        ]),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
