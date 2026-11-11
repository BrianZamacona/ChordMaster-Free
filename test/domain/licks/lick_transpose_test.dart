import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/lick_transpose.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/practice/tab_notation.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final intervals = {
    for (final s in [...master['scales'] as List, ...master['modes'] as List])
      (s as Map)['id'] as String: (s['intervals'] as List).cast<int>(),
  };
  Set<int> pitchClasses(LessonScale s) => {for (final i in intervals[s.scaleId]!) (s.root + i) % 12};
  List<TabNote> tones(List<TabNote> tab) => [for (final n in tab) ...n.tones];
  final movable = licks.where(isMovable).toList();

  test('movible = ninguna nota al aire; las demás no se ofrecen en otra tónica', () {
    expect(movable, isNotEmpty);
    for (final l in licks) {
      final open = tones(l.tab).any((t) => t.fret == 0);
      expect(isMovable(l), !open, reason: l.id);
      if (open) expect(transposableRoots(l), isEmpty, reason: l.id);
    }
  });

  test('en cada tónica que se ofrece: bien escrita, dentro del mástil y en su escala', () {
    for (final l in movable) {
      final roots = transposableRoots(l);
      expect(roots, contains(l.scale.root), reason: l.id);
      expect(transposeShift(l, l.scale.root), 0, reason: l.id);
      for (final r in roots) {
        final moved = transposedLick(l, r)!;
        final why = '${l.id} en ${pitchClassName(r)}';
        expect(moved.scale.root, r, reason: why);
        expect(tabNotationProblems(moved.tab), isEmpty, reason: why);
        final allowed = pitchClasses(moved.scale);
        for (final t in tones(moved.tab)) {
          expect(t.fret, inInclusiveRange(1, lickMaxFret), reason: why);
          expect(allowed, contains(tabMidi(t) % 12), reason: '$why $t');
          expect(allowed, contains((tabMidi(t) + t.bend) % 12), reason: '$why $t');
        }
        // La misma frase: los mismos intervalos entre notas, el mismo ritmo y
        // las mismas técnicas.
        final before = tones(l.tab);
        final after = tones(moved.tab);
        for (var i = 1; i < before.length; i++) {
          expect(tabMidi(after[i]) - tabMidi(after[i - 1]), tabMidi(before[i]) - tabMidi(before[i - 1]), reason: why);
        }
        expect([for (final n in moved.tab) (n.length, n.technique, n.pick)], [for (final n in l.tab) (n.length, n.technique, n.pick)]);
      }
    }
  });

  test('se mueve por el camino más corto que cabe en el mástil', () {
    for (final l in movable) {
      for (final r in transposableRoots(l)) {
        final shift = transposeShift(l, r)!;
        expect((l.scale.root + shift - r) % 12, 0, reason: l.id);
        expect(shift.abs(), lessThan(12), reason: l.id);
        // La otra octava, si es más corta, no cabría.
        final other = shift > 0 ? shift - 12 : shift + 12;
        if (other.abs() < shift.abs()) {
          final frets = [for (final t in tones(l.tab)) t.fret + other];
          expect(frets.any((f) => f < 1 || f > lickMaxFret), isTrue, reason: l.id);
        }
      }
    }
    // Un ejemplo: la b5 que baja (A) lleva a C subiendo 3 trastes.
    expect(transposeShift(licksById['minor_blues_lick']!, noteIndex('C')), 3);
  });

  test('los textos de las movibles nombran notas desde la tónica: al transponer siguen siendo ciertos', () {
    final note = RegExp(r'(?<![\w#{+])[A-G]#?(?![\w#])');
    // En inglés, "A" al empezar una frase y antes de una palabra en minúscula
    // es el artículo, no la nota.
    final article = RegExp('(^|[.:!?] )A (?=[a-z])');
    for (final l in movable) {
      for (final t in [l.about.es, l.about.en.replaceAll(article, r'$1')]) {
        expect(note.hasMatch(t), isFalse, reason: '${l.id}: "$t" nombra una nota fija');
      }
    }
    for (final l in licks) {
      for (var r = 0; r < 12; r++) {
        expect(l.aboutIn(r).es, isNot(contains('{')), reason: l.id);
        expect(l.aboutIn(r).en, isNot(contains('{')), reason: l.id);
      }
    }
    // En su tonalidad dicen lo de siempre; en otra, las notas de esa.
    final southern = licksById['southern_lick']!;
    expect(southern.aboutText.es, contains('(B)'));
    expect(southern.aboutText.es, contains('(C#)'));
    expect(southern.aboutText.es, contains('en A con vibrato'));
    expect(southern.aboutIn(noteIndex('C')).es, allOf(contains('(D)'), contains('(E)'), contains('en C con vibrato')));
    expect(licksById['metal_lick']!.aboutText.en, contains('(D#)'));
    expect(licksById['minor_blues_lick']!.aboutIn(noteIndex('C')).en, allOf(contains('(F#)'), contains('on C with vibrato')));
    expect(renderNoteTemplate('{R} y {R+7}', noteIndex('E')), 'E y B');
  });
}
