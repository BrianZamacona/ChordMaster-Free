import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/app_i18n.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/features/settings/settings_viewmodel.dart';
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
  Future<List<dynamic>> getAll(String box) async => <dynamic>[];
  @override
  Future<void> delete(String box, String key) async {}
  @override
  Future<void> clear(String box) async {}
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  test('tr devuelve la versión del idioma actual', () {
    CurrentLanguage.value = AppLanguage.es;
    expect(tr(es: 'Acordes', en: 'Chords'), 'Acordes');
    CurrentLanguage.value = AppLanguage.en;
    expect(tr(es: 'Acordes', en: 'Chords'), 'Chords');
    expect(const LocalizedText(es: 'a', en: 'b').text, 'b');
  });

  test('idioma inicial: inglés solo si el teléfono está en inglés', () {
    expect(AppI18n.defaultLocaleCode(const Locale('en', 'US')), 'en');
    expect(AppI18n.defaultLocaleCode(const Locale('es', 'MX')), 'es');
    expect(AppI18n.defaultLocaleCode(const Locale('pt')), 'es');
    expect(AppI18n.normalize('de'), 'es');
    expect(AppI18n.normalize('en'), 'en');
  });

  testWidgets('cambiar el idioma reescribe la barra sin perder la ruta', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [storageServiceProvider.overrideWithValue(_FakeStorage())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ChordMasterApp(),
      ),
    );
    await container
        .read(settingsViewModelProvider.notifier)
        .setLocaleCode('es');
    appRouter.go('/learn');
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Aprender'), findsWidgets);

    await container
        .read(settingsViewModelProvider.notifier)
        .setLocaleCode('en');
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Aprender'), findsNothing);
    expect(find.text(AppStrings.hubChords), findsOneWidget);
    expect(AppStrings.hubChords, 'Chords');
    expect(
      appRouter.routerDelegate.currentConfiguration.uri.path,
      '/learn',
    );
  });
}
