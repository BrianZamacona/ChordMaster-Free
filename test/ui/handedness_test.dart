import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/core/widgets/app_scaffold.dart';
import 'package:chordmaster_free/core/widgets/chord_diagram.dart';
import 'package:chordmaster_free/features/settings/settings_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/handedness.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:chordmaster_free/ui/widgets/fret_grid_geometry.dart';
import 'package:chordmaster_free/ui/widgets/fretboard_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Widget app(Widget child, {required bool leftHanded}) => MaterialApp(
    theme: darkTheme,
    home: Handedness(
      leftHanded: leftHanded,
      child: Scaffold(body: child),
    ),
  );

  bool flipped(WidgetTester tester) => tester
      .widgetList<Transform>(find.byType(Transform))
      .any((t) => t.transform.storage[0] == -1);

  testWidgets('el diagrama de acorde se espeja solo en modo zurdo', (tester) async {
    final diagram = ChordDiagramWidget(
      fretPositions: const [-1, 3, 2, 0, 1, 0],
      fingerPositions: const [0, 3, 2, 0, 1, 0],
      chordName: 'C',
      root: 'C',
    );
    await tester.pumpWidget(app(Center(child: diagram), leftHanded: false));
    expect(flipped(tester), isFalse);
    await tester.pumpWidget(app(Center(child: diagram), leftHanded: true));
    expect(flipped(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('en modo zurdo, tocar el mástil marca el traste que se ve: el 1 y la cuerda al aire, a la derecha', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 400);
    addTearDown(tester.view.reset);
    final taps = <(int, int)>[];
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 220,
          child: FretboardNeck(coordinates: const [], onTapCell: (s, f) => taps.add((s, f))),
        ),
        leftHanded: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(flipped(tester), isTrue);
    final box = tester.getRect(find.byType(FretboardNeck));
    const fretWidth = FretboardNeck.minFretWidth;
    // La 1ª cuerda va arriba en los dos casos; el espejo es de izquierda a derecha.
    final y = box.top + FretGridGeometry.top;
    // La columna de afinación (cuerda al aire) queda pegada al borde derecho…
    await tester.tapAt(Offset(box.right - FretGridGeometry.openNoteX, y));
    // …y el traste 1, justo a su izquierda.
    await tester.tapAt(Offset(box.right - FretGridGeometry.openColumnWidth - fretWidth / 2, y));
    expect(taps, [(1, 0), (1, 1)]);
  });

  test('el ajuste se guarda y se lee al volver a abrir la app', () async {
    final store = InMemoryStore();
    final c = ProviderContainer(overrides: [keyValueStoreProvider.overrideWithValue(store)]);
    addTearDown(c.dispose);
    expect(c.read(settingsViewModelProvider).leftHanded, isFalse);
    await c.read(settingsViewModelProvider.notifier).setLeftHanded(leftHanded: true);
    expect(c.read(settingsViewModelProvider).leftHanded, isTrue);
    expect(await store.get<bool>(StorageBoxes.settings, 'leftHanded'), isTrue);

    final again = ProviderContainer(overrides: [keyValueStoreProvider.overrideWithValue(store)]);
    addTearDown(again.dispose);
    again.read(settingsViewModelProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(again.read(settingsViewModelProvider).leftHanded, isTrue);
  });

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code): el interruptor cabe y cambia el ajuste', (tester) async {
      CurrentLanguage.value = code == 'es' ? AppLanguage.es : AppLanguage.en;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final c = ProviderContainer(overrides: [keyValueStoreProvider.overrideWithValue(InMemoryStore())]);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: darkTheme,
            home: const Scaffold(body: SingleChildScrollView(child: SettingsPanel())),
          ),
        ),
      );
      await tester.pump();
      final toggle = find.byKey(const Key('settings-left-handed'));
      expect(toggle, findsOneWidget);
      expect(tester.getRect(toggle).right, lessThanOrEqualTo(360));
      expect(find.text(AppStrings.leftHanded), findsOneWidget);
      await tester.tap(toggle);
      await tester.pump();
      expect(c.read(settingsViewModelProvider).leftHanded, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
