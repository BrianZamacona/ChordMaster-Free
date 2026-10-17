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

void main() {
  final builder = _realBuilder();

  const expectedNames = {
    0: ['C Major', 'G Major', 'A Minor', 'F Major'],
    7: ['G Major', 'D Major', 'E Minor', 'C Major'],
    5: ['F Major', 'C Major', 'D Minor', 'A# Major'],
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
      for (final name in entry.value) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
    });
  }

  testWidgets('cambiar de tónica cambia los nombres de acordes', (tester) async {
    final container = await _pump(tester, builder);
    expect(find.text('C Major'), findsOneWidget);

    container.read(progressionsViewModelProvider.notifier).setTonic(7);
    await tester.pumpAndSettle();

    expect(find.text('C Major'), findsOneWidget); // IV de G
    expect(find.text('G Major'), findsOneWidget);
    expect(find.text('A Minor'), findsNothing);
  });

  testWidgets('sin candidatos muestra un mensaje claro', (tester) async {
    await _pump(tester, ProgressionBuilder(const []));

    expect(find.byKey(const Key('progression-problem')), findsOneWidget);
    expect(find.textContaining('No hay digitaciones válidas'), findsOneWidget);
    expect(find.byType(ChordDiagramWidget), findsNothing);
  });
}
