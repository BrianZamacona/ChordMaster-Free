import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/features/ear_training/ear_training_screen.dart';
import 'package:chordmaster_free/features/ear_training/ear_training_viewmodel.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/key_value_store.dart';
import 'package:chordmaster_free/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/in_memory_store.dart';

/// Registra lo que se pidió sonar, sin reproducir nada.
class _FakeAudio extends AudioService {
  _FakeAudio() : super.forTesting();

  final played = <List<NoteEvent>>[];

  @override
  Future<void> playNotes(List<NoteEvent> events, {double seconds = 2.5}) async =>
      played.add(events);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('melódico: grave y luego aguda; armónico: casi a la vez', () {
    expect(intervalEvents(52, 7), [(midi: 52, at: 0.0), (midi: 59, at: 0.8)]);
    expect(intervalEvents(52, 7, harmonic: true), [(midi: 52, at: 0.0), (midi: 59, at: 0.03)]);
  });

  test('cada pregunta: nota grave entre C3 y C4 y 4 opciones con la correcta', () {
    final audio = _FakeAudio();
    final container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(InMemoryStore()),
        audioServiceProvider.overrideWithValue(audio),
      ],
    );
    addTearDown(container.dispose);
    final vm = container.read(earTrainingViewModelProvider.notifier);
    for (var i = 0; i < 50; i++) {
      final s = container.read(earTrainingViewModelProvider);
      expect(s.rootMidi, inInclusiveRange(48, 60));
      expect(s.choices, hasLength(4));
      expect(s.choices.map((c) => c.semitones), contains(s.currentInterval.semitones));
      expect(s.rootMidi + s.currentInterval.semitones, lessThanOrEqualTo(72));
      vm.nextQuestion();
      // Al pasar de pregunta suena la nueva.
      final now = container.read(earTrainingViewModelProvider);
      expect(audio.played.last, intervalEvents(now.rootMidi, now.currentInterval.semitones));
    }
  });

  testWidgets('la respuesta no se ve hasta contestar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryStore()),
          audioServiceProvider.overrideWithValue(_FakeAudio()),
        ],
        child: MaterialApp(theme: lightTheme, home: const EarTrainingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ear-play')), findsOneWidget);
    expect(find.byKey(const Key('ear-reveal')), findsNothing);
    expect(find.textContaining('semitono'), findsNothing);

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ear-reveal')), findsOneWidget);
    expect(find.textContaining('semitono'), findsOneWidget);
  });
}
