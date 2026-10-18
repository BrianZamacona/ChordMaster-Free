import 'package:chordmaster_free/features/rhythm_games/rhythm_game_viewmodel.dart';
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

  final ticks = <bool>[];

  @override
  Future<void> playMetronomeTick({bool isAccent = false}) async => ticks.add(isAccent);
}

void main() {
  testWidgets('cada tiempo suena un clic, con acento cada 4', (tester) async {
    final audio = _FakeAudio();
    final container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(_MemoryStorage()),
        audioServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(container.dispose);
    final vm = container.read(rhythmGameViewModelProvider.notifier)..setBpm(120);

    vm.start();
    await tester.pump(const Duration(milliseconds: 500 * 8 + 50));
    await vm.stop();

    expect(audio.ticks, [true, false, false, false, true, false, false, false]);
  });

  group('puntuación', () {
    TapResult tap(int offset) => TapResult(offsetMs: offset, timestamp: DateTime(2026));

    test('un solo toque bien dado ya no es 100 %: los pulsos sin tocar cuentan', () {
      final s = RhythmGameState(tapResults: [tap(10)], beatCount: 8);
      expect(s.accuracy, 13); // 1 de 8
      expect(s.countsForRecord, isFalse);
    });

    test('margen de ±75 ms', () {
      expect(tap(75).isAccurate, isTrue);
      expect(tap(-75).isAccurate, isTrue);
      expect(tap(76).isAccurate, isFalse);
      expect(tap(-150).isAccurate, isFalse);
    });

    test('16 toques a tiempo en 16 pulsos: 100 % y cuenta como récord', () {
      final s = RhythmGameState(tapResults: [for (var i = 0; i < 16; i++) tap(20)], beatCount: 16);
      expect(s.accuracy, 100);
      expect(s.countsForRecord, isTrue);
    });

    test('tocar de más también resta', () {
      final s = RhythmGameState(tapResults: [for (var i = 0; i < 20; i++) tap(i.isEven ? 0 : 300)], beatCount: 10);
      expect(s.accuracy, 50); // 10 a tiempo de 20 toques
    });
  });
}
