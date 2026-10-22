import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/core/i18n/app_i18n.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/features/settings/settings_viewmodel.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

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
      overrides: [keyValueStoreProvider.overrideWithValue(InMemoryStore())],
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
