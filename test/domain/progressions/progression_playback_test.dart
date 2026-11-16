import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/progressions/progression_data.dart';
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

  test('en 12/8: tres golpes parejos por pulso, el compás dura lo mismo', () {
    final sounds = progressionStrum([c], bpm: 60, feel: ProgressionFeel.triplet);
    // 4 pulsos × 3 golpes × 5 cuerdas.
    expect(sounds, hasLength(4 * 3 * 5));
    final bass = [for (final s in sounds) if (s.midi == 48) s.at];
    expect(bass, hasLength(12));
    for (var k = 0; k < 12; k++) {
      expect(bass[k], closeTo(k / 3, 1e-9));
    }
    expect(strokesPerBeat(ProgressionFeel.straight), 1);
  });

  test('con un patrón de rasgueo, ese patrón en cada compás', () {
    // El 2 son corcheas abajo y arriba: 8 golpes por compás; arriba suenan
    // solo las 4 cuerdas más agudas.
    final sounds = progressionStrum([g], bpm: 60, pattern: 'DUDUDUDU');
    expect(sounds, hasLength(4 * 6 + 4 * 4));
    expect(progressionStrum([g], bpm: 60, pattern: 'D D D D '), progressionStrum([g], bpm: 60));
  });

  group('con la duración de cada acorde', () {
    List<(double, int, double, StringTouch)> sig(List<StringSound> s) => [for (final x in s) (x.at, x.midi, x.seconds, x.touch)];

    test('todos de un compás suena igual que sin duraciones', () {
      for (final pattern in [null, 'DUDUDUDU', 'D DU UDU']) {
        expect(
          sig(progressionStrum([c, g], bpm: 90, pattern: pattern, beats: const [4, 4])),
          sig(progressionStrum([c, g], bpm: 90, pattern: pattern)),
        );
      }
    });

    test('medio compás, medio compás y un compás: un golpe por pulso donde cae', () {
      final sounds = progressionStrum([c, g, c], bpm: 60, beats: const [2, 2, 4]);
      // C (5 cuerdas) en los pulsos 0, 1 y 4–7; G (6 cuerdas) en el 2 y el 3.
      expect(sounds, hasLength(2 * 5 + 2 * 6 + 4 * 5));
      final firstG = sounds.firstWhere((s) => s.midi == 43);
      expect(firstG.at, closeTo(2, 1e-9));
      expect({for (final s in sounds) s.at.floor()}, {0, 1, 2, 3, 4, 5, 6, 7});
    });

    test('el patrón sigue el compás: dos acordes de medio compás tocan un patrón entero', () {
      const pattern = 'D DU UDU';
      final split = progressionStrum([c, c], bpm: 60, pattern: pattern, beats: const [2, 2]);
      final whole = progressionStrum([c], bpm: 60, pattern: pattern);
      expect(sig(split), sig(whole));
    });

    test('la vuelta dura la suma de los pulsos y el acorde que suena sale de ella', () {
      const beats = [1, 2, 8];
      expect(progressionLapSeconds(3, bpm: 60, beats: beats), closeTo(11, 1e-9));
      expect(progressionAudioSeconds(3, bpm: 60, loop: true, beats: beats), closeTo(11, 1e-9));
      expect(progressionAudioSeconds(3, bpm: 60, loop: false, beats: beats), greaterThan(11));
      expect(progressionChordAt(0.5, 3, bpm: 60, loop: false, beats: beats), 0);
      expect(progressionChordAt(1, 3, bpm: 60, loop: false, beats: beats), 1);
      expect(progressionChordAt(2.9, 3, bpm: 60, loop: false, beats: beats), 1);
      expect(progressionChordAt(3, 3, bpm: 60, loop: false, beats: beats), 2);
      expect(progressionChordAt(11, 3, bpm: 60, loop: false, beats: beats), isNull);
      expect(progressionChordAt(11.5, 3, bpm: 60, loop: true, beats: beats), 0);
      expect(progressionChordAt(12.5, 3, bpm: 60, loop: true, beats: beats), 1);
    });

    test('lo que puede durar un acorde: un pulso, medio compás, un compás o dos', () {
      expect(customChordBeats, [1, 2, 4, 8]);
      expect(chordBeats(2, null), [4, 4]);
    });
  });
}
