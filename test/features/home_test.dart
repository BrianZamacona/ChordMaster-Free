import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/constants/app_strings.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

void main() {
  List<String> labels() => [
        AppStrings.moduleChords,
        AppStrings.moduleScales,
        AppStrings.moduleTuner,
        AppStrings.moduleMetronome,
        AppStrings.moduleProgressions,
        AppStrings.moduleEarTraining,
        AppStrings.moduleRhythmGame,
        AppStrings.moduleSongs,
        AppStrings.moduleHealth,
      ];

  for (final code in ['es', 'en']) {
    for (final width in [320.0, 360.0]) {
      testWidgets('ningún módulo parte una palabra ($code, $width dp)', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1600);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              keyValueStoreProvider.overrideWithValue(
                InMemoryStore(settings: {'localeCode': code}),
              ),
            ],
            child: const ChordMasterApp(),
          ),
        );
        appRouter.go('/');
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }

        for (final label in labels()) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label).last,
          );
          var start = 0;
          for (final word in label.split(' ')) {
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: start, extentOffset: start + word.length),
            );
            expect(boxes, hasLength(1), reason: '"$word" en "$label" se parte');
            start += word.length + 1;
          }
        }
      });
    }
  }
}
