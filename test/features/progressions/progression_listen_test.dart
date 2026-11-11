import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/domain/progressions/progression_playback.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/chord_data.dart';
import '../../support/in_memory_store.dart';

class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <({List<StringSound> sounds, double seconds, bool loop})>[];
  int stops = 0;

  @override
  Future<void> playTab(List<StringSound> sounds, {required double seconds}) async =>
      played.add((sounds: sounds, seconds: seconds, loop: false));

  @override
  Future<void> loopTab(List<StringSound> sounds, {required double seconds}) async =>
      played.add((sounds: sounds, seconds: seconds, loop: true));

  @override
  Future<void> stopAll() async => stops++;
}

void main() {
  final raw = loadChordJson();
  final builder = ProgressionBuilder([
    for (final c in raw) ChordFingerings.fromJson(c),
  ]);
  final plan = buildProgressionPlan(
    builder,
    progressions.firstWhere((p) => p.id == 'v1-2'),
    0,
  );
  final shapes = [
    for (final s in plan.steps) ChordShape(name: '', frets: s.voicing.jsonFrets, fingers: List.filled(6, 0)),
  ];

  ProviderContainer container(_FakeAudio audio) {
    final c = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryStore()),
        audioServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  // A 120 BPM, un compás (4 pulsos) dura 2 s.
  const bar = Duration(seconds: 2);
  const half = Duration(seconds: 1);

  testWidgets('suena la vuelta entera al tempo elegido, marca cada acorde y termina en silencio', (
    tester,
  ) async {
    final audio = _FakeAudio();
    final c = container(audio);
    final vm = c.read(progressionsViewModelProvider.notifier)..setBpm(120);
    int? playing() => c.read(progressionsViewModelProvider).playingIndex;

    await vm.listen(plan);
    expect(audio.played.single.loop, isFalse);
    expect(audio.played.single.sounds, progressionStrum(shapes, bpm: 120));
    expect(audio.played.single.seconds, progressionAudioSeconds(4, bpm: 120, loop: false));
    for (var i = 0; i < 4; i++) {
      await tester.pump(half);
      expect(playing(), i);
      await tester.pump(half);
    }
    await tester.pump(half);
    expect(playing(), isNull);
  });

  testWidgets('en bucle vuelve al primer acorde y sigue hasta que se detiene', (tester) async {
    final audio = _FakeAudio();
    final c = container(audio);
    final vm = c.read(progressionsViewModelProvider.notifier)
      ..setBpm(120)
      ..setLoop(loop: true);
    int? playing() => c.read(progressionsViewModelProvider).playingIndex;

    await vm.listen(plan);
    expect(audio.played.single.loop, isTrue);
    expect(audio.played.single.seconds, progressionLapSeconds(4, bpm: 120));
    await tester.pump(bar * 4 + half);
    expect(playing(), 0);
    await tester.pump(bar * 9);
    expect(playing(), 1);
    await vm.listen(plan); // detener
    expect(playing(), isNull);
    expect(audio.stops, 1);
    await tester.pump(bar * 4);
    expect(playing(), isNull);
  });

  testWidgets('cambiar el tempo mientras suena vuelve a empezar con el nuevo; la tonalidad la detiene', (
    tester,
  ) async {
    final audio = _FakeAudio();
    final c = container(audio);
    final vm = c.read(progressionsViewModelProvider.notifier);
    expect(c.read(progressionsViewModelProvider).bpm, progressionDefaultBpm);

    await vm.listen(plan);
    await tester.pump(bar);
    vm.setBpm(100);
    await tester.pump();
    expect(audio.played, hasLength(2));
    expect(audio.played.last.sounds, progressionStrum(shapes, bpm: 100));
    expect(c.read(progressionsViewModelProvider).playingIndex, 0);

    vm.setTonic(7);
    expect(c.read(progressionsViewModelProvider).playingIndex, isNull);
    await tester.pump(bar * 8);
    expect(audio.played, hasLength(2));
  });

  test('el tempo va de 5 en 5 y no sale de 40–200', () {
    final c = container(_FakeAudio());
    final vm = c.read(progressionsViewModelProvider.notifier)..setBpm(12);
    expect(c.read(progressionsViewModelProvider).bpm, 40);
    vm.setBpm(212);
    expect(c.read(progressionsViewModelProvider).bpm, 200);
  });
}
