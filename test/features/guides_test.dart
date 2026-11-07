import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/features/capo/capo_screen.dart';
import 'package:chordmaster_free/features/guides/guide_detail_screen.dart';
import 'package:chordmaster_free/features/lessons/lesson_detail_screen.dart';
import 'package:chordmaster_free/features/workouts/workouts_screen.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 2400),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(settings: {'localeCode': code});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: const ChordMasterApp(),
      ),
    );
    // chords.json se decodifica en otro isolate: hace falta tiempo real.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
  }

  group('catálogo', () {
    testWidgets('Aprender enlaza Guías y el capo', (tester) async {
      await open(tester, '/learn');
      expect(find.text(AppStrings.hubGuides), findsOneWidget);
      expect(find.text(AppStrings.hubCapo), findsOneWidget);
    });

    testWidgets('una fila por categoría con todas sus guías', (tester) async {
      await open(tester, '/learn/guides');
      for (final c in GuideCategory.values) {
        expect(
          find.byKey(Key('guides-category-${c.name}'), skipOffstage: false),
          findsOneWidget,
        );
        for (final g in guidesIn(c)) {
          expect(
            find.byKey(Key('guide-${g.id}'), skipOffstage: false),
            findsOneWidget,
            reason: g.id,
          );
        }
      }
    });

    testWidgets('buscar filtra y oculta las filas vacías; la ✕ limpia', (tester) async {
      await open(tester, '/learn/guides');
      await tester.enterText(find.byKey(const Key('guides-search')), 'capo');
      await tester.pump();
      expect(find.byKey(const Key('guide-capo')), findsOneWidget);
      expect(find.byKey(const Key('guides-category-genres')), findsNothing);
      await tester.tap(find.byKey(const Key('guides-search-clear')));
      await tester.pump();
      expect(find.byKey(const Key('guides-category-genres'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('sin resultados muestra un aviso', (tester) async {
      await open(tester, '/learn/guides');
      await tester.enterText(find.byKey(const Key('guides-search')), 'zzzz');
      await tester.pump();
      expect(find.byKey(const Key('guides-empty')), findsOneWidget);
    });
  });

  group('detalle', () {
    testWidgets('tocar una guía abre sus capítulos', (tester) async {
      await open(tester, '/learn/guides');
      await tester.tap(find.byKey(const Key('guide-chord_variations')));
      await settle(tester);
      expect(find.byType(GuideDetailScreen), findsOneWidget);
      final guide = guidesById['chord_variations']!;
      for (var i = 0; i < guide.chapters.length; i++) {
        expect(find.byKey(Key('guide-chapter-$i'), skipOffstage: false), findsOneWidget);
      }
    });

    testWidgets('un capítulo de lección abre la lección y atrás vuelve', (tester) async {
      await open(tester, '/learn/guides/chord_variations');
      await tester.tap(find.byKey(const Key('guide-open-0')));
      await settle(tester);
      expect(find.byType(LessonDetailScreen), findsOneWidget);
      expect(appRouter.canPop(), isTrue);
      appRouter.pop();
      await settle(tester);
      expect(find.byType(GuideDetailScreen), findsOneWidget);
    });

    testWidgets('el capítulo del capo abre la calculadora', (tester) async {
      await open(tester, '/learn/guides/capo');
      await tester.tap(find.byKey(const Key('guide-open-0')));
      await settle(tester);
      expect(find.byType(CapoScreen), findsOneWidget);
    });

    testWidgets('el capítulo de rutinas abre las de su escala', (tester) async {
      await open(tester, '/learn/guides/minor_pentatonic');
      final guide = guidesById['minor_pentatonic']!;
      final index = guide.chapters.indexWhere((c) => c.target is WorkoutLink);
      expect(index, isNonNegative);
      final button = find.byKey(Key('guide-open-$index'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle(tester);
      expect(find.byType(WorkoutsScreen), findsOneWidget);
    });

    testWidgets('una guía que no existe muestra un aviso', (tester) async {
      await open(tester, '/learn/guides/no_existe');
      expect(find.text(AppStrings.guideNotFound), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('capo', () {
    testWidgets('A mayor: A sin capo, G en el 2, E en el 5 y D en el 7', (tester) async {
      await open(tester, '/learn/capo');
      for (final shape in ['A', 'G', 'E', 'D']) {
        expect(find.byKey(Key('capo-option-$shape'), skipOffstage: false), findsOneWidget);
      }
      // C quedaría en el traste 9: no se muestra.
      expect(find.byKey(const Key('capo-option-C'), skipOffstage: false), findsNothing);
      expect(find.text(AppStrings.capoAt(2, 'G')), findsOneWidget);
    });

    testWidgets('cambiar a menor usa las formas Am, Em y Dm', (tester) async {
      await open(tester, '/learn/capo');
      await tester.tap(find.text(AppStrings.capoMinor));
      await tester.pump();
      expect(find.byKey(const Key('capo-option-Am'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const Key('capo-option-A'), skipOffstage: false), findsNothing);
    });

    testWidgets('cambiar la tonalidad recalcula', (tester) async {
      await open(tester, '/learn/capo');
      await tester.tap(find.byKey(const Key('capo-key')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('root-E')));
      await settle(tester);
      expect(find.text(AppStrings.capoResults('E')), findsOneWidget);
      expect(find.byKey(const Key('capo-option-C'), skipOffstage: false), findsOneWidget);
    });
  });

  // Un desborde hace fallar estos tests.
  for (final code in ['es', 'en']) {
    group('a 360 dp ($code)', () {
      testWidgets('catálogo y cada guía sin desbordes', (tester) async {
        await open(tester, '/learn/guides', code: code, size: const Size(360, 3200));
        expect(tester.takeException(), isNull);
        // Dos tarjetas enteras y un trozo de la tercera a la vista.
        final row = guidesIn(GuideCategory.acoustic);
        final third = tester.getRect(find.byKey(Key('guide-${row[2].id}')));
        expect(third.left, lessThan(360));
        expect(third.right, greaterThan(360));
        for (final g in guides) {
          appRouter.go('/learn/guides/${g.id}');
          await settle(tester);
          expect(tester.takeException(), isNull, reason: g.id);
        }
      });

      testWidgets('el capo cabe en todas las tonalidades', (tester) async {
        await open(tester, '/learn/capo', code: code, size: const Size(360, 3200));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(AppStrings.capoMinor));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });
  }
}
