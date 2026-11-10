import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/domain/lessons/curriculum.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('miniaturas (mapa a 64 dp, unidad a 56)', () {
    test('el número del dedo mide unos 7 dp (antes, unos 4)', () {
      expect(chordDiagramMetrics(64).fingerFont, greaterThanOrEqualTo(7));
      expect(chordDiagramMetrics(56).fingerFont, greaterThanOrEqualTo(6.4));
    });

    test('desde la cejuela la rejilla queda centrada (antes, unos 2.5 dp a la derecha)', () {
      for (final w in [56.0, 64.0, 88.0, 110.0, 200.0]) {
        expect(chordDiagramMetrics(w).gridCenter, closeTo(w / 2, 1e-9), reason: '$w');
      }
    });

    test('no crece de alto: muestra 4 trastes en vez de 5', () {
      expect(chordDiagramMetrics(64).frets, 4);
      expect(chordDiagramMetrics(200).frets, 5);
      // Antes medía 69.6 dp de alto a 64 de ancho.
      expect(chordDiagramMetrics(64).height, lessThanOrEqualTo(69.6));
    });

    test('cada acorde dibujado en el mapa o en una guía cabe en esos 4 trastes', () {
      final byName = {for (final c in loadChordJson()) c['displayName'] as String: c};
      final arts = [for (final u in lessonUnits) u.art, for (final g in guides) g.art];
      final names = {for (final a in arts) if (a case ChordArt(:final chord)) chord};
      expect(names, isNotEmpty);
      for (final name in names) {
        final c = byName[name]!;
        final frets = (c['fretPositions'] as List).cast<int>();
        final base = (c['baseFret'] as int?) ?? diagramBaseFret(frets);
        final offset = base > 1 ? base - 1 : 0;
        for (final f in frets.where((f) => f > 0)) {
          expect(f - offset, inInclusiveRange(1, chordDiagramMetrics(64).frets), reason: name);
        }
      }
    });

    test('lejos de la cejuela deja lugar al número del traste a la izquierda', () {
      expect(chordDiagramMetrics(64, baseFret: 5).gridCenter, greaterThan(32));
    });

    test('los diagramas grandes no cambian de tamaño de número', () {
      // 200 dp: radio 0.36 del espacio entre cuerdas, número 1.15 del radio.
      const spacing = (200 - 200 * 0.08 * 2) / 5;
      expect(chordDiagramMetrics(200).fingerFont, closeTo(spacing * 0.36 * 1.15, 1e-9));
    });
  });

  testWidgets('C abierto a 64 dp se dibuja sin errores', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: Scaffold(
          body: Center(
            child: ChordDiagramWidget(
              chordName: 'C',
              fretPositions: const [-1, 3, 2, 0, 1, 0],
              fingerPositions: const [0, 3, 2, 0, 1, 0],
              root: 'C',
              size: 64,
              showChordName: false,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ChordDiagramWidget)).width, 64);
  });
}
