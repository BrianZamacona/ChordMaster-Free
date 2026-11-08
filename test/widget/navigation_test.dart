import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/features/chords/chord_library_screen.dart';
import 'package:chordmaster_free/features/home/home_screen.dart';
import 'package:chordmaster_free/features/hubs/hubs.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:chordmaster_free/ui/section_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  group('redirectLegacyRoute', () {
    test('rutas viejas a su sección', () {
      expect(redirectLegacyRoute('/tuner'), '/tools/tuner');
      expect(redirectLegacyRoute('/rhythm-game'), '/practice/rhythm');
      expect(redirectLegacyRoute('/community'), '/progress');
      expect(redirectLegacyRoute('/composition'), '/learn/progressions');
      expect(redirectLegacyRoute('/learn/composition'), '/learn/progressions');
      expect(redirectLegacyRoute('/improvisation'), '/learn/scales');
      expect(redirectLegacyRoute('/practice/improvisation'), '/learn/scales');
    });

    test('rutas actuales y prefijos parecidos no se tocan', () {
      expect(redirectLegacyRoute('/learn/chords'), isNull);
      // /chords, /scales y /progressions ya no son viejas: son los módulos en Inicio.
      expect(redirectLegacyRoute('/chords'), isNull);
      expect(redirectLegacyRoute('/scales/double-stops'), isNull);
      expect(redirectLegacyRoute('/progressions'), isNull);
      expect(redirectLegacyRoute('/'), isNull);
    });
  });

  Future<void> open(WidgetTester tester, String location) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(InMemoryStore())],
        child: const ChordMasterApp(),
      ),
    );
    appRouter.go(location);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  for (final (location, back) in [
    ('/learn', false),
    ('/learn/chords', true),
    ('/learn/lessons', true),
    ('/learn/lessons/f1_meet_guitar', true),
    ('/learn/lessons/unit/f_first_steps', true),
    ('/learn/scales/double-stops', true),
    ('/learn/progressions', true),
    ('/practice/ear-training', true),
    ('/tools/metronome', false),
    ('/progress/achievements', true),
  ]) {
    testWidgets('$location: barra inferior${back ? ' y botón de atrás' : ''}', (
      tester,
    ) async {
      await open(tester, location);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BackButton), back ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('/chords abre Acordes dentro de Inicio', (tester) async {
    await open(tester, '/chords');
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
    expect(find.byType(BackButton), findsOneWidget);
  });

  for (final (label, route, module) in [
    ('Acordes', '/chords', 'chords'),
    ('Escalas', '/scales', 'scales'),
    ('Progresiones', '/progressions', 'progressions'),
    ('Círculo de quintas', '/circle', 'circle'),
  ]) {
    testWidgets('$label desde Inicio: atrás vuelve a Inicio', (tester) async {
      await open(tester, '/');
      appRouter.go(route);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/');
      // En Aprender, el mismo módulo vuelve a Aprender.
      appRouter.go('/learn/$module');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 1);
    });
  }

  testWidgets('tocar Aprender desde otra pestaña abre el inicio de Aprender', (tester) async {
    await open(tester, '/learn/chords');
    expect(find.byType(LearnHubScreen), findsNothing);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LearnHubScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('los enlaces internos de un módulo se quedan en su pestaña', (tester) async {
    await open(tester, '/chords');
    var context = tester.element(find.byType(ChordLibraryScreen));
    expect(context.sectionPath('chords/C%20Major'), '/chords/C%20Major');
    appRouter.go('/learn/chords');
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    context = tester.element(find.byType(ChordLibraryScreen));
    expect(context.sectionPath('chords/C%20Major'), '/learn/chords/C%20Major');
  });
}
