import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chordmaster_free/domain/audio/note_onsets.dart';
import 'package:chordmaster_free/domain/audio/pitch_detection.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/play_along.dart';
import 'package:chordmaster_free/domain/practice/tab_notation.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:flutter_test/flutter_test.dart';

/// Altura de [audio] en la ventana que empieza en [from] segundos, como la
/// leería el micrófono (22.05 kHz).
double _hzAt(Float64List audio, double from) {
  final half = decimateByTwo(audio);
  final start = (from * synthSampleRate / 2).round();
  return detectPitchHz(Float64List.sublistView(half, start, start + 2048), synthSampleRate ~/ 2)!;
}

double _cents(double hz, double midi) => 1200 * math.log(hz / (440 * math.pow(2, (midi - 69) / 12))) / math.ln2;

double _rms(Float64List x, double from, double to) {
  final a = (from * synthSampleRate).round();
  final b = (to * synthSampleRate).round();
  var sum = 0.0;
  for (var i = a; i < b; i++) {
    sum += x[i] * x[i];
  }
  return math.sqrt(sum / (b - a));
}

void main() {
  group('ritmo', () {
    test('cada nota empieza donde terminó la anterior (en partes de pulso)', () {
      const tab = [
        TabNote(1, 0, length: tabQuarter),
        TabNote.rest(tabEighth),
        TabNote(1, 1, length: tabSixteenth),
        TabNote(1, 3, length: tabSixteenth),
      ];
      expect(tabPositions(tab), [0, 12, 18, 21]);
      expect(tabLength(tab), 24);
      expect(tabOnsetSeconds(tab, bpm: 60), [0, 1, 1.5, 1.75]);
      expect(tabEndSeconds(tab, bpm: 60), 2);
    });

    test('swing de corcheas: el contratiempo cae a dos tercios del pulso', () {
      expect(tabSwungBeats(tabEighth, TabSwing.eighths), closeTo(2 / 3, 1e-12));
      expect(tabSwungBeats(tabQuarter, TabSwing.eighths), 1);
      expect(tabSwungBeats(tabQuarter + tabEighth, TabSwing.eighths), closeTo(1 + 2 / 3, 1e-12));
      // Sin swing, igual que antes.
      expect(tabSwungBeats(tabQuarter + tabEighth, TabSwing.none), 1.5);
    });

    test('swing de semicorcheas: cada "e" y cada "a" llegan tarde', () {
      expect(tabSwungBeats(tabSixteenth, TabSwing.sixteenths), closeTo(1 / 3, 1e-12));
      expect(tabSwungBeats(tabEighth, TabSwing.sixteenths), 0.5);
      expect(tabSwungBeats(3 * tabSixteenth, TabSwing.sixteenths), closeTo(0.5 + 1 / 3, 1e-12));
      expect(tabSwungBeats(tabQuarter, TabSwing.sixteenths), 1);
    });

    test('la nota marcada sigue a las duraciones, también en un silencio', () {
      const tab = [TabNote(1, 0, length: tabQuarter), TabNote.rest(tabEighth), TabNote(1, 1)];
      expect(tabIndexAt(0.9, tab, bpm: 60), 0);
      expect(tabIndexAt(1.2, tab, bpm: 60), 1);
      expect(tabIndexAt(1.5, tab, bpm: 60), 2);
      expect(tabIndexAt(2, tab, bpm: 60), isNull);
    });

    test('se cuenta "1 e y a" y el número del pulso dentro del compás', () {
      String count(int p, {int beats = 4}) =>
          tabCountAt(p, e: 'e', and: 'y', a: 'a', trip: 'tri', let: 'ple', beatsPerBar: beats);
      expect(
        [for (var p = 0; p < 8; p++) count(p * tabSixteenth)],
        ['1', 'e', 'y', 'a', '2', 'e', 'y', 'a'],
      );
      expect(count(4 * tabQuarter), '1');
      expect(count(3 * tabQuarter, beats: 3), '1');
      // Tresillo de corcheas: "1 tri ple".
      expect([for (var p = 0; p < 3; p++) count(p * tabTripletEighth)], ['1', 'tri', 'ple']);
    });

    test('el conteo se dibuja solo si la tablatura trae ritmo propio', () {
      expect(tabHasRhythm(const [TabNote(1, 0), TabNote(1, 1)]), isFalse);
      expect(tabHasRhythm(const [TabNote(1, 0, length: tabQuarter)]), isTrue);
      expect(tabHasRhythm(const [TabNote.rest(tabEighth)]), isTrue);
      expect(tabHasRhythm(const [TabNote(1, 0)], swing: TabSwing.eighths), isTrue);
    });
  });

  group('tresillos', () {
    test('tres corcheas de tresillo ocupan un pulso, parejas', () {
      const tab = [
        TabNote(1, 0, length: tabTripletEighth),
        TabNote(1, 1, length: tabTripletEighth),
        TabNote(1, 3, length: tabTripletEighth),
        TabNote(1, 5, length: tabQuarter),
      ];
      expect(tabLength(tab), 2 * tabQuarter);
      final at = tabOnsetSeconds(tab, bpm: 60);
      expect(at[0], 0);
      expect(at[1], closeTo(1 / 3, 1e-12));
      expect(at[2], closeTo(2 / 3, 1e-12));
      expect(at[3], 1);
      expect(tabTripletGroups(tab), [
        [0, 1, 2],
      ]);
      expect(tabMarksIn(tab), contains(TabMark.triplet));
      expect(tabHasRhythm(tab), isTrue);
    });

    test('semicorcheas de tresillo: seis por pulso; un grupo incompleto no cuenta', () {
      final six = [for (var i = 0; i < 6; i++) const TabNote(2, 5, length: tabTripletSixteenth)];
      expect(tabLength(six), tabQuarter);
      expect(tabTripletGroups(six), [
        [0, 1, 2],
        [3, 4, 5],
      ]);
      expect(
        tabTripletGroups(const [TabNote(1, 0, length: tabTripletEighth), TabNote(1, 1)]),
        isEmpty,
      );
    });
  });

  group('escritura', () {
    test('una tablatura bien escrita no tiene problemas', () {
      const tab = [
        TabNote(3, 5, pick: PickStroke.down),
        TabNote(3, 7, technique: TabTechnique.hammerOn),
        TabNote(3, 5, technique: TabTechnique.pullOff),
        TabNote(2, 8, technique: TabTechnique.bend, bend: 2),
        TabNote(2, 8, technique: TabTechnique.release),
        TabNote(2, 5, technique: TabTechnique.slide),
        TabNote(6, 0, technique: TabTechnique.palmMute),
        TabNote(6, 0, technique: TabTechnique.dead),
        TabNote.rest(tabEighth),
        TabNote(1, 5, technique: TabTechnique.vibrato, length: tabQuarter),
      ];
      expect(tabNotationProblems(tab), isEmpty);
      // Todas menos el tresillo (va en el grupo de tresillos).
      expect(tabMarksIn(tab), TabMark.values.toSet()..remove(TabMark.triplet));
    });

    test('cada técnica exige lo suyo de la nota anterior', () {
      expect(tabNotationProblems(const [TabNote(3, 5), TabNote(3, 4, technique: TabTechnique.hammerOn)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 5), TabNote(3, 7, technique: TabTechnique.pullOff)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 5), TabNote(2, 7, technique: TabTechnique.hammerOn)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 0), TabNote(3, 2, technique: TabTechnique.slide)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 5), TabNote(3, 5, technique: TabTechnique.release)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote.rest(tabEighth), TabNote(3, 7, technique: TabTechnique.hammerOn)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 0, technique: TabTechnique.bend, bend: 1)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 5, bend: 1)]), hasLength(1));
      expect(tabNotationProblems(const [TabNote(3, 5), TabNote(3, 7, technique: TabTechnique.hammerOn, pick: PickStroke.up)]), hasLength(1));
    });
  });

  group('lo que suena', () {
    test('ligados: una sola cuerda pulsada que cambia de altura en su tiempo', () {
      const tab = [
        TabNote(3, 5),
        TabNote(3, 7, technique: TabTechnique.hammerOn),
        TabNote(3, 5, technique: TabTechnique.pullOff),
      ];
      final sounds = tabSounds(tab, bpm: 60);
      expect(sounds, hasLength(1));
      expect(sounds.single.midi, 60);
      expect([for (final g in sounds.single.glides) (g.at, g.midi, g.excite)], [(0.5, 62.0, true), (1.0, 60.0, true)]);
      expect(sounds.single.midiAt(0.7), 62);
      expect(sounds.single.midiAt(1.2), 60);
    });

    test('un slide llega a su traste justo a tiempo', () {
      final s = tabSounds(const [TabNote(3, 5), TabNote(3, 7, technique: TabTechnique.slide)], bpm: 60).single;
      expect(s.midiAt(0.5 - slideSeconds), 60);
      expect(s.midiAt(0.5 - slideSeconds / 2), closeTo(61, 1e-9));
      expect(s.midiAt(0.5), 62);
    });

    test('bend y release: sube los semitonos pedidos y vuelve, sin otra púa', () {
      final s = tabSounds(
        const [
          TabNote(2, 8, technique: TabTechnique.bend, bend: 2, length: tabQuarter),
          TabNote(2, 8, technique: TabTechnique.release),
        ],
        bpm: 60,
      ).single;
      expect(s.midiAt(0.01), 67);
      expect(s.midiAt(bendDelaySeconds + bendSeconds), 69);
      expect(s.midiAt(1 + bendSeconds), 67);
    });

    test('volver a pulsar una cuerda apaga lo que sonaba en ella; otra cuerda sigue', () {
      final sounds = tabSounds(const [TabNote(3, 5), TabNote(2, 5), TabNote(3, 7)], bpm: 60);
      expect(sounds[0].seconds, 1.0);
      expect(sounds[1].seconds, tabNoteRingSeconds);
    });

    test('un silencio no suena y corre lo que sigue', () {
      final sounds = tabSounds(const [TabNote(1, 0), TabNote.rest(tabQuarter), TabNote(1, 1)], bpm: 60);
      expect([for (final s in sounds) s.at], [0, 1.5]);
    });

    test('el bend sintetizado llega a la nota de arriba (a menos de 5 cents)', () {
      final s = tabSounds(const [TabNote(2, 8, technique: TabTechnique.bend, bend: 2, length: tabHalf)], bpm: 60);
      final audio = renderStrings(s, seconds: 1.5);
      expect(_cents(_hzAt(audio, 0.6), 69).abs(), lessThan(5));
    });

    test('el hammer-on sintetizado suena a su traste sin volver a pulsar', () {
      final s = tabSounds(
        const [TabNote(3, 5, length: tabQuarter), TabNote(3, 7, technique: TabTechnique.hammerOn, length: tabQuarter)],
        bpm: 60,
      );
      final audio = renderStrings(s, seconds: 1.8);
      expect(_cents(_hzAt(audio, 0.3), 60).abs(), lessThan(5));
      expect(_cents(_hzAt(audio, 1.3), 62).abs(), lessThan(5));
    });

    test('con la palma la nota se apaga mucho antes; la nota muerta es solo un golpe', () {
      Float64List one(TabTechnique t) => renderStrings(
        tabSounds([TabNote(5, 2, technique: t, length: tabHalf)], bpm: 60),
        seconds: 1,
      );
      final open = one(TabTechnique.none);
      final muted = one(TabTechnique.palmMute);
      expect(_rms(muted, 0.25, 0.3), lessThan(_rms(open, 0.25, 0.3) * 0.2));
      final dead = tabSounds(const [TabNote(5, 2, technique: TabTechnique.dead)], bpm: 60).single;
      expect(dead.touch, StringTouch.dead);
      expect(dead.seconds, lessThan(0.2));
    });
  });

  group('micrófono', () {
    HeardNote heard(int midi, double at, {bool plucked = true}) => (midi: midi, at: at, plucked: plucked);

    test('silencios y notas muertas no se esperan; la posición es la de la tablatura', () {
      final f = NoteFollower(const [
        TabNote(3, 0),
        TabNote.rest(tabEighth),
        TabNote(6, 0, technique: TabTechnique.dead),
        TabNote(3, 2),
      ]);
      expect(f.expected, [55, 57]);
      expect(f.position, 0);
      f.hear(heard(55, 0));
      expect(f.position, 3);
      f.hear(heard(57, 1.5));
      expect(f.done, isTrue);
      expect(f.position, 4);
    });

    test('un ligado sale sin ataque; la nota empujada no es error', () {
      final f = NoteFollower(const [
        TabNote(2, 8, technique: TabTechnique.bend, bend: 2),
        TabNote(3, 5),
        TabNote(3, 7, technique: TabTechnique.hammerOn),
      ]);
      expect(f.hear(heard(67, 0)), HeardKind.right);
      expect(f.hear(heard(69, 0.1, plucked: false)), HeardKind.echo);
      expect(f.hear(heard(60, 0.5)), HeardKind.right);
      expect(f.hear(heard(62, 1, plucked: false)), HeardKind.right);
      expect(f.mistakes, 0);
    });

    test('el tempo se mide por los pulsos de cada nota, no por notas iguales', () {
      // Negra, negra, corchea, corchea a 60: notas en 0, 1, 2 y 2.5 s.
      final f = NoteFollower(const [
        TabNote(3, 0, length: tabQuarter),
        TabNote(3, 2, length: tabQuarter),
        TabNote(3, 4),
        TabNote(3, 5),
      ]);
      for (final (midi, at) in const <(int, double)>[(55, 0), (57, 1), (59, 2), (60, 2.5)]) {
        f.hear(heard(midi, at));
      }
      expect(f.result.bpm, closeTo(60, 1e-9));
      expect(f.result.paused, isFalse);
    });
  });
}
