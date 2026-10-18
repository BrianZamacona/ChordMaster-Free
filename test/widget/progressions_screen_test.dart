import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/features/progressions/progressions_screen.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProgressionBuilder _realBuilder() {
  final raw =
      jsonDecode(File('assets/data/chords.json').readAsStringSync())
          as List<dynamic>;
  return ProgressionBuilder([
    for (final c in raw) ChordFingerings.fromJson(c as Map<String, dynamic>),
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

  testWidgets('sin candidatos muestra un mensaje claro', (tester) async {
    await _pump(tester, ProgressionBuilder(const []));

    expect(find.byKey(const Key('progression-problem')), findsOneWidget);
    expect(find.textContaining('No hay digitaciones válidas'), findsOneWidget);
    expect(find.byType(ChordDiagramWidget), findsNothing);
  });
}
