import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_notifier.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_screen.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final data =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  final major = ScaleDefinition.fromJson(
    (data['scales'] as List<dynamic>).cast<Map<String, dynamic>>().firstWhere(
      (s) => s['id'] == 'major',
    ),
  );
  final args = (scale: major, root: 0);

  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> pump(WidgetTester tester, {Size size = const Size(360, 800)}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryStore()),
          scaleRepositoryProvider.overrideWithValue(
            ScaleRepository(bundle: _FileBundle()),
          ),
        ],
        child: MaterialApp(
          theme: lightTheme,
          home: ScaleDetailScreen(scale: major),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  ScaleDetailState stateOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ScaleDetailScreen)),
  ).read(scaleDetailProvider(args));

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('scale-pattern')));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, int index) async {
    await openSheet(tester);
    final row = find.byKey(Key('pattern-$index'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  ResolvedPattern board(WidgetTester tester) =>
      tester.widget<FretboardDiagram>(find.byType(FretboardDiagram).first).pattern;

  testWidgets('sin digitación elegida: vista previa de la primera posición', (
    tester,
  ) async {
    await pump(tester);
    final state = stateOf(tester);
    expect(state.selectedPatternIndex, isNull);
    expect(state.hasSelectedPattern, isFalse);
    expect(board(tester), same(state.visiblePatterns.first));
    expect(find.textContaining('Vista previa'), findsOneWidget);
  });

  testWidgets('la hoja agrupa por sistema y da el rango de trastes', (
    tester,
  ) async {
    await pump(tester);
    await openSheet(tester);
    expect(find.text(AppStrings.scaleWholeNeck), findsOneWidget);
    final state = stateOf(tester);
    expect(
      find.byKey(Key('pattern-${state.visiblePatterns.length - 1}'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('CAGED'), findsWidgets);
    final first = state.visiblePatterns.first;
    expect(
      find.descendant(
        of: find.byKey(const Key('pattern-0')),
        matching: find.text(
          AppStrings.scaleFretRange(first.startingFret, first.endFret),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('elegir una posición actualiza el botón y el diapasón', (
    tester,
  ) async {
    await pump(tester);
    await choose(tester, 3);
    final state = stateOf(tester);
    final chosen = state.visiblePatterns[3];
    expect(state.selectedPatternIndex, 3);
    expect(board(tester), same(chosen));
    expect(
      find.text('${AppStrings.scaleFingering}: ${chosen.positionName}'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('scale-pattern-context'))).data,
      contains(AppStrings.scaleFretRange(chosen.startingFret, chosen.endFret)),
    );
  });

  testWidgets('"Todo el mástil" limpia la selección', (tester) async {
    await pump(tester);
    await choose(tester, 2);
    await openSheet(tester);
    await tester.tap(find.byKey(const Key('pattern-whole-neck')));
    await tester.pumpAndSettle();
    expect(stateOf(tester).selectedPatternIndex, isNull);
    expect(find.text(AppStrings.scaleFingering), findsOneWidget);
  });

  testWidgets('la ✕ limpia la selección', (tester) async {
    await pump(tester);
    await choose(tester, 2);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('scale-pattern')),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();
    expect(stateOf(tester).selectedPatternIndex, isNull);
  });

  testWidgets('‹ › pasan de posición y se detienen en los extremos', (
    tester,
  ) async {
    await pump(tester);
    await choose(tester, 0);
    final previous = find.byKey(const Key('scale-pattern-previous'));
    expect(tester.widget<IconButton>(previous).onPressed, isNull);
    await tester.tap(find.byKey(const Key('scale-pattern-next')));
    await tester.pumpAndSettle();
    expect(stateOf(tester).selectedPatternIndex, 1);
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(stateOf(tester).selectedPatternIndex, 0);
  });

  testWidgets('cambiar la tónica limpia la selección', (tester) async {
    await pump(tester);
    await choose(tester, 2);
    await tester.tap(find.byKey(const Key('scale-root')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('root-E')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(stateOf(tester).selectedPatternIndex, isNull);
    expect(stateOf(tester).rootName, 'E');
  });

  testWidgets('cambiar el sistema limpia la selección', (tester) async {
    await pump(tester);
    await choose(tester, 2);
    await tester.tap(find.byKey(const Key('scale-system')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'CAGED').first);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(stateOf(tester).selectedPatternIndex, isNull);
    expect(
      stateOf(tester).visiblePatterns.map((p) => p.systemId).toSet(),
      {stateOf(tester).selectedSystemId},
    );
  });

  testWidgets('en pantalla ancha el diapasón no pasa de 900 y queda centrado', (
    tester,
  ) async {
    await pump(tester, size: const Size(1400, 900));
    final rect = tester.getRect(find.byType(FretboardDiagram).first);
    expect(rect.width, lessThanOrEqualTo(900));
    expect(rect.center.dx, closeTo(700, 1));
    expect(tester.takeException(), isNull);
  });

  for (final language in AppLanguage.values) {
    testWidgets('a 360 dp (${language.name}) los tres botones y el contexto '
        'caben, con cualquier posición elegida', (tester) async {
      CurrentLanguage.value = language;
      await pump(tester);
      final count = stateOf(tester).visiblePatterns.length;
      for (var i = 0; i < count; i++) {
        await choose(tester, i);
        expect(tester.takeException(), isNull, reason: 'posición $i');
        final pill = tester.getRect(find.byKey(const Key('scale-pattern')));
        expect(pill.left, greaterThanOrEqualTo(0));
        expect(pill.right, lessThanOrEqualTo(360));
      }
    });
  }
}
