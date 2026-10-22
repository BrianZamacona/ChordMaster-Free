import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/features/chords/chord_viewmodel.dart';
import 'package:chordmaster_free/features/progressions/progressions_screen.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/models/chord.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';
import '../support/in_memory_store.dart';

class _FakeChords extends ChordViewModel {
  _FakeChords(this.chords);

  final List<Chord> chords;

  @override
  ChordState build() => ChordState(allChords: chords, filteredChords: chords, isLoading: false);

  @override
  Chord? findByName(String name) => chords.where((c) => c.name == name).firstOrNull;
}

void main() {
  final raw = loadChordJson();
  final builder = ProgressionBuilder([
    for (final c in raw) ChordFingerings.fromJson(c),
  ]);
  final chords = [for (final c in raw) Chord.fromJson(c)];
  final progression = progressions.firstWhere((p) => p.id == 'v1-2'); // I-V-vi-IV

  List<String> frets(ProgressionPlan plan) => [
    for (final s in plan.steps) s.voicing.jsonFrets.join(','),
  ];

  group('buildProgressionPlan con digitaciones elegidas', () {
    test('solo cambia el acorde elegido; los demás quedan como en el camino óptimo', () {
      final optimal = buildProgressionPlan(builder, progression, 0);
      // F: tríada en las cuerdas 3-2-1 en lugar de la cejilla.
      const triad = (frets: [-1, -1, -1, 10, 10, 8], fingers: [0, 0, 0, 2, 3, 1]);
      final chosen = buildProgressionPlan(builder, progression, 0, chosen: {3: triad});

      expect(frets(chosen).take(3), frets(optimal).take(3));
      expect(frets(chosen)[3], '-1,-1,-1,10,10,8');
      expect([for (final s in chosen.steps) s.chosen], [false, false, false, true]);
      // La transición hacia el acorde elegido se recalcula con la nueva forma.
      expect(chosen.steps[3].transition!.fretShift, isNot(optimal.steps[3].transition!.fretShift));
    });
  });

  testWidgets('tocar un acorde abre sus posiciones; elegir una la usa y se puede volver', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 2000);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryStore()),
        progressionBuilderProvider.overrideWith((ref) async => builder),
        chordViewModelProvider.overrideWith(() => _FakeChords(chords)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ProgressionsContent())),
      ),
    );
    await tester.pumpAndSettle();
    final defaultF = tester.widget<ChordDiagramWidget>(
      find.descendant(of: find.byKey(const Key('step-3')), matching: find.byType(ChordDiagramWidget)),
    ).fretPositions;

    await tester.tap(find.byKey(const Key('step-3')));
    await tester.pumpAndSettle();
    expect(find.text('Posiciones de F'), findsOneWidget);
    // Glosario completo: CAGED, voicings y tríadas.
    expect(find.byKey(const Key('glossary-caged-0')), findsOneWidget);
    expect(find.byKey(const Key('glossary-triadInversions-0')), findsOneWidget);

    final triad = find.byKey(const Key('glossary-triadInversions-0'));
    await tester.ensureVisible(triad);
    await tester.tap(triad);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('step-chosen-3')), findsOneWidget);
    final chosenF = tester.widget<ChordDiagramWidget>(
      find.descendant(of: find.byKey(const Key('step-3')), matching: find.byType(ChordDiagramWidget)),
    ).fretPositions;
    expect(chosenF, isNot(defaultF));
    expect(chosenF.take(3), [-1, -1, -1]);

    await tester.tap(find.byKey(const Key('step-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-fingering')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('step-chosen-3')), findsNothing);

    // Cambiar de tonalidad descarta lo elegido.
    container.read(progressionsViewModelProvider.notifier)
      ..chooseFingering(0, (frets: const [-1, 3, 2, 0, 1, 0], fingers: const [0, 3, 2, 0, 1, 0]))
      ..setTonic(7);
    expect(container.read(progressionsViewModelProvider).chosen, isEmpty);
  });
}
