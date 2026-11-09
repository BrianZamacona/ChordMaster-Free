import 'dart:io';

import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/guides/guide_progress.dart';
import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/domain/guides/style_guides.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/features/capo/capo_screen.dart';
import 'package:chordmaster_free/features/guides/guide_detail_screen.dart';
import 'package:chordmaster_free/features/guides/guides_viewmodel.dart';
import 'package:chordmaster_free/features/lessons/lesson_detail_screen.dart';
import 'package:chordmaster_free/features/lessons/lessons_viewmodel.dart';
import 'package:chordmaster_free/features/licks/lick_detail_screen.dart';
import 'package:chordmaster_free/features/workouts/workouts_screen.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

/// Lee los assets del disco: `rootBundle` ataría la lectura al primer test.
class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async => File(key).readAsStringSync();
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<InMemoryStore> open(
    WidgetTester tester,
    String location, {
    String code = 'es',
    Size size = const Size(500, 2400),
    Map<String, Object?>? progress,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final store = InMemoryStore(
      settings: {'localeCode': code},
      progress: progress,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
        ],
        child: const ChordMasterApp(),
      ),
    );
    // chords.json se decodifica en otro isolate: hace falta tiempo real.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    appRouter.go(location);
    await settle(tester);
    return store;
  }

  group('catálogo', () {
    testWidgets('Aprender enlaza Guías y el capo', (tester) async {
      await open(tester, '/learn');
      expect(find.text(AppStrings.hubGuides), findsOneWidget);
      expect(find.text(AppStrings.hubCapo), findsOneWidget);
    });

    testWidgets('una fila por categoría con todas sus guías', (tester) async {
      await open(tester, '/learn/guides', size: const Size(500, 9000));
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

    testWidgets('el filtro de nivel deja solo ese nivel; "Todos" vuelve', (tester) async {
      await open(tester, '/learn/guides');
      await tester.tap(find.byKey(const Key('guides-level-advanced')));
      await tester.pump();
      for (final g in guides) {
        expect(
          find.byKey(Key('guide-${g.id}'), skipOffstage: false),
          g.level == GuideLevel.advanced ? findsOneWidget : findsNothing,
          reason: g.id,
        );
      }
      await tester.tap(find.byKey(const Key('guides-level-all')));
      await tester.pump();
      expect(find.byKey(const Key('guide-capo'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('el filtro de nivel se combina con la búsqueda', (tester) async {
      await open(tester, '/learn/guides');
      await tester.enterText(find.byKey(const Key('guides-search')), 'caged');
      await tester.tap(find.byKey(const Key('guides-level-beginner')));
      await tester.pump();
      expect(find.byKey(const Key('guides-empty')), findsOneWidget);
      await tester.tap(find.byKey(const Key('guides-level-intermediate')));
      await tester.pump();
      expect(find.byKey(const Key('guide-caged_chord_scale')), findsOneWidget);
    });

    testWidgets('cada tarjeta dice su nivel', (tester) async {
      await open(tester, '/learn/guides', size: const Size(500, 9000));
      for (final g in guides) {
        final level = tester.widget<Text>(find.byKey(Key('guide-level-${g.id}'), skipOffstage: false));
        expect(level.data, guideLevelTitle(g.level).text, reason: g.id);
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
      // El nombre del módulo es una pregunta: el botón no lo repite.
      expect(find.text(AppStrings.guideOpenCapo), findsWidgets);
      expect(
        find.textContaining(AppStrings.guideOpenModuleNamed(AppStrings.hubCapo)),
        findsNothing,
      );
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

    testWidgets('una guía de estilo abre su lick y atrás vuelve a la guía', (tester) async {
      final id = styleGuideId(LickStyle.latinRock);
      await open(tester, '/learn/guides/$id');
      expect(find.text(AppStrings.guideOpenLick(guidesById[id]!.chapters[1].title.text.split(': ').last)), findsOneWidget);
      final button = find.byKey(const Key('guide-open-1'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle(tester);
      expect(find.byType(LickDetailScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(GuideDetailScreen), findsOneWidget);
    });

    testWidgets('una guía que no existe muestra un aviso', (tester) async {
      await open(tester, '/learn/guides/no_existe');
      expect(find.text(AppStrings.guideNotFound), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('progreso', () {
    final guide = guidesById['chord_variations']!;
    final lessonIndex = guide.chapters.indexWhere((c) => c.target is LessonLink);
    final otherIndex = guide.chapters.indexWhere((c) => c.target is! LessonLink);
    final lessonId = (guide.chapters[lessonIndex].target as LessonLink).lessonId;

    testWidgets('muestra capítulos, minutos y cuánto llevas', (tester) async {
      await open(tester, '/learn/guides/chord_variations');
      expect(
        find.text(
          '${AppStrings.guideChapters(guide.chapters.length)} · '
          '${AppStrings.guideMinutes(guideMinutes(guide))}',
        ),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.guideDoneCount(0, guide.chapters.length)),
        findsOneWidget,
      );
      // Sin empezar no se señala ningún capítulo.
      expect(find.text(AppStrings.guideContinueHere), findsNothing);
    });

    testWidgets('marcar un capítulo se guarda y señala el siguiente', (tester) async {
      final store = await open(tester, '/learn/guides/chord_variations');
      final check = find.byKey(Key('guide-check-$otherIndex'));
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();
      expect(
        find.text(AppStrings.guideDoneCount(1, guide.chapters.length)),
        findsOneWidget,
      );
      expect(
        store.progress[GuideChecksViewModel.keyChecked],
        [chapterKey(guide, otherIndex)],
      );
      final next = otherIndex == 0 ? 1 : 0;
      expect(find.byKey(Key('guide-next-chapter-$next')), findsOneWidget);
      await tester.tap(check);
      await tester.pump();
      expect(
        find.text(AppStrings.guideDoneCount(0, guide.chapters.length)),
        findsOneWidget,
      );
    });

    testWidgets('el capítulo de una lección marca la lección', (tester) async {
      final store = await open(tester, '/learn/guides/chord_variations');
      final check = find.byKey(Key('guide-check-$lessonIndex'));
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await tester.pump();
      expect(store.progress[LessonsViewModel.keyCompleted], [lessonId]);
      expect(store.progress[GuideChecksViewModel.keyChecked], isNull);
    });

    testWidgets('una lección terminada cuenta en la guía', (tester) async {
      await open(
        tester,
        '/learn/guides/chord_variations',
        progress: {
          LessonsViewModel.keyCompleted: [lessonId],
        },
      );
      expect(
        find.text(AppStrings.guideDoneCount(1, guide.chapters.length)),
        findsOneWidget,
      );
    });

    testWidgets('todo hecho: guía terminada', (tester) async {
      await open(
        tester,
        '/learn/guides/chord_variations',
        progress: {
          LessonsViewModel.keyCompleted: [
            for (final c in guide.chapters)
              if (c.target case LessonLink(:final lessonId)) lessonId,
          ],
          GuideChecksViewModel.keyChecked: [
            for (var i = 0; i < guide.chapters.length; i++) chapterKey(guide, i),
          ],
        },
      );
      expect(find.byKey(const Key('guide-finished')), findsOneWidget);
    });

    testWidgets('"Siguiente guía" reemplaza a esta y atrás vuelve al catálogo', (
      tester,
    ) async {
      await open(tester, '/learn/guides');
      await tester.tap(find.byKey(const Key('guide-chord_variations')));
      await settle(tester);
      final next = const GuideProgress().nextGuide(guide)!;
      final card = find.byKey(const Key('guide-next'));
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(card);
      await settle(tester);
      expect(
        tester.widget<Text>(find.byKey(const Key('guide-title'))).data,
        next.title.text,
      );
      appRouter.pop();
      await settle(tester);
      expect(find.byKey(const Key('guides-search')), findsOneWidget);
    });

    testWidgets('el catálogo pone arriba las guías empezadas', (tester) async {
      await open(
        tester,
        '/learn/guides',
        progress: {
          GuideChecksViewModel.keyChecked: [chapterKey(guide, otherIndex)],
        },
      );
      final row = find.byKey(const Key('guides-row-in-progress'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.byKey(Key('guide-${guide.id}'))),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('guide-card-progress-${guide.id}')),
        findsNWidgets(2),
      );
      // Al buscar, la fila desaparece.
      await tester.enterText(find.byKey(const Key('guides-search')), 'blues');
      await tester.pump();
      expect(row, findsNothing);
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
      expect(
        find.descendant(
          of: find.byKey(const Key('capo-option-G')),
          matching: find.text(AppStrings.capoAt(2, 'G')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cambiar a menor usa las formas Am, Em y Dm', (tester) async {
      await open(tester, '/learn/capo');
      await tester.tap(find.text(AppStrings.capoMinor));
      await tester.pump();
      expect(find.byKey(const Key('capo-option-Am'), skipOffstage: false), findsOneWidget);
      expect(find.byKey(const Key('capo-option-A'), skipOffstage: false), findsNothing);
    });

    testWidgets('girar una progresión: en A, la forma de G en el 2 toca G D Em C', (
      tester,
    ) async {
      await open(tester, '/learn/capo');
      final picker = find.byKey(const Key('capo-progression'));
      await tester.ensureVisible(picker);
      await tester.pump();
      await tester.tap(picker);
      await settle(tester);
      await tester.tap(find.byKey(const Key('capo-progression-v1-2')));
      await settle(tester);
      String text(String key) => tester.widget<Text>(find.byKey(Key(key))).data!;
      expect(
        text('capo-turn-target'),
        AppStrings.capoTurnInKey('A', 'A – E – F#m – D'),
      );
      expect(text('capo-turn-G'), 'G – D – Em – C');
    });

    testWidgets('en menor no se ofrece girar (las progresiones son mayores)', (
      tester,
    ) async {
      await open(tester, '/learn/capo');
      expect(find.byKey(const Key('capo-turn'), skipOffstage: false), findsOneWidget);
      await tester.tap(find.text(AppStrings.capoMinor));
      await tester.pump();
      expect(find.byKey(const Key('capo-turn'), skipOffstage: false), findsNothing);
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
        // Con una guía empezada: aparece su fila y la barra en la tarjeta.
        final first = guides.first;
        await open(
          tester,
          '/learn/guides',
          code: code,
          size: const Size(360, 3200),
          progress: {
            GuideChecksViewModel.keyChecked: [
              for (var i = 0; i < first.chapters.length; i++)
                if (first.chapters[i].target is! LessonLink) chapterKey(first, i),
            ],
          },
        );
        expect(tester.takeException(), isNull);
        // En lista: cada guía ocupa todo el ancho, una debajo de otra (la
        // primera está empezada y sale también arriba).
        final row = guidesIn(GuideCategory.acoustic);
        final firstRect = tester.getRect(find.byKey(Key('guide-${row[1].id}')));
        final secondRect = tester.getRect(find.byKey(Key('guide-${row[2].id}')));
        expect(firstRect.width, 328);
        expect(secondRect.top, greaterThan(firstRect.bottom));
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

  for (final code in ['es', 'en']) {
    testWidgets('a 360 dp ($code) el filtro de nivel cabe', (tester) async {
      await open(tester, '/learn/guides', code: code, size: const Size(360, 3200));
      expect(tester.takeException(), isNull);
      for (final key in ['guides-levels', 'guides-level-intermediate', 'guides-level-advanced']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0), reason: key);
        expect(rect.right, lessThanOrEqualTo(360), reason: key);
      }
    });
  }
}