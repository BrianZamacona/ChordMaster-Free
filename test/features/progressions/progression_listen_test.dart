import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/progressions/progression_builder.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
import 'package:chordmaster_free/features/progressions/progressions_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements StorageService {
  final data = <String, dynamic>{};

  @override
  Future<void> openBoxes() async {}

  @override
  Future<void> save(String box, String key, dynamic value) async => data[key] = value;

  @override
  Future<T?> get<T>(String box, String key) async {
    final value = data[key];
    return value is T ? value : null;
  }

  @override
  Future<List<dynamic>> getAll(String box) async => data.values.toList();

  @override
  Future<void> delete(String box, String key) async => data.remove(key);

  @override
  Future<void> clear(String box) async => data.clear();
}

class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <String>[];

  @override
  Future<void> playFingering(List<int> jsonFrets) async => played.add(jsonFrets.join(','));
}

void main() {
  final raw = jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List<dynamic>;
  final builder = ProgressionBuilder([
    for (final c in raw) ChordFingerings.fromJson(c as Map<String, dynamic>),
  ]);
  final plan = buildProgressionPlan(
    builder,
    progressions.firstWhere((p) => p.id == 'v1-2'),
    0,
  );
  const step = Duration(milliseconds: 1600);

  ProviderContainer container(_FakeAudio audio) {
    final c = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(_MemoryStorage()),
        audioServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('suenan los 4 acordes en orden, marcando cuál suena, y luego silencio', (
    tester,
  ) async {
    final audio = _FakeAudio();
    final c = container(audio);
    final vm = c.read(progressionsViewModelProvider.notifier);

    final done = vm.listen(plan);
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      expect(c.read(progressionsViewModelProvider).playingIndex, i);
      await tester.pump(step);
    }
    await done;
    expect(c.read(progressionsViewModelProvider).playingIndex, isNull);
    expect(audio.played, [for (final s in plan.steps) s.voicing.jsonFrets.join(',')]);
  });

  testWidgets('volver a tocar detiene; cambiar de tonalidad también', (tester) async {
    final audio = _FakeAudio();
    final c = container(audio);
    final vm = c.read(progressionsViewModelProvider.notifier);

    final first = vm.listen(plan);
    await tester.pump();
    await vm.listen(plan); // detener
    expect(c.read(progressionsViewModelProvider).playingIndex, isNull);
    await tester.pump(step * 4);
    await first;
    expect(audio.played, hasLength(1));

    final second = vm.listen(plan);
    await tester.pump();
    vm.setTonic(7);
    expect(c.read(progressionsViewModelProvider).playingIndex, isNull);
    await tester.pump(step * 4);
    await second;
    expect(audio.played, hasLength(2));
  });
}
