import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/features/progressions/progressions_screen.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/chord_data.dart';
import '../support/in_memory_store.dart';

ProgressionBuilder _realBuilder() {
  final raw = loadChordJson();
  return ProgressionBuilder([
    for (final c in raw) ChordFingerings.fromJson(c),
  ]);
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  ProgressionBuilder builder,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 2000);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryStore()),
      progressionBuilderProvider.overrideWith((ref) async => builder),
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
  return container;
}

/// Nombres visibles de los acordes de la progresión, en orden.
List<String> _stepNames(WidgetTester tester) => [
  for (var i = 0; tester.any(find.byKey(Key('step-name-$i'))); i++)
    tester.widget<Text>(find.byKey(Key('step-name-$i'))).data!,
];

void main() {
  final builder = _realBuilder();

  const expectedNames = {
    0: ['C', 'G', 'Am', 'F'],
    7: ['G', 'D', 'Em', 'C'],
    5: ['F', 'C', 'Dm', 'A#'],
  };

  for (final entry in expectedNames.entries) {
    testWidgets('I-V-vi-IV con tónica ${entry.key}: 4 diagramas y 3 chips', (
      tester,
    ) async {
      final container = await _pump(tester, builder);
      container.read(progressionsViewModelProvider.notifier)
        ..setProgression('v1-2')
        ..setTonic(entry.key);
      await tester.pumpAndSettle();

      expect(find.byType(ChordDiagramWidget), findsNWidgets(4));
      expect(find.byType(ProgressionTransitionChip), findsNWidgets(3));
      expect(_stepNames(tester), entry.value);
    });
  }

  testWidgets('cambiar de tónica cambia los nombres de acordes', (tester) async {
    final container = await _pump(tester, builder);
    expect(_stepNames(tester), ['C', 'G', 'Am', 'F']);

    container.read(progressionsViewModelProvider.notifier).setTonic(7);
    await tester.pumpAndSettle();

    expect(_stepNames(tester), ['G', 'D', 'Em', 'C']); // C = IV de G
  });

  testWidgets('modo principiante en G con I-V-vi-IV: sin cejilla grande', (
    tester,
  ) async {
    final container = await _pump(tester, builder);
    container.read(progressionsViewModelProvider.notifier)
      ..setProgression('v1-2')
      ..setTonic(7);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('barre-chip')), findsNothing);

    await tester.tap(find.text('Principiante'));
    await tester.pumpAndSettle();

    expect(container.read(progressionsViewModelProvider).beginner, isTrue);
    expect(find.byType(ChordDiagramWidget), findsNWidgets(4));
    expect(find.textContaining('cejilla grande'), findsNothing);

    await tester.tap(find.text('Estándar'));
    await tester.pumpAndSettle();
    expect(container.read(progressionsViewModelProvider).beginner, isFalse);
    expect(find.byKey(const Key('barre-chip')), findsNothing);
  });

  testWidgets('Mi progresión: se arma por grados y explica por qué', (
    tester,
  ) async {
    final container = await _pump(tester, builder);
    expect(find.byKey(const Key('progression-why')), findsOneWidget);
    expect(find.textContaining('cadencia rota'), findsOneWidget);

    await tester.tap(find.byKey(const Key('progression-pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progression-custom')));
    await tester.pumpAndSettle();

    expect(container.read(progressionsViewModelProvider).isCustom, isTrue);
    expect(find.byType(ChordDiagramWidget), findsNothing);
    expect(find.byKey(const Key('progression-why')), findsNothing);

    for (final n in ['ii', 'V', 'I']) {
      await tester.tap(find.byKey(Key('add-degree-$n')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(ChordDiagramWidget), findsNWidgets(3));
    expect(_stepNames(tester), ['Dm', 'G', 'C']);
    expect(find.textContaining('cadencia auténtica'), findsOneWidget);

    await tester.tap(find.byKey(const Key('custom-clear')));
    await tester.pumpAndSettle();
    expect(container.read(progressionsViewModelProvider).custom, isEmpty);
    expect(find.byType(ChordDiagramWidget), findsNothing);
  });

  testWidgets('Mi progresión: con 7ª y en otra escala de base', (tester) async {
    final container = await _pump(tester, builder);
    final vm = container.read(progressionsViewModelProvider.notifier)..setProgression('custom');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('custom-sevenths')));
    await tester.pumpAndSettle();
    expect(container.read(progressionsViewModelProvider).customSevenths, isTrue);
    for (final n in ['ii7', 'V7', 'Imaj7']) {
      await tester.tap(find.byKey(Key('add-degree-$n')));
      await tester.pumpAndSettle();
    }
    expect(_stepNames(tester), ['Dm7', 'G7', 'Cmaj7']);
    expect(find.textContaining('V7 → Imaj7: cadencia auténtica'), findsOneWidget);

    // La menor natural ofrece sus grados; los acordes ya puestos no cambian.
    await tester.tap(find.byKey(const Key('custom-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menor natural').last);
    await tester.pumpAndSettle();
    expect(container.read(progressionsViewModelProvider).customMode, 5);
    expect(find.byKey(const Key('add-degree-♭VII7')), findsOneWidget);
    expect(find.byKey(const Key('add-degree-V7')), findsNothing);
    expect(_stepNames(tester), ['Dm7', 'G7', 'Cmaj7']);
    vm.addCustomDegree('♭VII7');
    await tester.pumpAndSettle();
    expect(_stepNames(tester).last, 'A#7');
  });

  testWidgets('Mi progresión: acordes de otra fuente, con su porqué', (tester) async {
    final container = await _pump(tester, builder);
    container.read(progressionsViewModelProvider.notifier).setProgression('custom');
    await tester.pumpAndSettle();

    for (final n in ['I']) {
      await tester.tap(find.byKey(Key('add-degree-$n')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('custom-source-secondaryDominant')));
    await tester.pumpAndSettle();
    expect(find.text('El V7 de cada grado: ponlo justo antes de él.'), findsOneWidget);
    expect(find.byKey(const Key('add-degree-ii')), findsNothing);
    expect(find.text('V7/ii · A7'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-degree-VI7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('custom-source-scale')));
    await tester.pumpAndSettle();
    for (final n in ['ii', 'V']) {
      await tester.tap(find.byKey(Key('add-degree-$n')));
      await tester.pumpAndSettle();
    }
    expect(_stepNames(tester), ['C', 'A7', 'Dm', 'G']);
    expect(find.textContaining('Recorrido: I (reposo) → VI7 → ii (preparación)'), findsOneWidget);
    expect(
      find.text('V7/ii: la dominante de ii: su 3ª sube medio tono a la raíz de ii.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('custom-source-negative')));
    await tester.pumpAndSettle();
    expect(find.text('iv ⇄ V · Fm'), findsOneWidget);
  });

  testWidgets('Mi progresión: tocar un acorde cambia cuánto dura', (tester) async {
    final container = await _pump(tester, builder);
    container.read(progressionsViewModelProvider.notifier)
      ..setProgression('custom')
      ..addCustomDegree('I')
      ..addCustomDegree('V');
    await tester.pumpAndSettle();
    expect(find.text('I · 1 compás'), findsOneWidget);
    expect(find.text('Un compás por acorde, un golpe hacia abajo en cada pulso.'), findsOneWidget);

    await tester.tap(find.text('V · 1 compás'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuánto dura V?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('custom-beats-2')));
    await tester.pumpAndSettle();
    expect(container.read(progressionsViewModelProvider).customBeats, [4, 2]);
    expect(find.text('V · ½ compás'), findsOneWidget);
    expect(
      find.text('Cada acorde dura lo que le pusiste, un golpe hacia abajo en cada pulso.'),
      findsOneWidget,
    );
  });

  testWidgets('sin candidatos muestra un mensaje claro', (tester) async {
    await _pump(tester, ProgressionBuilder(const []));

    expect(find.byKey(const Key('progression-problem')), findsOneWidget);
    expect(find.textContaining('No hay digitaciones válidas'), findsOneWidget);
    expect(find.byType(ChordDiagramWidget), findsNothing);
  });
}
