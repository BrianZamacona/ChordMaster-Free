import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/domain/voicing/fingering_metrics.dart';
import 'package:chordmaster_free/features/chords/chord_compare_screen.dart';
import 'package:chordmaster_free/features/chords/chord_explorer_screen.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/features/chords/fingering_selection.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChordViewModel extends ChordViewModel {
  _FakeChordViewModel(this._chords);

  final List<Chord> _chords;

  @override
  ChordState build() => ChordState(
        allChords: _chords,
        filteredChords: _chords,
        isLoading: false,
      );

  @override
  Chord? findByName(String name) {
    for (final chord in _chords) {
      if (chord.name == name) return chord;
    }
    return null;
  }
}

final _cMajor = Chord.fromJson(
  (jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .firstWhere((c) => c['name'] == 'C Major'),
);

Future<void> _pump(WidgetTester tester, Widget child, {double width = 1200}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chordViewModelProvider.overrideWith(
          () => _FakeChordViewModel([_cMajor]),
        ),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _compare(String? sel) => ChordCompareScreen(
      chordId: Uri.encodeComponent('C Major'),
      selection: sel,
    );

void main() {
  test('C Major tiene datos suficientes para los tests', () {
    expect(_cMajor.cagedPositions.length, greaterThanOrEqualTo(4));
    expect(_cMajor.voicings, isNotEmpty);
  });

  group('parseFingeringSelection', () {
    test('ignora claves inválidas y repetidas, corta en 3', () {
      final refs = parseFingeringSelection(
        'caged:0,caged:0,nope,voicings:x,caged:99,caged:-1,:,caged:1,'
        'voicings:0,caged:2',
        _cMajor,
      );
      expect([for (final r in refs) r.key], ['caged:0', 'caged:1', 'voicings:0']);
    });

    test('null y vacío dan lista vacía', () {
      expect(parseFingeringSelection(null, _cMajor), isEmpty);
      expect(parseFingeringSelection('', _cMajor), isEmpty);
    });
  });

  for (final width in [1200.0, 400.0]) {
    testWidgets('2 selecciones → 2 diagramas y fila de costo (ancho $width)', (
      tester,
    ) async {
      await _pump(tester, _compare('caged:0,voicings:0'), width: width);

      expect(tester.takeException(), isNull);
      expect(find.byType(ChordDiagramWidget), findsNWidgets(2));
      expect(find.text(AppStrings.metricCost), findsNWidgets(2));
      expect(find.text(AppStrings.compareEmpty), findsNothing);
    });
  }

  testWidgets('3 selecciones: los mejores se marcan con ícono según bestIndices', (
    tester,
  ) async {
    await _pump(tester, _compare('caged:0,caged:1,caged:2'));
    expect(find.byType(ChordDiagramWidget), findsNWidgets(3));

    final metrics = [
      for (var i = 0; i < 3; i++)
        analyzeFingering(
          jsonFrets: _cMajor.cagedPositions[i].fretPositions,
          jsonFingers: _cMajor.cagedPositions[i].fingerPositions,
          root: _cMajor.root,
          intervals: _cMajor.intervals,
        ),
    ];
    final expected = {
      'cost': bestIndices([for (final m in metrics) m.ergonomicCost]),
      'fingers': bestIndices([for (final m in metrics) m.fingers]),
      'span': bestIndices([for (final m in metrics) m.fretSpan]),
      'muted': bestIndices([for (final m in metrics) m.mutedStrings]),
    };
    for (final entry in expected.entries) {
      for (var i = 0; i < 3; i++) {
        expect(
          find.byKey(Key('best-${entry.key}-$i')),
          entry.value.contains(i) ? findsOneWidget : findsNothing,
          reason: '${entry.key} columna $i',
        );
      }
    }
  });

  testWidgets('sin sel → estado vacío con botón de volver', (tester) async {
    await _pump(tester, _compare(null));

    expect(find.text(AppStrings.compareEmpty), findsOneWidget);
    expect(find.byKey(const Key('compare-back')), findsOneWidget);
    expect(find.byType(ChordDiagramWidget), findsNothing);
  });

  for (final sel in ['', 'basura', 'caged:99,voicings:-5', '::,,', 'caged:0']) {
    testWidgets('sel inválido "$sel" no lanza y muestra estado vacío', (
      tester,
    ) async {
      await _pump(tester, _compare(sel));

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.compareEmpty), findsOneWidget);
    });
  }

  testWidgets('acorde inexistente → estado vacío', (tester) async {
    await _pump(
      tester,
      const ChordCompareScreen(chordId: 'Nada', selection: 'caged:0,caged:1'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.compareEmpty), findsOneWidget);
  });

  testWidgets('explorador: barra se habilita con 2; con 3 se deshabilitan los demás', (
    tester,
  ) async {
    await _pump(
      tester,
      ChordExplorerScreen(chordId: Uri.encodeComponent('C Major')),
    );

    FilledButton bar() => tester.widget<FilledButton>(
          find.byKey(const Key('compare-bar-button')),
        );
    Checkbox box(String key) =>
        tester.widget<Checkbox>(find.byKey(Key('compare-$key')));
    Future<void> tap(String key) async {
      final finder = find.byKey(Key('compare-$key'));
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }

    expect(bar().onPressed, isNull);
    expect(find.text('${AppStrings.compareButton} (0)'), findsOneWidget);

    await tap('caged:0');
    expect(bar().onPressed, isNull);

    await tap('caged:1');
    expect(bar().onPressed, isNotNull);
    expect(find.text('${AppStrings.compareButton} (2)'), findsOneWidget);
    expect(box('caged:2').onChanged, isNotNull);

    await tap('caged:2');
    expect(find.text('${AppStrings.compareButton} (3)'), findsOneWidget);
    expect(box('caged:3').onChanged, isNull);
    expect(box('voicings:0').onChanged, isNull);
    expect(box('caged:0').onChanged, isNotNull);
    expect(find.byTooltip(AppStrings.compareMaxReached), findsWidgets);

    // Desmarcar libera un lugar.
    await tap('caged:0');
    expect(box('caged:3').onChanged, isNotNull);
    expect(find.byTooltip(AppStrings.compareMaxReached), findsNothing);
  });
}
