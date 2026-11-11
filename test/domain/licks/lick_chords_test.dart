import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/lick_transpose.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/open_chords/chord_shape.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final scaleIntervals = {
    for (final s in [...master['scales'] as List, ...master['modes'] as List])
      (s as Map)['id'] as String: (s['intervals'] as List).cast<int>(),
  };
  // Intervalos de cada (raíz, tipo) de chords.json.
  final chordJson = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List).cast<Map>();
  final chordIntervals = {
    for (final c in chordJson) (noteIndex(c['root'] as String), c['type'] as String): (c['intervals'] as List).cast<int>(),
  };
  Set<int> chordTones(int root, LickChord c) => {for (final i in chordIntervals[(root, c.type)]!) (root + i) % 12};
  Set<int> scaleTones(LessonScale s) => {for (final i in scaleIntervals[s.scaleId]!) (s.root + i) % 12};
  // Lo que se oye de una nota: con bend, la nota a la que llega.
  Set<int> heard(TabNote n) => {for (final t in n.tones) (tabMidi(t) + t.bend) % 12};

  test('cada frase tiene acordes: duran lo que la tablatura y cada uno entra con una nota', () {
    for (final l in licks) {
      expect(l.chords, isNotEmpty, reason: l.id);
      expect(l.chords.fold(0, (sum, c) => sum + c.length), tabLength(l.tab), reason: l.id);
      final starts = tabPositions(l.tab).toSet();
      for (final c in l.chordsIn(l.scale.root)) {
        expect(starts, contains(c.start), reason: '${l.id}: el acorde de la parte ${c.start} no cae en una nota');
      }
    }
  });

  test('cada acorde existe en chords.json en toda tónica que se ofrece y sus notas son de la escala', () {
    for (final l in licks) {
      final roots = isMovable(l) ? transposableRoots(l) : [l.scale.root];
      for (final r in roots) {
        final scale = LessonScale(scaleId: l.scale.scaleId, root: r);
        for (final c in l.chordsIn(r)) {
          final why = '${l.id} en ${pitchClassName(r)}: ${pitchClassName(c.root)} ${c.chord.type}';
          expect(chordIntervals, contains((c.root, c.chord.type)), reason: why);
          expect(scaleTones(scale), containsAll(chordTones(c.root, c.chord)), reason: why);
        }
      }
    }
  });

  test('la frase cae en sus acordes: la primera nota de cada uno, y en los licks las largas y la última', () {
    for (final l in licks) {
      final spans = l.chordsIn(l.scale.root);
      final positions = tabPositions(l.tab);
      ({int root, LickChord chord, int start}) at(int tick) => spans.lastWhere((s) => s.start <= tick);
      final sounding = [
        for (final (i, n) in l.tab.indexed)
          if (!n.isRest) (note: n, at: positions[i]),
      ];
      for (final s in spans) {
        final first = sounding.firstWhere((x) => x.at >= s.start);
        expect(chordTones(s.root, s.chord), containsAll(heard(first.note)), reason: '${l.id}: entra ${s.chord.type}');
      }
      if (l.kind != LickKind.lick) continue;
      for (final x in sounding) {
        final last = identical(x, sounding.last);
        if (x.note.length < tabQuarter && !last) continue;
        final c = at(x.at);
        expect(chordTones(c.root, c.chord), containsAll(heard(x.note)), reason: '${l.id}: ${x.note} sobre ${c.chord.type}');
      }
    }
  });

  test('el lick de jazz es el ii–V–I que dice su texto: Dm7, G7 y Cmaj7 en la 3ª', () {
    final jazz = licksById['jazz_lick']!;
    final spans = jazz.chordsIn(jazz.scale.root);
    expect([for (final s in spans) (pitchClassName(s.root), s.chord.type)], [
      ('D', 'minor7'),
      ('G', 'dominant7'),
      ('C', 'major7'),
    ]);
    expect(jazz.aboutText.es, allOf(contains('Dm7'), contains('G7'), contains('3ª de C')));
    // La última nota es la 3ª de C.
    final last = jazz.tab.lastWhere((n) => !n.isRest);
    expect(pitchClassName(tabMidi(last)), 'E');
  });

  test('al transponer, los acordes se mueven con la tónica', () {
    final l = licksById['metal_lick']!;
    final c = l.chordsIn(noteIndex('A'));
    expect([for (final s in c) pitchClassName(s.root)], ['A', 'E']);
    expect(c.last.start, tabQuarter * 3);
  });

  test('la parte rítmica: un golpe al entrar cada acorde y en cada pulso mientras dura', () {
    final jazz = licksById['jazz_lick']!;
    // Dm7 en 0 y 1, G7 en 2 y 3, Cmaj7 en la "y" del 4.
    expect(jazz.chordStrokes, [
      (chord: 0, beat: 0.0),
      (chord: 0, beat: 1.0),
      (chord: 1, beat: 2.0),
      (chord: 1, beat: 3.0),
      (chord: 2, beat: 3.5),
    ]);
    for (final l in licks) {
      final strokes = l.chordStrokes;
      expect(strokes.first.beat, 0, reason: l.id);
      expect(strokes.length, greaterThanOrEqualTo(tabLength(l.tab) ~/ tabQuarter), reason: l.id);
    }
    const shape = ChordShape(name: 'E5', frets: [0, 2, 2, -1, -1, -1], fingers: [0, 1, 1, 0, 0, 0]);
    final sounds = strumStrokes([(shape: shape, beat: 0), (shape: shape, beat: 1.5)], bpm: 60);
    expect(sounds, hasLength(6));
    expect(sounds[3].at, 1.5);
    expect([for (final s in sounds.take(3)) s.midi], [40, 47, 52]);
  });
}
