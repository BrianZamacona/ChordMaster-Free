import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/progressions/progression_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = ChordShape(name: 'C', frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0]);
  const g = ChordShape(name: 'G', frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, 0, 0, 0, 3]);

  test('el tempo va de 5 en 5, entre 40 y 200', () {
    expect(progressionTempo(83), 85);
    expect(progressionTempo(10), 40);
    expect(progressionTempo(260), 200);
    expect(progressionTempo(progressionDefaultBpm), progressionDefaultBpm);
  });

  test('un compás por acorde: cuatro golpes, uno por pulso, con todas sus cuerdas', () {
    final sounds = progressionStrum([c, g], bpm: 60);
    // C suena en 5 cuerdas y G en 6, cuatro golpes cada uno.
    expect(sounds, hasLength(4 * 5 + 4 * 6));
    final starts = {for (final s in sounds) s.at.floor()};
    expect(starts, {0, 1, 2, 3, 4, 5, 6, 7});
    // El primer golpe de G cae en el pulso 5 (a 60 BPM, a los 4 s).
    final firstG = sounds.firstWhere((s) => s.midi == 43);
    expect(firstG.at, closeTo(4, 1e-9));
  });

  test('en bucle, el archivo dura la vuelta justa; sin bucle, también lo que tarda en apagarse', () {
    expect(progressionLapSeconds(4, bpm: 80), closeTo(12, 1e-9));
    expect(progressionAudioSeconds(4, bpm: 80, loop: true), closeTo(12, 1e-9));
    expect(progressionAudioSeconds(4, bpm: 80, loop: false), greaterThan(12));
  });

  test('qué acorde suena: en bucle vuelve a empezar; sin bucle se termina', () {
    // A 120 BPM cada acorde dura 2 s.
    expect(progressionChordAt(0, 3, bpm: 120, loop: false), 0);
    expect(progressionChordAt(2.1, 3, bpm: 120, loop: false), 1);
    expect(progressionChordAt(5.9, 3, bpm: 120, loop: false), 2);
    expect(progressionChordAt(6, 3, bpm: 120, loop: false), isNull);
    expect(progressionChordAt(6, 3, bpm: 120, loop: true), 0);
    expect(progressionChordAt(9, 3, bpm: 120, loop: true), 1);
    expect(progressionChordAt(1, 0, bpm: 120, loop: true), isNull);
  });
}
