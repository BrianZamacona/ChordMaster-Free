import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chordmaster_free/domain/audio/note_onsets.dart';
import 'package:chordmaster_free/domain/audio/pitch_detection.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/melodies/basics_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/practice/play_along.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:flutter_test/flutter_test.dart';

const _rate = synthSampleRate ~/ 2;
const _window = 2048;
const _hop = 1024;
const _lead = 0.3;

/// [tab] tocada a [bpm] (corcheas) como en la guitarra: cada nota suena hasta
/// que se pulsa otra en su misma cuerda o, con [ring] = null, hasta la nota
/// siguiente (dedos que se levantan y apagan la cuerda).
Float64List _played(List<TabNote> tab, int bpm, {double? ring}) {
  final step = tabStepSeconds(bpm);
  final total = ((_lead + tab.length * step + 0.6) * synthSampleRate).round();
  final mix = Float64List(total);
  for (final (i, n) in tab.indexed) {
    final at = _lead + i * step;
    final nextSame = tab.indexed.skip(i + 1).where((e) => e.$2.string == n.string).firstOrNull;
    var end = ring == null ? at + step : at + ring;
    if (nextSame != null) end = math.min(end, _lead + nextSame.$1 * step);
    final start = (at * synthSampleRate).round();
    final note = pluck(midiToHz(tabMidi(n)), end - at, seed: i + 1);
    for (var t = 0; t < note.length && start + t < total; t++) {
      mix[start + t] += note[t] * 0.45;
    }
  }
  return mix;
}

/// [tab] como suena en la app ([tabSounds]: rasgueada, con la palma y las
/// cuerdas que siguen sonando) a [bpm], tras [_lead] de silencio.
Float64List _rendered(List<TabNote> tab, int bpm) => Float64List.fromList([
  ...Float64List((synthSampleRate * _lead).round()),
  ...renderStrings(tabSounds(tab, bpm: bpm), seconds: tabDurationSeconds(tab, bpm: bpm)),
]);

/// Lo que hace la pantalla con el micrófono: bajar a 22.05 kHz y pasar una
/// ventana cada [_hop] muestras a la sesión.
PlayAlongSession _listen(List<TabNote> expected, Float64List audio) {
  final session = PlayAlongSession(expected);
  final half = decimateByTwo(audio);
  for (var start = 0; start + _window <= half.length; start += _hop) {
    session.listen(
      Float64List.sublistView(half, start, start + _window),
      _rate,
      at: (start + _window) / _rate,
      hop: _hop,
    );
  }
  return session;
}

