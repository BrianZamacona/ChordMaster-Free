import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/double_stops.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_fretboard.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_layout.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_screen.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/paint_matchers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('segmentLabelOffset', () {
    test('en el hueco sobre la cuerda superior, al centro de la línea', () {
      expect(
        segmentLabelOffset(const Offset(50, 36), const Offset(90, 56), 20),
        const Offset(70, 26),
      );
    });

    test('pareja en la 1ª cuerda: bajo la cuerda inferior', () {
      expect(
        segmentLabelOffset(const Offset(50, 16), const Offset(50, 36), 20),
        const Offset(50, 46),
      );
    });
  });
  group('noteOffset', () {
    // Columna de afinación de 32 y 12 celdas de 20: el traste N va entre los
    // alambres N-1 y N.
    const size = Size(272, 136);

    test('0–12: el aire en su columna y el traste N en la celda N', () {
      expect(noteOffset(0, 0, size), const Offset(21, 16));
      expect(noteOffset(0, 1, size), const Offset(42, 16));
      expect(noteOffset(5, 12, size), const Offset(262, 116));
      expect(noteOffset(2, 5, size), const Offset(122, 56));
    });

    test('respeta startFret y endFret (13–24)', () {
      expect(
        noteOffset(1, 13, size, startFret: 13, endFret: 24),
        const Offset(42, 36),
      );
      expect(
        noteOffset(3, 24, size, startFret: 13, endFret: 24),
        const Offset(262, 76),
      );
    });
  });

  group('cejuela de double stops', () {
    Future<RenderObject> board(WidgetTester tester, FretRange range) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: DoubleStopFretboard(
              pairs: const [],
              range: range,
              tonic: 'C',
            ),
          ),
        ),
      );
      return tester.renderObject(
        find.descendant(
          of: find.byType(DoubleStopFretboard),
          matching: find.byType(CustomPaint),
        ),
      );
    }

    testWidgets('0–12 la dibuja', (tester) async {
      expect(
        await board(tester, const FretRange(0, 12)),
        paintsNut,
      );
    });

    testWidgets('13–24 no la dibuja', (tester) async {
      expect(
        await board(tester, const FretRange(13, 24)),
        isNot(paintsNut),
      );
    });
  });

  test('los segmentos usan exactamente noteOffset de sus dos notas', () {
    const size = Size(333, 170);
    final pairs = findDiatonicDoubleStopPairs(
      'C',
      DiatonicDoubleStopInterval.third,
      const FretRange(0, 12),
    ).expand((g) => g.pairs).toList();
    expect(pairs, isNotEmpty);

    final segments = doubleStopSegments(pairs, size);
    expect(segments, hasLength(pairs.length));
    for (var i = 0; i < pairs.length; i++) {
      expect(
        segments[i].from,
        noteOffset(pairs[i].root.stringIndex, pairs[i].root.fret, size),
      );
      expect(
        segments[i].to,
        noteOffset(pairs[i].interval.stringIndex, pairs[i].interval.fret, size),
      );
    }
  });

  testWidgets('C, 3ª, adyacente, 0–12: 5 grupos y las parejas del golden', (
    tester,
  ) async {
    final golden =
        (jsonDecode(File('test/fixtures/golden/double_stops.json').readAsStringSync())
                as List<dynamic>)
            .cast<Map<String, dynamic>>();
    final expected = golden.firstWhere(
      (c) =>
          c['kind'] == 'diatonic' &&
          c['key'] == 'C' &&
          c['interval'] == '3rd' &&
          c['pattern'] == 'adjacent' &&
          (c['range'] as Map<String, dynamic>)['start'] == 0,
    );
    final expectedPairs = (expected['rows'] as List<dynamic>).length;

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 6000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DoubleStopsContent())),
      ),
    );
    await tester.pumpAndSettle();

    final boards = tester.widgetList<DoubleStopFretboard>(
      find.byType(DoubleStopFretboard),
    );
    expect(boards, hasLength(5));
    expect(
      boards.fold<int>(0, (sum, b) => sum + b.pairs.length),
      expectedPairs,
    );
  });
}
