import 'dart:io';

import 'package:chordmaster_free/data/repository/scale_repository.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/features/lessons/lesson_widgets.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/theme.dart';
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

  Future<void> pump(WidgetTester tester, UnitArt art) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryStore()),
          scaleRepositoryProvider.overrideWithValue(ScaleRepository(bundle: _FileBundle())),
        ],
        child: MaterialApp(theme: lightTheme, home: Scaffold(body: UnitArtView(art: art))),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('el dibujo de un modo (D dórico) muestra sus notas', (tester) async {
    await pump(tester, const ScaleArt(LessonScale(scaleId: 'dorian', root: 2)));
    for (final n in ['D', 'E', 'F', 'G', 'A', 'B', 'C']) {
      expect(find.text(n), findsWidgets, reason: n);
    }
  });

  testWidgets('el de una escala (A menor pentatónica), las suyas', (tester) async {
    await pump(tester, const ScaleArt(LessonScale(scaleId: 'pentatonic_minor', root: 9)));
    for (final n in ['A', 'C', 'D', 'E', 'G']) {
      expect(find.text(n), findsWidgets, reason: n);
    }
  });
}
