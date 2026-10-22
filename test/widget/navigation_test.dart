import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/services/storage_service.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements StorageService {
  @override
  Future<void> openBoxes() async {}
  @override
  Future<void> save(String box, String key, dynamic value) async {}
  @override
  Future<T?> get<T>(String box, String key) async => null;
  @override
  Future<void> delete(String box, String key) async {}
  @override
  Future<void> clear(String box) async {}
}

void main() {
  group('redirectLegacyRoute', () {
    test('rutas viejas a su sección', () {
      expect(redirectLegacyRoute('/chords'), '/learn/chords');
      expect(
        redirectLegacyRoute('/chords/C%20Major/compare?sel=caged:0,caged:1'),
        '/learn/chords/C%20Major/compare?sel=caged:0,caged:1',
      );
      expect(redirectLegacyRoute('/scales/double-stops'), '/learn/scales/double-stops');
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
      expect(redirectLegacyRoute('/'), isNull);
      expect(redirectLegacyRoute('/chordsx'), isNull);
    });
  });

  Future<void> open(WidgetTester tester, String location) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWithValue(_FakeStorage())],
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

  testWidgets('la ruta vieja /chords abre Acordes dentro de Aprender', (tester) async {
    await open(tester, '/chords');
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
