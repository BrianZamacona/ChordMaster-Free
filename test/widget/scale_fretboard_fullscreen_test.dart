import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/models/note_coordinate.dart';
import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/theory/neck_notes.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_notifier.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_screen.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_fretboard_fullscreen.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:chordmaster_free/ui/widgets/fret_grid_geometry.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
import 'package:flutter/foundation.dart';
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

const _landscape = ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight'];

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
  final args = (scale: major, root: 0, position: null);

  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  /// Registra cada lista de orientaciones pedida al sistema.
  List<List<dynamic>> recordOrientations(WidgetTester tester) {
    final requests = <List<dynamic>>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        requests.add(call.arguments as List<dynamic>);
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    return requests;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(360, 800),
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
          home: ScaleDetailScreen(scale: major),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> expand(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('scale-expand')));
    await tester.pumpAndSettle();
  }

  ScaleDetailState stateOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(ScaleDetailScreen, skipOffstage: false)),
  ).read(scaleDetailProvider(args));

  FretboardNeck neck(WidgetTester tester) =>
      tester.widget<FretboardNeck>(find.byType(FretboardNeck));

  Future<void> chooseInNeck(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(const Key('neck-pattern')));
    await tester.pumpAndSettle();
    final row = find.byKey(Key('pattern-$index'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  group('orientación', () {
    test('solo Android e iOS, y nunca en web', () {
      for (final platform in TargetPlatform.values) {
        expect(
          forcesLandscape(platform: platform, isWeb: false),
          platform == TargetPlatform.android || platform == TargetPlatform.iOS,
          reason: platform.name,
        );
        expect(forcesLandscape(platform: platform, isWeb: true), isFalse);
      }
    });

    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets('${platform.name}: pide horizontal y lo devuelve al salir', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final requests = recordOrientations(tester);
        await pump(tester);
        expect(requests, isEmpty);
        await expand(tester);
        expect(requests, [_landscape]);
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        expect(requests, [_landscape, <String>[]]);
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('android: el botón atrás también lo devuelve', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final requests = recordOrientations(tester);
      await pump(tester);
      await expand(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FretboardNeck), findsNothing);
      expect(requests.last, isEmpty);
      debugDefaultTargetPlatformOverride = null;
    });

    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      testWidgets('${platform.name}: no pide orientación; ✕ y Esc cierran', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final requests = recordOrientations(tester);
        await pump(tester, size: const Size(1280, 800));
        await expand(tester);
        expect(find.byType(FretboardNeck), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(FretboardNeck), findsNothing);
        await expand(tester);
        await tester.tap(find.byType(CloseButton));
        await tester.pumpAndSettle();
        expect(find.byType(FretboardNeck), findsNothing);
        expect(requests, isEmpty);
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });

  group('vista ampliada', () {
    testWidgets('el botón está en el detalle, con su descripción', (
      tester,
    ) async {
      await pump(tester);
      final button = tester.widget<IconButton>(
        find.byKey(const Key('scale-expand')),
      );
      expect((button.icon as Icon).icon, Icons.fullscreen);
      expect(button.tooltip, 'Ampliar diapasón');
    });

    testWidgets('sin digitación: toda la escala, sin nada atenuado', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      final widget = neck(tester);
      expect(widget.highlighted, isNull);
      expect(widget.focus, isNull);
      // 15 notas por cuerda en C mayor, más que cualquier posición.
      expect(widget.coordinates, hasLength(90));
      final first = stateOf(tester).visiblePatterns.first.coordinates.toSet();
      expect(widget.coordinates.toSet().difference(first), isNotEmpty);
    });

    testWidgets('con digitación: se resalta justo esa y se centra', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      await chooseInNeck(tester, 4);
      await tester.pumpAndSettle();
      final state = stateOf(tester);
      final chosen = state.visiblePatterns[4];
      final widget = neck(tester);
      expect(widget.highlighted, patternAcrossNeck(chosen.coordinates).toSet());
      expect(widget.highlighted!.containsAll(chosen.coordinates), isTrue);
      expect(widget.focus, (start: chosen.startingFret, end: chosen.endFret));
      // La digitación es parte de la escala, y el resto queda atenuado.
      expect(widget.coordinates.toSet().containsAll(widget.highlighted!), isTrue);
      expect(widget.coordinates.length, greaterThan(widget.highlighted!.length));
    });

    testWidgets('C mayor, Posición 3 de 3NPS: también se marca en el traste 12', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      final positions = stateOf(tester).visiblePatterns;
      final index = positions.indexWhere(
        (p) => p.positionId == 'nps_3',
      );
      expect(positions[index].startingFret, 0);
      await chooseInNeck(tester, index);
      final highlighted = neck(tester).highlighted!;
      for (final c in positions[index].coordinates) {
        final copy = highlighted.lookup(
          NoteCoordinate(string: c.string, fret: c.fret + 12, isRoot: c.isRoot),
        );
        expect(copy, isNotNull, reason: 'cuerda ${c.string}, traste ${c.fret}');
        expect(copy!.note, c.note);
        expect(copy.interval, c.interval);
      }
      expect(highlighted, hasLength(positions[index].coordinates.length * 2));
      expect(neck(tester).coordinates.toSet().containsAll(highlighted), isTrue);
    });

    testWidgets('limpiar vuelve a todo el mástil', (tester) async {
      await pump(tester);
      await expand(tester);
      await chooseInNeck(tester, 4);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('neck-pattern')),
          matching: find.byIcon(Icons.close),
        ),
      );
      await tester.pumpAndSettle();
      expect(neck(tester).highlighted, isNull);
    });

    testWidgets('al cerrar, el detalle conserva la misma selección', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      await chooseInNeck(tester, 5);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(stateOf(tester).selectedPatternIndex, 5);
      expect(
        tester.widget<FretboardDiagram>(find.byType(FretboardDiagram).first).pattern,
        same(stateOf(tester).visiblePatterns[5]),
      );
    });

    testWidgets('el botón de etiquetas cambia entre intervalo y nota', (
      tester,
    ) async {
      await pump(tester);
      await expand(tester);
      expect(neck(tester).label, FretboardLabel.interval);
      await tester.tap(find.text('Notas'));
      await tester.pumpAndSettle();
      expect(neck(tester).label, FretboardLabel.note);
    });

    testWidgets('el mástil tiene sitio para los 24 trastes y hace scroll', (
      tester,
    ) async {
      await pump(tester, size: const Size(800, 360));
      await expand(tester);
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('neck-scroll')),
      );
      expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));
      const g = FretGridGeometry(
        width: 800,
        height: 240,
        startFret: 1,
        endFret: 24,
        fixedFretWidth: FretboardNeck.minFretWidth,
      );
      expect(scroll.controller!.position.maxScrollExtent, g.boardWidth - 800);
    });

    for (final language in AppLanguage.values) {
      for (final size in const [Size(800, 360), Size(360, 800)]) {
        testWidgets('${size.width.toInt()}×${size.height.toInt()} '
            '(${language.name}): nada se desborda', (tester) async {
          CurrentLanguage.value = language;
          await pump(tester, size: size);
          await expand(tester);
          expect(tester.takeException(), isNull);
          await chooseInNeck(tester, 4);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('centrado', () {
    const g = FretGridGeometry(
      width: 800,
      height: 240,
      startFret: 1,
      endFret: 24,
      fixedFretWidth: 52,
    );

    test('una posición baja no se pasa del inicio', () {
      expect(g.scrollToCenter(0, 4, 800), 0);
    });

    test('una posición alta no se pasa del final', () {
      expect(g.scrollToCenter(20, 24, 800), g.boardWidth - 800);
    });

    test('una posición media queda en el centro de lo visible', () {
      final scroll = g.scrollToCenter(12, 16, 800);
      final left = g.fretLineX(11) - scroll;
      final right = g.fretLineX(16) - scroll;
      expect(left - g.nutX, closeTo(800 - right, 1e-9));
    });
  });
}
