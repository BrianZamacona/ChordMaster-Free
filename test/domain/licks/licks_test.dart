import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/practice/tab_notation.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final master = jsonDecode(File('assets/data/scales_master.json').readAsStringSync()) as Map;
  final intervals = {
    for (final s in [...master['scales'] as List, ...master['modes'] as List])
      (s as Map)['id'] as String: (s['intervals'] as List).cast<int>(),
  };
  Set<int> pitchClasses(LessonScale s) => {for (final i in intervals[s.scaleId]!) (s.root + i) % 12};
  List<TabNote> played(Lick l) => [for (final n in l.tab) if (!n.isRest) n];
  Lick lick(String id) => licksById[id]!;

  group('cada frase', () {
    test('ids únicos y textos en los dos idiomas', () {
      expect(licksById, hasLength(licks.length));
      for (final l in licks) {
        for (final t in [l.title, l.about]) {
          expect(t.es.trim(), isNotEmpty, reason: l.id);
          expect(t.en.trim(), isNotEmpty, reason: l.id);
        }
      }
    });

    test('cada nota (y la nota a la que llega un bend) es de su escala', () {
      for (final l in licks) {
        expect(intervals, contains(l.scale.scaleId), reason: l.id);
        final allowed = pitchClasses(l.scale);
        for (final n in played(l)) {
          expect(allowed, contains(tabMidi(n) % 12), reason: '${l.id} $n');
          expect(allowed, contains((tabMidi(n) + n.bend) % 12), reason: '${l.id} $n');
        }
      }
    });

    test('la tablatura está bien escrita y dura pulsos enteros', () {
      for (final l in licks) {
        expect(tabNotationProblems(l.tab), isEmpty, reason: l.id);
        expect(tabLength(l.tab) % 4, 0, reason: l.id);
      }
    });

    test('la mano no se estira más de 5 trastes ni sube del 15', () {
      for (final l in licks) {
        final frets = [for (final n in played(l)) if (n.fret > 0) n.fret];
        expect(frets.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(15), reason: l.id);
        final span = frets.reduce((a, b) => a > b ? a : b) - frets.reduce((a, b) => a < b ? a : b);
        expect(span, lessThanOrEqualTo(5), reason: l.id);
      }
    });

    test('tempo razonable para empezar', () {
      for (final l in licks) {
        expect(l.bpm, inInclusiveRange(50, 120), reason: l.id);
      }
    });
  });

  group('estilos', () {
    test('cada estilo tiene un riff y un lick, el riff primero', () {
      for (final style in LickStyle.values) {
        final mine = licks.where((l) => l.style == style).toList();
        expect(mine.map((l) => l.kind), containsAll(LickKind.values), reason: style.name);
        expect(mine.first.kind, LickKind.riff, reason: style.name);
      }
    });

    test('las técnicas que nombra un estilo están en sus frases', () {
      for (final style in LickStyle.values) {
        final info = lickStyleInfo(style);
        expect(info.title.es, isNotEmpty);
        expect(info.summary.en, isNotEmpty);
        final used = {for (final l in licks.where((l) => l.style == style)) ...l.techniques};
        expect(used, containsAll(info.traits), reason: style.name);
      }
    });
  });

  group('lo que dicen los textos', () {
    test('estadio: el pedal de la 6ª al aire va con palma; el lick sube un tono y cierra en la tónica', () {
      for (final n in played(lick('stadium_riff')).where((n) => n.string == 6 && n.fret == 0)) {
        expect(n.technique, TabTechnique.palmMute);
      }
      final l = played(lick('stadium_lick'));
      expect((l.first.technique, l.first.bend), (TabTechnique.bend, 2));
      expect(l[1].technique, TabTechnique.release);
      expect(tabMidi(l.last) % 12, lick('stadium_lick').scale.root);
      expect(l.last.technique, TabTechnique.vibrato);
    });

    test('clásico: todo con la púa abajo; la 5ª al aire con palma entre cada nota', () {
      final riff = played(lick('classic_riff'));
      expect(riff.every((n) => n.pick == PickStroke.down), isTrue);
      for (final n in riff.where((n) => n.string == 5 && n.fret == 0)) {
        expect(n.technique, TabTechnique.palmMute);
      }
      final l = played(lick('classic_lick'));
      final bend = l.firstWhere((n) => n.technique == TabTechnique.bend);
      expect((bend.string, bend.bend), (3, 2));
      expect(tabMidi(l.last) % 12, lick('classic_lick').scale.root);
    });

    test('doom: el slide en la 6ª llega a la b5', () {
      final slide = played(lick('doom_riff')).firstWhere((n) => n.technique == TabTechnique.slide);
      expect(slide.string, 6);
      expect((tabMidi(slide) - lick('doom_riff').scale.root) % 12, 6);
      expect(played(lick('doom_lick')).any((n) => (tabMidi(n) - 4) % 12 == 6), isTrue);
    });

    test('thrash: galope = corchea y dos semicorcheas, con palma; la 2ª menor aparece', () {
      final riff = lick('thrash_riff').tab;
      expect([for (final n in riff.take(3)) n.length], [tabEighth, tabSixteenth, tabSixteenth]);
      expect(riff.take(3).every((n) => n.technique == TabTechnique.palmMute), isTrue);
      expect(riff.any((n) => (tabMidi(n) - lick('thrash_riff').scale.root) % 12 == 1), isTrue);
      final l = lick('thrash_lick').tab;
      expect(l.every((n) => n.length == tabSixteenth), isTrue);
      for (var i = 0; i < l.length; i++) {
        expect(l[i].pick, i.isEven ? PickStroke.down : PickStroke.up);
      }
    });

    test('rock latino: hay silencios; el slide llega a la 6ª mayor y cierra con vibrato en la tónica', () {
      expect(lick('latin_riff').tab.where((n) => n.isRest), isNotEmpty);
      final l = lick('latin_lick');
      final slide = l.tab.firstWhere((n) => n.technique == TabTechnique.slide);
      expect((tabMidi(slide) - l.scale.root) % 12, 9);
      expect(tabMidi(l.tab.last) % 12, l.scale.root);
      expect(l.tab.last.technique, TabTechnique.vibrato);
    });

    test('sinfónico: dos tríadas en la 3ª, 2ª y 1ª cuerda; el lick llega con un slide', () {
      final riff = lick('symphonic_riff').tab;
      expect({for (final n in riff) n.string}, {1, 2, 3});
      Set<int> classes(Iterable<TabNote> ns) => {for (final n in ns) tabMidi(n) % 12};
      // G = B D G (sol, si, re) y C = C E G.
      expect(classes(riff.take(4)), {7, 11, 2});
      expect(classes(riff.skip(4)), {0, 4, 7});
      expect(lick('symphonic_lick').tab.last.technique, TabTechnique.slide);
    });

    test('psicodélico: los pull-offs caen en cuerdas al aire; el lick termina en la 6ª con vibrato', () {
      final pulls = lick('psychedelic_riff').tab.where((n) => n.technique == TabTechnique.pullOff);
      expect(pulls, isNotEmpty);
      expect(pulls.every((n) => n.fret == 0), isTrue);
      final last = lick('psychedelic_lick').tab.last;
      expect((last.string, last.technique), (6, TabTechnique.vibrato));
    });

    test('virtuoso: una sola púa por cuerda en el lick; el riff alterna la púa', () {
      final l = lick('virtuoso_lick').tab;
      for (var i = 0; i < l.length; i++) {
        final newString = i == 0 || l[i].string != l[i - 1].string;
        expect(l[i].technique == TabTechnique.none, newString, reason: '$i');
      }
      final riff = lick('virtuoso_riff').tab;
      for (var i = 0; i < riff.length; i++) {
        expect(riff[i].pick, i.isEven ? PickStroke.down : PickStroke.up);
      }
    });

    test('atmosférico: el arpegio no repite cuerda seguida; el lick tiene un silencio antes de la última', () {
      final riff = lick('atmospheric_riff').tab;
      for (var i = 1; i < riff.length; i++) {
        expect(riff[i].string, isNot(riff[i - 1].string));
      }
      final l = lick('atmospheric_lick').tab;
      expect(l[l.length - 2].isRest, isTrue);
    });

    test('progresivo: grupos de tres semicorcheas contra cuatro; ligados en la 1ª cuerda', () {
      final riff = lick('progressive_riff').tab;
      expect(riff.every((n) => n.length == tabSixteenth), isTrue);
      // El patrón se repite cada 3 y el compás dura 16: la nota alta cae cada vez en otro lugar.
      for (var i = 3; i < riff.length - 1; i++) {
        expect(riff[i], riff[i - 3]);
      }
      final legato = lick('progressive_lick').tab.where((n) => n.technique.legato);
      expect(legato.where((n) => n.string == 1).length, greaterThan(legato.length / 2));
    });

    test('folk: el hammer-on está en la segunda vuelta; el lick baja con pull-offs a la 3ª al aire', () {
      final riff = lick('folk_riff').tab;
      final hammer = riff.indexWhere((n) => n.technique == TabTechnique.hammerOn);
      expect(tabPositions(riff)[hammer], greaterThanOrEqualTo(16));
      final l = lick('folk_lick').tab;
      expect(l.first.technique, TabTechnique.none);
      expect(l[1].technique, TabTechnique.slide);
      expect((l.last.string, l.last.fret, l.last.technique), (3, 0, TabTechnique.pullOff));
    });
  });
}
