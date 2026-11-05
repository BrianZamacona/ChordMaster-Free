import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/data/models/scale_definition.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/scales/detail/scale_detail_screen.dart';
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
  final data =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync())
          as Map<String, dynamic>;
  final scales = [
    for (final g in ['scales', 'modes'])
      for (final s in (data[g] as List<dynamic>))
        ScaleDefinition.fromJson(s as Map<String, dynamic>),
  ];

  Future<void> pump(WidgetTester tester, ScaleDefinition scale) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryStore()),
          scaleRepositoryProvider.overrideWithValue(
            ScaleRepository(bundle: _FileBundle()),
          ),
        ],
        child: MaterialApp(home: ScaleDetailScreen(scale: scale)),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Los sistemas se eligen en la vista ampliada, en la hoja del botón Sistema.
  Future<void> openSystems(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('scale-expand')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('neck-system')));
    await tester.pumpAndSettle();
  }

  for (final id in ['pentatonic_minor', 'pentatonic_major', 'blues_minor']) {
    testWidgets('$id: ofrece Caja pentatónica (2NPS), sin Linear', (tester) async {
      await pump(tester, scales.firstWhere((s) => s.id == id));
      await openSystems(tester);
      expect(find.widgetWithText(ListTile, 'Caja pentatónica (2NPS)'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Lineal (4NPS)'), findsNothing);
    });
  }

  for (final scale in scales.where((s) => s.intervals.length == 7)) {
    testWidgets('${scale.id}: ofrece Lineal (4NPS)', (tester) async {
      await pump(tester, scale);
      await openSystems(tester);
      expect(find.widgetWithText(ListTile, 'Lineal (4NPS)'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Caja pentatónica (2NPS)'), findsNothing);
    });
  }

  // Cada posición aparece una vez, completa (nunca recortada) y de la escala.
  const openHighToLow = [4, 11, 7, 2, 9, 4];
  for (final root in [0, 4, 9, 11]) {
    test('raíz $root: todos los sistemas, instancias completas y de la escala',
        () async {
      final repo = ScaleRepository(bundle: _FileBundle());
      for (final scale in scales) {
        final allowed = {for (final i in scale.intervals) (root + i) % 12};
        for (final sys in scale.systems) {
          final sizes = {
            for (final p in scale.positions)
              if (p.systemId == sys.id) p.id: p.coordinates.length,
          };
          final patterns = await repo.getPositions(
            scaleId: scale.id,
            rootSemitone: root,
            systemFilter: sys.id,
          );
          expect(patterns, hasLength(sizes.length), reason: '${scale.id}/${sys.id}');
          final seen = <String>{};
          for (final pat in patterns) {
            seen.add(pat.positionId);
            final label = '${scale.id}/${sys.id}/${pat.positionId}';
            expect(pat.coordinates, hasLength(sizes[pat.positionId]),
                reason: label);
            for (final c in pat.coordinates) {
              final pc = (openHighToLow[c.string - 1] + c.fret) % 12;
              expect(allowed, contains(pc), reason: label);
            }
          }
          expect(seen, sizes.keys.toSet(), reason: '${scale.id}/${sys.id}');
        }
      }
    });
  }
}
