import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/theory/note_finder.dart';
import 'package:chordmaster_free/domain/theory/notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chordsJson = (jsonDecode(File('assets/data/chords.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final scalesJson =
      jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map<String, dynamic>;

  // Un tipo por fórmula, en el orden de chords.json (como lo arma la app).
  final types = <PitchFormula>[];
  for (final c in chordsJson) {
    final type = c['type'] as String;
    if (types.any((t) => t.id == type)) continue;
    types.add((id: type, intervals: (c['intervals'] as List).cast<int>()));
  }
  final scales = <PitchFormula>[
    for (final s in [...scalesJson['scales'] as List, ...scalesJson['modes'] as List])
      (id: (s as Map)['id'] as String, intervals: (s['intervals'] as List).cast<int>()),
  ];

  /// Notas de una digitación de chords.json (6ª → 1ª, -1 = muteada).
  List<FretNote> grip(List<int> frets) => [
        for (var i = 0; i < 6; i++)
          if (frets[i] >= 0) (string: 6 - i, fret: frets[i]),
      ];

  List<ChordMatch> chordsOf(List<int> frets) {
    final notes = grip(frets);
    return chordsFor(pitchClassesOf(notes), types: types, bass: bassOf(notes));
  }

  final c = noteIndex('C'), e = noteIndex('E'), a = noteIndex('A');

  group('acordes', () {
    test('x32010 es C, con la tónica en el bajo', () {
      final first = chordsOf([-1, 3, 2, 0, 1, 0]).first;
      expect((first.root, first.type, first.isSlash), (c, 'major', false));
    });

    test('032010 es C/E: la E al aire de la 6ª queda en el bajo', () {
      final first = chordsOf([0, 3, 2, 0, 1, 0]).first;
      expect((first.root, first.type, first.bass), (c, 'major', e));
      expect(first.isSlash, isTrue);
    });

    test('A C E G con A en el bajo: primero Am7, después C6/A', () {
      final matches = chordsOf([-1, 0, 2, 0, 1, 3]);
      expect((matches[0].root, matches[0].type), (a, 'minor7'));
      expect(matches.any((m) => m.root == c && m.type == 'sixth' && m.isSlash), isTrue);
    });

    test('C E A# sin G: C7 sin la 5ª', () {
      final m = chordsFor({c, e, noteIndex('A#')}, types: types, bass: c);
      expect(m.first, ChordMatch(root: c, type: 'dominant7', bass: c, omitted: const [7]));
    });

    test('C13 sin 5ª, 9ª ni 11ª (x32355) y Cm11 sin 9ª (x33343)', () {
      final c13 = chordsOf([-1, 3, 2, 3, 5, 5]).firstWhere((m) => m.type == 'thirteenth');
      expect(c13.root, c);
      expect(c13.omitted, [7, 14, 17]);
      final cm11 = chordsOf([-1, 3, 3, 3, 4, 3]).firstWhere((m) => m.type == 'minor11');
      expect(cm11.root, c);
      expect(cm11.omitted, [14]);
    });

    test('la nota que da el nombre no se omite: C E G no es Cadd9 ni C9', () {
      final m = chordsFor({c, e, noteIndex('G')}, types: types, bass: c);
      expect(m.first, ChordMatch(root: c, type: 'major', bass: c));
      expect(m.any((x) => x.root == c && (x.type == 'add9' || x.type == 'dominant9')), isFalse);
    });

    test('dos notas a una 5ª: power chord', () {
      final m = chordsOf([0, 2, -1, -1, -1, -1]);
      expect((m.first.root, m.first.type), (e, 'power5'));
    });

    test('una sola nota no es un acorde', () {
      expect(chordsOf([-1, -1, -1, -1, -1, 0]), isEmpty);
      expect(chordsOf([0, -1, -1, -1, -1, 0]), isEmpty, reason: 'E y E: una sola nota');
    });

    test('la digitación principal de cada acorde de chords.json se reconoce como él', () {
      final failures = <String>[];
      for (final chord in chordsJson) {
        final root = noteIndex(chord['root'] as String);
        final type = chord['type'] as String;
        final found = chordsOf((chord['fretPositions'] as List).cast<int>());
        if (!found.any((m) => m.root == root && m.type == type)) {
          failures.add('${chord['name']} ${chord['fretPositions']}');
        }
      }
      expect(failures, isEmpty);
    });
  });

  group('escalas', () {
    test('A C D E G: las dos pentatónicas exactas, primero la de la nota grave', () {
      final notes = {a, c, noteIndex('D'), e, noteIndex('G')};
      final m = scalesFor(notes, scales: scales, tonic: a);
      expect(m.take(2).toList(), [
        ScaleMatch(root: a, id: 'pentatonic_minor', extra: 0),
        ScaleMatch(root: c, id: 'pentatonic_major', extra: 0),
      ]);
      expect(m.every((s) => s.extra >= 0), isTrue);
    });

    test('las 7 notas de C mayor con C abajo: C Mayor primero y sin repetir la Jónica', () {
      final notes = {for (final i in [0, 2, 4, 5, 7, 9, 11]) i};
      final m = scalesFor(notes, scales: scales, tonic: c);
      expect(m.first, ScaleMatch(root: c, id: 'major', extra: 0));
      expect(m.any((s) => s.root == c && s.id == 'ionian'), isFalse);
      expect(m.any((s) => s.root == a && s.id == 'natural_minor'), isTrue);
      expect(m.any((s) => s.root == noteIndex('D') && s.id == 'dorian'), isTrue);
    });

    test('cada escala, en cada tónica, se encuentra con sus propias notas', () {
      for (final s in scales) {
        for (var root = 0; root < 12; root++) {
          final notes = {for (final i in s.intervals) (root + i) % 12};
          final m = scalesFor(notes, scales: scales, tonic: root);
          // La primera es ella o una de igual tónica y mismas notas (mayor = jónica).
          expect(m.first.root, root, reason: '${s.id} en ${pitchClassName(root)}');
          expect(m.first.extra, 0, reason: '${s.id} en ${pitchClassName(root)}');
        }
      }
    });

    test('notas que no caben en ninguna escala: sin resultados', () {
      // Cromático de 9 notas.
      expect(scalesFor({for (var i = 0; i < 9; i++) i}, scales: scales), isEmpty);
    });
  });

  test('bajo y clases de altura de lo marcado', () {
    final notes = <FretNote>[(string: 1, fret: 0), (string: 5, fret: 3), (string: 2, fret: 1)];
    expect(bassOf(notes), c);
    expect(pitchClassesOf(notes), {e, c});
    expect(bassOf(const []), isNull);
  });
}
