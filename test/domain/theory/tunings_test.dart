import 'package:chordmaster_free/core/i18n/tr.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:chordmaster_free/domain/theory/tunings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.es);

  test('las cuerdas al aire de cada afinación, de la 6ª a la 1ª', () {
    expect({for (final t in GuitarTuning.values) t: t.notes}, {
      GuitarTuning.standard: 'E A D G B E',
      GuitarTuning.dropD: 'D A D G B E',
      GuitarTuning.halfStepDown: 'D# G# C# F# A# D#',
      GuitarTuning.openG: 'D G D G B D',
      GuitarTuning.dadgad: 'D A D G A D',
    });
    expect(GuitarTuning.standard.openMidi, standardOpenStringMidi);
  });

  test('cómo afinar: dice qué cuerdas bajan, cuánto y a qué nota (comparado con las alturas)', () {
    // (cuerda, semitonos que baja) desde la estándar.
    List<(int, int)> changes(GuitarTuning t) => [
      for (var s = 6; s >= 1; s--)
        if (t.openMidi[s - 1] != standardOpenStringMidi[s - 1]) (s, standardOpenStringMidi[s - 1] - t.openMidi[s - 1]),
    ];
    expect(changes(GuitarTuning.dropD), [(6, 2)]);
    expect(GuitarTuning.dropD.howTo.es, 'Baja la 6ª un tono, a D.');
    expect(changes(GuitarTuning.halfStepDown), [for (var s = 6; s >= 1; s--) (s, 1)]);
    expect(GuitarTuning.halfStepDown.howTo.es, 'Baja todas las cuerdas medio tono.');
    expect(changes(GuitarTuning.openG), [(6, 2), (5, 2), (1, 2)]);
    expect(
      [for (final s in [6, 5, 1]) pitchClassName(GuitarTuning.openG.openMidi[s - 1])],
      ['D', 'G', 'D'],
    );
    expect(GuitarTuning.openG.howTo.es, 'Baja la 6ª, la 5ª y la 1ª un tono: a D, G y D.');
    expect(changes(GuitarTuning.dadgad), [(6, 2), (2, 2), (1, 2)]);
    expect(
      [for (final s in [6, 2, 1]) pitchClassName(GuitarTuning.dadgad.openMidi[s - 1])],
      ['D', 'A', 'D'],
    );
    expect(GuitarTuning.dadgad.howTo.es, 'Baja la 6ª, la 2ª y la 1ª un tono: a D, A y D.');
    for (final t in GuitarTuning.values.skip(1)) {
      expect(t.howTo.en, isNotEmpty);
      expect(t.name.en, isNotEmpty);
    }
  });
}
