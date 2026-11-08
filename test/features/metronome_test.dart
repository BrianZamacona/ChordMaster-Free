import 'package:chordmaster_free/app.dart';
import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/features/metronome/metronome_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_store.dart';

/// Registra cada arranque del metrónomo, sin sonar.
class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final starts = <({int bpm, int beats, int perBeat})>[];
  int stops = 0;

  @override
  Future<void> startMetronome({required int bpm, required int beats, int perBeat = 1}) async =>
      starts.add((bpm: bpm, beats: beats, perBeat: perBeat));

  @override
  Future<void> stopMetronome() async => stops++;
}

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  (ProviderContainer, _FakeAudio) setUpVm() {
    final audio = _FakeAudio();
    final container = ProviderContainer(
      overrides: [audioServiceProvider.overrideWithValue(audio)],
    );
    addTearDown(container.dispose);
    return (container, audio);
  }

  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  group('MetronomeViewModel', () {
    test('arrastrar el tempo sonando arranca el sonido una sola vez, al soltar', () async {
      final (container, audio) = setUpVm();
      final vm = container.read(metronomeViewModelProvider.notifier)..startMetronome();
      await wait(10);
      for (var bpm = 100; bpm <= 140; bpm += 4) {
        vm.setBpm(bpm);
      }
      await wait(MetronomeViewModel.restartDelay.inMilliseconds + 100);
      expect(audio.starts.map((s) => s.bpm), [120, 140]);
      vm.stopMetronome();
    });

    test('las corcheas suenan como subdivisión, pero la cuenta sigue en 4 tiempos', () async {
      final (container, audio) = setUpVm();
      final vm = container.read(metronomeViewModelProvider.notifier)
        ..setBpm(300)
        ..setSubdivision('eighth')
        ..startMetronome();
      final beats = <int>[];
      container.listen(
        metronomeViewModelProvider.select((s) => s.currentBeat),
        (_, b) => beats.add(b),
      );
      await wait(1100); // 300 BPM: un tiempo cada 200 ms
      vm.stopMetronome();
      expect(audio.starts.single, (bpm: 300, beats: 4, perBeat: 2));
      expect(beats.length, greaterThanOrEqualTo(2));
      // La cuenta avanza (si un temporizador llega tarde, salta al tiempo que
      // suena: va contra el reloj) y nunca pasa de 3: las corcheas no cuentan.
      expect(beats.every((b) => b < 4), isTrue);
      for (var i = 1; i < beats.length - 1; i++) {
        expect(beats[i], isNot(beats[i - 1]), reason: '$beats');
      }
    });

    test('parar detiene el sonido y vuelve al primer tiempo', () async {
      final (container, audio) = setUpVm();
      final vm = container.read(metronomeViewModelProvider.notifier)..startMetronome();
      await wait(10);
      vm.stopMetronome();
      expect(audio.stops, 1);
      expect(container.read(metronomeViewModelProvider).isPlaying, isFalse);
      expect(container.read(metronomeViewModelProvider).currentBeat, 0);
    });
  });

  for (final code in ['es', 'en']) {
    testWidgets('12/8 cabe a 360 dp ($code)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(
              InMemoryStore(settings: {'localeCode': code}),
            ),
            audioServiceProvider.overrideWithValue(_FakeAudio()),
          ],
          child: const ChordMasterApp(),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      appRouter.go('/tools/metronome');
      await tester.pumpAndSettle();
      await tester.tap(find.text('12/8'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 12; i++) {
        final box = tester.getRect(find.byKey(ValueKey('beat-$i')));
        expect(box.left, greaterThanOrEqualTo(0), reason: 'tiempo $i');
        expect(box.right, lessThanOrEqualTo(360), reason: 'tiempo $i');
      }
    });
  }
}
