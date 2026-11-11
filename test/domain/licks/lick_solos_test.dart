import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Solos y rellenos: lo que dicen sus textos, nota por nota.
void main() {
  Lick lick(String id) => licksById[id]!;
  List<TabNote> played(Lick l) => [for (final n in l.tab) if (!n.isRest) n];
  int pc(TabNote n) => tabMidi(n) % 12;
  List<(int, String)> chordsOf(Lick l) => [for (final c in l.chords) (c.degree, c.type)];

  // Las notas que empiezan dentro del compás [bar] (0 = el primero).
  List<TabNote> bar(Lick l, int bar) {
    final positions = tabPositions(l.tab);
    return [
      for (final (i, n) in l.tab.indexed)
        if (!n.isRest && positions[i] ~/ lickBar == bar) n,
    ];
  }

  test('hay un solo por nivel, de cuatro compases y varios renglones', () {
    final solos = licks.where((l) => l.kind == LickKind.solo).toList();
    expect({for (final s in solos) s.level}, GuideLevel.values.toSet());
    for (final s in solos) {
      expect(tabLength(s.tab), 4 * lickBar, reason: s.id);
      expect(tabLineCount(s.tab.length), greaterThanOrEqualTo(2), reason: s.id);
    }
  });

  test('un relleno deja los dos primeros pulsos al rasgueo', () {
    final fills = licks.where((l) => l.kind == LickKind.fill).toList();
    expect(fills, isNotEmpty);
    for (final f in fills) {
      expect(f.tab.first.isRest, isTrue, reason: f.id);
      expect(f.tab.first.length, tabHalf, reason: f.id);
    }
  });

  test('primer solo: I–IV–V–I sin técnicas, un dedo por traste, termina en la tónica', () {
    final l = lick('folk_solo');
    expect(chordsOf(l), [(0, 'major'), (5, 'major'), (7, 'major'), (0, 'major')]);
    expect(l.techniques, isEmpty);
    final frets = [for (final n in played(l)) n.fret];
    expect(frets.reduce((a, b) => a > b ? a : b) - frets.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(3));
    expect(pc(played(l).last), l.scale.root);
    expect(l.aboutText.es, contains('(G)'));
  });

  test('solo de blues menor: bend a la 5ª, ligado a la b5 y cierre en la tónica con vibrato', () {
    final l = lick('minor_blues_solo');
    final r = l.scale.root;
    expect(chordsOf(l), List.filled(4, (0, 'minor7')));
    final first = l.tab.first;
    expect((first.technique, (tabMidi(first) + first.bend) % 12), (TabTechnique.bend, (r + 7) % 12));
    expect(first.bend, 2);
    expect(l.tab.any((n) => n.technique == TabTechnique.hammerOn && pc(n) == (r + 6) % 12), isTrue);
    final last = played(l).last;
    expect((pc(last), last.technique), (r, TabTechnique.vibrato));
    expect(l.aboutText.es, allOf(contains('(E)'), contains('(D#)'), contains('en A con vibrato')));
  });

  test('solo en semicorcheas: i–VI–VII–i, ligados y cada compás cierra con una nota larga con vibrato', () {
    final l = lick('virtuoso_solo');
    expect(chordsOf(l), [(0, 'minor'), (8, 'major'), (10, 'major'), (0, 'minor')]);
    expect(l.techniques, containsAll([TabTechnique.hammerOn, TabTechnique.pullOff]));
    for (var b = 0; b < 4; b++) {
      final notes = bar(l, b);
      expect(notes.last.length, greaterThanOrEqualTo(tabQuarter), reason: 'compás ${b + 1}');
      expect(notes.last.technique, TabTechnique.vibrato, reason: 'compás ${b + 1}');
      expect(notes.sublist(0, notes.length - 1).every((n) => n.length == tabSixteenth), isTrue, reason: 'compás ${b + 1}');
    }
    expect(l.aboutText.en, contains('Am, F, G, Am'));
  });

  test('bajo que camina: G A B por la 6ª y la 5ª hasta la C', () {
    final l = lick('country_walk_fill');
    expect(chordsOf(l), [(0, 'major'), (5, 'major')]);
    final notes = played(l);
    expect([for (final n in notes) pitchClassName(tabMidi(n))], ['G', 'A', 'B', 'C']);
    expect({for (final n in notes) n.string}, {6, 5});
    expect(tabPositions(l.tab)[l.tab.indexOf(notes.last)], lickBar);
  });

  test('respuesta entre acordes: hammer-on y pull-off que caen en la tónica', () {
    final l = lick('minor_blues_fill');
    expect(l.techniques, [TabTechnique.hammerOn, TabTechnique.pullOff]);
    expect(pc(played(l).last), l.scale.root);
  });
}