void main() {
  final steps = [
    for (final levels in [basicsCourse, melodyCourse])
      for (final s in courseSteps(levels))
        if (s.tab.isNotEmpty) s,
  ];

  group('con el micrófono, sobre cuerdas sintetizadas', () {
    test('cada ejercicio y canción de Primeros pasos y Melodías se sigue entera, '
        'sin errores y midiendo el tempo (60 y 100 BPM)', () {
      expect(steps, isNotEmpty);
      for (final bpm in [60, 100]) {
        for (final s in steps) {
          final f = _listen(s.tab, _played(s.tab, bpm)).follower;
          final why = '${s.id} a $bpm BPM';
          expect(f.done, isTrue, reason: '$why: se quedó en la nota ${f.position}');
          expect(f.mistakes, 0, reason: why);
          final r = f.result;
          expect(r.bpm, closeTo(bpm, bpm * 0.03), reason: why);
          expect(r.paused, isFalse, reason: why);
          expect(r.cleanBpm, isNotNull, reason: why);
        }
      }
    });

    test('con las cuerdas sonando (hasta la siguiente nota en la misma cuerda), '
        'casi todos salen limpios', () {
      final failed = [
        for (final s in steps)
          if (_listen(s.tab, _played(s.tab, 80, ring: tabNoteRingSeconds)).follower
              case final f when !f.done || f.mistakes > 0)
            s.id,
      ];
      // El límite conocido: varias cuerdas al aire graves sonando al mismo
      // nivel tapan la nota nueva (b_open toca las seis al aire seguidas).
      expect(failed.length, lessThanOrEqualTo(steps.length ~/ 10), reason: '$failed');
    });

    test('las notas con palma, sueltas y en acorde, se siguen enteras, sin errores '
        '(70 y 110 BPM)', () {
      // Se apagan antes de que el ataque termine y, en classic_riff, bajo la
      // 4ª cuerda que sigue sonando.
      for (final id in ['punk_riff', 'stadium_riff', 'classic_riff', 'punk_power_riff', 'gypsy_pompe_riff']) {
        final tab = licksById[id]!.tab;
        expect(tab.where((n) => n.technique == TabTechnique.palmMute), isNotEmpty, reason: id);
        for (final bpm in [70, 110]) {
          final f = _listen(tab, _rendered(tab, bpm)).follower;
          final why = '$id a $bpm BPM';
          expect(f.done, isTrue, reason: '$why: se quedó en la nota ${f.position}');
          expect(f.mistakes, 0, reason: why);
          expect(f.result.bpm, closeTo(bpm, bpm * 0.03), reason: why);
        }
      }
    });

    test('una nota con palma equivocada no se da por buena', () {
      // classic_riff: A2 con palma mientras suena el E3 de la 4ª cuerda.
      final tab = licksById['classic_riff']!.tab.take(4).toList();
      for (final (string, fret) in [(6, 0), (6, 1), (5, 3)]) {
        final wrong = TabNote(string, fret, technique: TabTechnique.palmMute, pick: PickStroke.down);
        final f = _listen(tab, _rendered([...tab.take(3), wrong], 90)).follower;
        expect(f.position, 3, reason: '$string/$fret');
        expect(f.done, isFalse, reason: '$string/$fret');
      }
    });

    test('power chords: tocar solo la quinta no da el acorde por bueno', () {
      final tab = licksById['punk_power_riff']!.tab;
      final wrong = renderStrings(
        tabSounds(const [TabNote(5, 2, length: tabHalf)], bpm: 60),
        seconds: 2,
      );
      expect(_listen(tab.take(1).toList(), wrong).follower.done, isFalse);
    });

    test('una nota equivocada cuenta como error y se sigue esperando la correcta', () {
      final tab = steps.firstWhere((s) => s.id == 'mm_mary').tab;
      final wrong = TabNote(tab[3].string, tab[3].fret + 1);
      final f = _listen(tab, _played([...tab.take(3), wrong, ...tab.skip(3)], 80)).follower;
      expect(f.done, isTrue);
      expect(f.mistakes, 1);
      expect(f.result.clean, isFalse);
    });

    test('si falta una nota, se queda esperándola', () {
      final tab = steps.firstWhere((s) => s.id == 'b_mid_ladder').tab;
      final f = _listen(tab, _played([...tab.take(4), ...tab.skip(5)], 80)).follower;
      expect(f.position, 4);
      expect(f.done, isFalse);
    });

    test('la misma nota pulsada dos veces cuenta dos veces', () {
      const g = TabNote(3, 0);
      final f = _listen(const [g, g, g, g], _played(const [g, g, g, g], 90)).follower;
      expect(f.done, isTrue);
      expect(f.mistakes, 0);
    });

    test('silencio y ruido: no se oye ninguna nota', () {
      const tab = [TabNote(1, 0), TabNote(2, 1)];
      final rng = math.Random(3);
      final noise = Float64List.fromList([
        for (var i = 0; i < synthSampleRate; i++) (rng.nextDouble() * 2 - 1) * 0.05,
      ]);
      for (final audio in [Float64List(synthSampleRate), noise]) {
        final f = _listen(tab, audio).follower;
        expect(f.position, 0);
        expect(f.mistakes, 0);
      }
    });

    test('el retraso del micrófono no cambia el tempo medido', () {
      final tab = steps.firstWhere((s) => s.id == 'mu_ladder').tab;
      final audio = _played(tab, 80);
      final late = Float64List(audio.length + 4410)..setRange(4410, audio.length + 4410, audio);
      expect(
        _listen(tab, late).follower.result.bpm,
        closeTo(_listen(tab, audio).follower.result.bpm!, 0.5),
      );
    });
  });

  group('NoteFollower', () {
    const tab = [TabNote(3, 0), TabNote(3, 2), TabNote(3, 4)];
    HeardNote note(int midi, double at, {bool plucked = true}) =>
        (midi: midi, at: at, plucked: plucked);

    test('avanza con la nota esperada; la anterior otra vez es eco', () {
      final f = NoteFollower(tab);
      expect(f.expected, [55, 57, 59]);
      expect(f.hear(note(55, 0)), HeardKind.right);
      expect(f.hear(note(55, 0.1)), HeardKind.echo);
      expect(f.hear(note(58, 0.2)), HeardKind.wrong);
      expect(f.hear(note(57, 0.3)), HeardKind.right);
      expect(f.position, 2);
      expect(f.mistakes, 1);
    });

    test('una nota sin ataque (cuerdas que siguen sonando) no es error', () {
      final f = NoteFollower(tab)..hear(note(55, 0));
      expect(f.hear(note(62, 0.1, plucked: false)), HeardKind.echo);
      expect(f.mistakes, 0);
    });

    test('terminada, lo demás se ignora', () {
      final f = NoteFollower(tab)
        ..hear(note(55, 0))
        ..hear(note(57, 0.3))
        ..hear(note(59, 0.6));
      expect(f.done, isTrue);
      expect(f.hear(note(40, 1)), HeardKind.ignored);
    });
  });

  group('PlayAlongResult', () {
    test('tempo por la distancia típica entre notas (corcheas)', () {
      // 0.375 s entre corcheas = 80 BPM.
      final r = PlayAlongResult.from([0, 0.375, 0.75, 1.125, 1.5]);
      expect(r.bpm, closeTo(80, 1e-9));
      expect(r.clean, isTrue);
      expect(r.cleanBpm, 80);
    });

    test('el récord se redondea hacia abajo al paso del tempo', () {
      final r = PlayAlongResult.from([0, 0.37, 0.74, 1.11]);
      expect(r.bpm, closeTo(81.1, 0.1));
      expect(r.cleanBpm, 80);
    });

    test('con errores, con una pausa larga o con una sola nota no es limpia', () {
      expect(PlayAlongResult.from([0, 0.375, 0.75], mistakesAt: [1]).cleanBpm, isNull);
      final paused = PlayAlongResult.from([0, 0.375, 0.75, 2.5, 2.875]);
      expect(paused.paused, isTrue);
      expect(paused.cleanBpm, isNull);
      expect(PlayAlongResult.from([0]).bpm, isNull);
    });

    test('con el margen de la medida, 99.6 BPM cuenta como 100', () {
      // 0.3012 s entre corcheas = 99.6 BPM.
      final r = PlayAlongResult.from([0, 0.3012, 0.6024, 0.9036]);
      expect(r.bpm, closeTo(99.6, 0.05));
      expect(r.cleanBpm, 100);
    });

    test('más lenta que el mínimo del selector: sin récord', () {
      expect(PlayAlongResult.from([0, 1, 2, 3]).cleanBpm, isNull);
    });
  });

  group('señales', () {
    test('periodicityAt: la nota que suena da casi 0; otra, casi 1', () {
      final half = decimateByTwo(pluck(midiToHz(57), 0.5));
      final w = Float64List.sublistView(half, 3000, 3000 + _window);
      expect(periodicityAt(w, _rate, midiToHz(57)), lessThan(0.1));
      expect(periodicityAt(w, _rate, midiToHz(60)), greaterThan(0.8));
    });

    test('withoutPeriod: quita la cuerda que suena y deja clara la nota de abajo', () {
      final loud = pluck(midiToHz(52), 0.5);
      final quiet = pluck(midiToHz(45), 0.5, seed: 2);
      final mix = decimateByTwo(Float64List.fromList([
        for (var i = 0; i < loud.length; i++) loud[i] + 0.15 * quiet[i],
      ]));
      final w = Float64List.sublistView(mix, 3000, 3000 + _window);
      final a2 = midiToHz(45);
      expect(periodicityAt(w, _rate, a2), greaterThan(0.3));
      expect(periodicityAt(withoutPeriod(w, _rate, midiToHz(52)), _rate, a2), lessThan(0.1));
    });

    test('una nota con palma tras un silencio se oye, aunque se apague durante el ataque', () {
      const note = TabNote(6, 0, technique: TabTechnique.palmMute);
      final half = decimateByTwo(_rendered(const [note], 70));
      final detector = NoteOnsetDetector();
      final heard = <HeardNote>[];
      for (var start = 0; start + _window <= half.length; start += _hop) {
        final frame = analyzeFrame(
          Float64List.sublistView(half, start, start + _window),
          _rate,
          at: (start + _window) / _rate,
          hop: _hop,
          expectedMidi: 40,
        );
        if (detector.feed(frame, expected: 40) case final n?) heard.add(n);
      }
      expect(heard.map((n) => (n.midi, n.plucked)), [(40, true)]);
      expect(heard.single.at, closeTo(_lead, 0.05));
    });

    test('attackLevelOf: el ataque es más agudo que lo que sigue sonando', () {
      final half = decimateByTwo(pluck(midiToHz(45), 0.6));
      final attack = attackLevelOf(Float64List.sublistView(half, 0, _hop));
      final later = attackLevelOf(Float64List.sublistView(half, 4000, 4000 + _hop));
      expect(attack / later, greaterThan(2));
    });
  });

  group('repetir un renglón y más lento', () {
    test('renglones de 8 notas', () {
      expect(tabLineCount(0), 0);
      expect(tabLineCount(8), 1);
      expect(tabLineCount(9), 2);
      expect(tabLineOf(7), 0);
      expect(tabLineOf(8), 1);
      expect(tabLineRange(20, 0), (start: 0, end: 8));
      expect(tabLineRange(20, 2), (start: 16, end: 20));
    });

    test('el seguidor anota dónde fue cada error', () {
      const tab = [TabNote(3, 0), TabNote(3, 2), TabNote(3, 4)];
      final f = NoteFollower(tab)
        ..hear((midi: 55, at: 0, plucked: true))
        ..hear((midi: 58, at: 0.2, plucked: true))
        ..hear((midi: 60, at: 0.3, plucked: true))
        ..hear((midi: 57, at: 0.4, plucked: true));
      expect(f.mistakes, 2);
      expect(f.result.mistakesAt, [1, 1]);
    });

    test('se repite el renglón con más errores; si empatan, el primero', () {
      const times = [0.0, 0.375, 0.75];
      expect(PlayAlongResult.from(times, mistakesAt: [3, 9, 10]).lineToPractice, 1);
      expect(PlayAlongResult.from(times, mistakesAt: [9, 2]).lineToPractice, 0);
    });

    test('sin errores, el renglón de la pausa; limpia, ninguno', () {
      final times = [for (var i = 0; i < 12; i++) i * 0.375]..[10] += 3;
      for (var i = 11; i < 12; i++) {
        times[i] += 3;
      }
      final paused = PlayAlongResult.from(times);
      expect(paused.pauseAt, 10);
      expect(paused.lineToPractice, 1);
      expect(PlayAlongResult.from([0, 0.375, 0.75]).lineToPractice, isNull);
    });

    test('más lento baja 10 BPM sin pasar del mínimo', () {
      expect(slowerBpm(80), 70);
      expect(slowerBpm(45), techniqueMinBpm);
    });
  });
}