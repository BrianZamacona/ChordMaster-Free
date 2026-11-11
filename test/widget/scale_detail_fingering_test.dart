import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/models/note_coordinate.dart';
import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
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
  final scales = [
    for (final g in ['scales', 'modes'])
      for (final s in (data[g] as List<dynamic>))
        ScaleDefinition.fromJson(s as Map<String, dynamic>),
  ];
  final major = scales.firstWhere((s) => s.id == 'major');

  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    ScaleDefinition? scale,
    Size size = const Size(360, 800),
    String? position,
  }) async {
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
          home: ScaleDetailScreen(scale: scale ?? major, initialPosition: position),
        ),
      ),
    );
    await settle(tester);
  }

  ScaleDetailState stateOf(WidgetTester tester, [ScaleDefinition? scale, String? position]) =>
      ProviderScope.containerOf(
        tester.element(find.byType(ScaleDetailScreen, skipOffstage: false)),
      ).read(scaleDetailProvider((scale: scale ?? major, root: 0, position: position)));

  FretboardDiagram board(WidgetTester tester) =>
      tester.widget<FretboardDiagram>(find.byType(FretboardDiagram).first);

  Future<void> expand(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('scale-expand')));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(const Key('neck-pattern')));
    await tester.pumpAndSettle();
    final row = find.byKey(Key('pattern-$index'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  group('detalle', () {
    testWidgets('abierta desde una guía en la forma A: CAGED y esa digitación', (tester) async {
      await pump(tester, position: 'caged_a');
      final s = stateOf(tester, major, 'caged_a');
      expect(s.selectedSystemId, 'caged');
      expect(s.currentPattern?.positionId, 'caged_a');
      expect(board(tester).pattern.positionId, 'caged_a');
    });

    testWidgets('una digitación que no existe deja la predeterminada', (tester) async {
      await pump(tester, position: 'no_existe');
      final s = stateOf(tester, major, 'no_existe');
      expect(s.selectedSystemId, isNull);
      expect(s.selectedPatternIndex, isNull);
    });
    testWidgets('arriba solo queda la tónica', (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('scale-root')), findsOneWidget);
      expect(find.text(AppStrings.scaleSystem), findsNothing);
      expect(find.text(AppStrings.scaleFingering), findsNothing);
    });

    testWidgets('C mayor abre en la Posición 1 de 3NPS', (tester) async {
      await pump(tester);
      final state = stateOf(tester);
      expect(state.selectedPatternIndex, isNull);
      expect(state.hasSelectedPattern, isFalse);
      final preview = board(tester).pattern;
      expect(preview.systemId, 'three_nps');
      expect(preview.positionName, 'Posición 1');
      expect(preview.startingFret, 8);
      expect(
        tester.widget<Text>(find.byKey(const Key('scale-pattern-context'))).data,
        contains('Posición 1 · 3NPS'),
      );
    });

    testWidgets('la vista previa sigue en Posición 1 al cambiar de tónica', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('scale-root')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('root-A')));
      await settle(tester);
      final preview = board(tester).pattern;
      expect(preview.positionName, 'Posición 1');
      expect(preview.systemId, 'three_nps');
    });

    // 3NPS en las de 7 notas, la caja en pentatónicas y blues, CAGED en las
    // simétricas; siempre la primera posición que declara ese sistema.
    // Pentatónicas = las de 5 notas (también las de cada modo) y el blues.
    String expectedSystem(ScaleDefinition scale) => scale.intervals.length == 5 || scale.id == 'blues_minor'
        ? 'pentatonic_two_notes'
        : scale.intervals.length == 7
        ? 'three_nps'
        : 'caged';

    for (final scale in scales) {
      testWidgets('${scale.id}: vista previa de su sistema predeterminado', (
        tester,
      ) async {
        await pump(tester, scale: scale);
        final preview = board(tester).pattern;
        expect(preview.systemId, expectedSystem(scale));
        expect(
          preview.positionId,
          scale.positions.firstWhere((p) => p.systemId == preview.systemId).id,
        );
      });
    }

    testWidgets('en pantalla ancha el diapasón no pasa de 900 y queda centrado', (
      tester,
    ) async {
      await pump(tester, size: const Size(1400, 900));
      final rect = tester.getRect(find.byType(FretboardDiagram).first);
      expect(rect.width, lessThanOrEqualTo(900));
      expect(rect.center.dx, closeTo(700, 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('filtros en la vista ampliada', () {
    testWidgets('la hoja agrupa por sistema y da el rango de trastes', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      await tester.tap(find.byKey(const Key('neck-pattern')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.scaleWholeNeck), findsOneWidget);
      expect(find.text('CAGED'), findsWidgets);
      final first = stateOf(tester).visiblePatterns.first;
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

    testWidgets('elegir una posición se conserva y se ve al volver al detalle', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      await choose(tester, 3);
      final chosen = stateOf(tester).visiblePatterns[3];
      expect(stateOf(tester).selectedPatternIndex, 3);
      expect(
        find.text(chosen.positionName),
        findsOneWidget,
      );
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(board(tester).pattern, same(chosen));
      expect(
        tester.widget<Text>(find.byKey(const Key('scale-pattern-context'))).data,
        contains(AppStrings.scaleFretRange(chosen.startingFret, chosen.endFret)),
      );
    });

    testWidgets('"Todo el mástil" limpia la selección', (tester) async {
      await pump(tester);
      await expand(tester);
      await choose(tester, 2);
      await tester.tap(find.byKey(const Key('neck-pattern')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pattern-whole-neck')));
      await tester.pumpAndSettle();
      expect(stateOf(tester).selectedPatternIndex, isNull);
    });

    testWidgets('la ✕ limpia la selección', (tester) async {
      await pump(tester);
      await expand(tester);
      await choose(tester, 2);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('neck-pattern')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      expect(stateOf(tester).selectedPatternIndex, isNull);
    });

    testWidgets('cambiar la tónica limpia la selección', (tester) async {
      await pump(tester);
      await expand(tester);
      await choose(tester, 2);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scale-root')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('root-E')));
      await settle(tester);
      expect(stateOf(tester).selectedPatternIndex, isNull);
      expect(stateOf(tester).rootName, 'E');
    });

    testWidgets('elegir un sistema filtra, limpia la selección y cambia la '
        'vista previa', (tester) async {
      await pump(tester);
      await expand(tester);
      await choose(tester, 2);
      await tester.tap(find.byKey(const Key('neck-system')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'CAGED').first);
      await settle(tester);
      final state = stateOf(tester);
      expect(state.selectedPatternIndex, isNull);
      expect(state.visiblePatterns.map((p) => p.systemId).toSet(), {'caged'});
      expect(state.currentPattern!.positionName, 'Forma C');
    });

    for (final language in AppLanguage.values) {
      for (final size in const [Size(744, 308), Size(360, 800)]) {
        testWidgets('${size.width.toInt()}×${size.height.toInt()} '
            '(${language.name}): caben los nombres más largos', (tester) async {
          CurrentLanguage.value = language;
          await pump(
            tester,
            scale: scales.firstWhere((s) => s.id == 'pentatonic_minor'),
          );
          await expand(tester);
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('neck-system')));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ListTile).last);
          await settle(tester);
          await tester.tap(find.byKey(const Key('neck-pattern')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('pattern-0')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final key in const ['neck-system', 'neck-pattern', 'neck-label']) {
            final rect = tester.getRect(find.byKey(Key(key)));
            expect(rect.left, greaterThanOrEqualTo(0), reason: key);
            expect(rect.right, lessThanOrEqualTo(size.width), reason: key);
          }
        });
      }
    }
  });

  group('arpegio de la tónica dentro de la forma', () {
    for (final code in ['es', 'en']) {
      testWidgets('a 360 dp ($code): resalta C E G, «solo el arpegio» deja solo esas notas', (tester) async {
        CurrentLanguage.value = code == 'es' ? AppLanguage.es : AppLanguage.en;
        await pump(tester);
        final chip = find.byKey(const Key('scale-arpeggio'));
        expect(chip, findsOneWidget);
        expect(tester.getRect(chip).right, lessThanOrEqualTo(360));
        expect(find.text(AppStrings.scaleArpeggioOf('C')), findsOneWidget);
        final all = stateOf(tester).currentPattern!.coordinates;
        await tester.tap(chip);
        await tester.pump();
        final board = tester.widget<FretboardDiagram>(find.byKey(const Key('scale-arpeggio-board')));
        // Resaltadas: solo C, E y G; las demás siguen dibujadas, atenuadas.
        int pc(NoteCoordinate c) => (standardOpenStringMidi[c.string - 1] + c.fret) % 12;
        expect(board.highlighted!.map(pc).toSet(), {0, 4, 7});
        expect(board.pattern.coordinates, hasLength(all.length));
        expect(tester.widget<Text>(find.byKey(const Key('scale-arpeggio-hint'))).data, contains('C E G'));
        final only = find.byKey(const Key('scale-arpeggio-only'));
        expect(tester.getRect(only).right, lessThanOrEqualTo(360));
        await tester.tap(only);
        await tester.pump();
        final onlyBoard = tester.widget<FretboardDiagram>(find.byKey(const Key('scale-arpeggio-board')));
        expect(onlyBoard.pattern.coordinates.map(pc).toSet(), {0, 4, 7});
        expect(onlyBoard.highlighted, isNull);
        // Apagar el arpegio vuelve a la forma entera.
        await tester.tap(chip);
        await tester.pump();
        expect(find.byKey(const Key('scale-arpeggio-board')), findsNothing);
        expect(find.byKey(const Key('scale-arpeggio-only')), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
