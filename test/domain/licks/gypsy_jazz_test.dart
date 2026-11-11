import 'package:chordmaster_free/domain/guides/style_guides.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/practice/play_along.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jazz gitano: lo que dicen el estilo y sus frases, nota por nota.
void main() {
  final riff = licksById['gypsy_pompe_riff']!;
  final lick = licksById['gypsy_arpeggio_lick']!;
  Set<String> names(TabNote n) => {for (final t in n.tones) pitchClassName(tabMidi(t))};

  test('es un género, con su guía en la fila Géneros', () {
    expect(lickStyleInfo(LickStyle.gypsyJazz).genre, isTrue);
    expect(styleGuides.map((g) => g.id), contains('style_gypsyJazz'));
  });

  test('la pompe: el bajo alterna fundamental y quinta en 1 y 3, la 3ª con la 6ª o la 7ª con palma en 2 y 4; Am6 y E7, todo abajo', () {
    expect([for (final c in riff.chords) (c.degree, c.type)], [(0, 'minor6'), (7, 'dominant7')]);
    final positions = tabPositions(riff.tab);
    for (final (i, n) in riff.tab.indexed) {
      final beat = positions[i] ~/ tabQuarter;
      final why = 'pulso ${beat % 4 + 1}';
      expect(n.length, tabQuarter);
      expect(n.pick, PickStroke.down);
      final am6 = beat < 4;
      if (beat.isEven) {
        expect((n.isChord, n.technique), (false, TabTechnique.none), reason: why);
        // Fundamental en el 1 y quinta en el 3.
        expect(names(n), {['A', 'E', 'E', 'B'][beat ~/ 2]}, reason: why);
      } else {
        expect((n.tones.length, n.technique), (2, TabTechnique.palmMute), reason: why);
        // La 3ª con la 6ª (Am6: C y F#) o con la 7ª (E7: G# y D).
        expect(names(n), am6 ? {'C', 'F#'} : {'G#', 'D'}, reason: why);
      }
    }
    expect(tabLength(riff.tab), 2 * lickBar);
  });

  test('con el micrófono se sigue el bajo: los golpes de acorde no se esperan', () {
    final f = NoteFollower(riff.tab);
    expect([for (final m in f.expected) pitchClassName(m)], ['A', 'E', 'E', 'B']);
    expect(riff.tab.where((n) => n.isChord).every((n) => !tabMicHears(n)), isTrue);
    // Un power chord sí se espera.
    expect(tabMicHears(licksById['punk_power_riff']!.tab.first), isTrue);
  });

  test('el arpegio: sube por Am6 hacia abajo con la púa, pasa al V7 y termina en su 3ª con vibrato', () {
    expect(lick.tab.every((n) => n.pick == PickStroke.down), isTrue);
    final heard = [for (final n in lick.tab) pitchClassName(tabMidi(n))];
    expect(heard.sublist(0, 5), ['A', 'C', 'E', 'F#', 'A']);
    expect(lick.chords.last.degree, 7);
    final last = lick.tab.last;
    expect((pitchClassName(tabMidi(last)), last.technique), ('G#', TabTechnique.vibrato));
    expect(lick.aboutText.es, allOf(contains('Am6'), contains('(F#)'), contains('(G#)')));
    expect(lick.swing, TabSwing.eighths);
  });
}
