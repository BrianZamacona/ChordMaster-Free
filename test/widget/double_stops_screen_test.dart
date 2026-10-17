import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/double_stops.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_fretboard.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_layout.dart';
import 'package:chordmaster_free/ui/scales/double_stops/double_stops_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('noteTextColor: blanco en la raíz, onPrimary en el intervalo', () {
    final dark = ColorScheme.fromSeed(
      seedColor: Colors.pink,
      brightness: Brightness.dark,
    );
    expect(noteTextColor(true, dark), Colors.white);
    expect(noteTextColor(false, dark), dark.onPrimary);
    expect(noteTextColor(false, dark), isNot(Colors.white));
  });
  group('noteOffset', () {
    const size = Size(280, 136);

    test('valores fijos (0–12: 13 trastes, ancho de traste 20, separación 20)', () {
      expect(noteOffset(0, 0, size), const Offset(30, 16));
      expect(noteOffset(5, 12, size), const Offset(270, 116));
      expect(noteOffset(2, 5, size), const Offset(130, 56));
    });

    test('respeta startFret y fretCount (13–24)', () {
      const upper = Size(260, 136);
      expect(
        noteOffset(1, 13, upper, startFret: 13, fretCount: 12),
        const Offset(30, 36),
      );
      expect(
        noteOffset(3, 24, upper, startFret: 13, fretCount: 12),
        const Offset(250, 76),
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
