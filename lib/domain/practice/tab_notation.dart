/// Reglas de escritura de una tablatura: lo que una técnica exige de la nota
/// anterior. Los tests las corren sobre todas las tablaturas de la app.
library;

import '../lessons/lesson.dart';
import 'tab_playback.dart';

/// Lo que está mal escrito en [notes] (vacío = bien). Cada problema dice el
/// índice de la nota.
List<String> tabNotationProblems(List<TabNote> notes) {
  final problems = <String>[];
  TabNote? previous;
  for (final (i, n) in notes.indexed) {
    void fail(String why) => problems.add('$i: $why ($n)');
    if (n.length <= 0) fail('dura ${n.length}');
    if (n.isRest) {
      if (n.technique != TabTechnique.none || n.pick != null) fail('un silencio no se toca');
      previous = null;
      continue;
    }
    if (n.string < 1 || n.string > 6) fail('cuerda fuera de 1–6');
    if (n.fret < 0 || n.fret > 24) fail('traste fuera de 0–24');
    if ((n.technique == TabTechnique.bend) != (n.bend > 0)) {
      fail('solo un bend lleva semitonos');
    }
    if (n.bend > 3) fail('un bend de más de un tono y medio');
    if (n.technique == TabTechnique.bend && n.fret == 0) fail('una cuerda al aire no se empuja');
    if (n.isChord) {
      if (n.chord.length > 2) fail('un acorde de la tablatura tiene 2 o 3 notas');
      if (n.technique != TabTechnique.none && n.technique != TabTechnique.palmMute) {
        fail('un acorde se pulsa, abierto o con palma');
      }
      final strings = {for (final t in n.tones) t.string};
      if (strings.length != n.tones.length) fail('cada nota del acorde en su cuerda');
      for (final (s, f) in n.chord) {
        if (s < 1 || s > 6 || f < 0 || f > 24) fail('nota del acorde fuera del mástil');
      }
      for (final t in n.tones.skip(1)) {
        if (t.string >= 1 && t.string <= 6 && tabMidi(t) <= tabMidi(n)) {
          fail('la nota principal es la más grave del acorde');
        }
      }
    }
    if (n.technique.legato) {
      if (n.pick != null) fail('una nota ligada no lleva púa');
      final p = previous;
      if (p == null || p.string != n.string || p.technique == TabTechnique.dead || p.isChord) {
        fail('se liga a la nota anterior, en la misma cuerda');
      } else {
        switch (n.technique) {
          case TabTechnique.hammerOn when n.fret <= p.fret:
            fail('un hammer-on sube de traste');
          case TabTechnique.pullOff when n.fret >= p.fret:
            fail('un pull-off baja de traste');
          case TabTechnique.slide when n.fret == p.fret || n.fret == 0 || p.fret == 0:
            fail('un slide cambia de traste, sin cuerdas al aire');
          case TabTechnique.release when p.technique != TabTechnique.bend || p.fret != n.fret:
            fail('un release vuelve del bend, en el mismo traste');
          default:
        }
      }
    }
    previous = n;
  }
  return problems;
}

/// Técnicas y marcas que usa [notes], para explicar solo esas.
Set<TabMark> tabMarksIn(List<TabNote> notes) => {
  if (notes.any((n) => isTripletLength(n.length))) TabMark.triplet,
  for (final n in notes)
    if (n.isRest)
      TabMark.rest
    else ...[
      ?_markOf(n),
      if (n.pick != null) TabMark.pick,
      if (n.isChord) TabMark.chord,
    ],
};

TabMark? _markOf(TabNote n) => switch (n.technique) {
  TabTechnique.none => null,
  TabTechnique.hammerOn => TabMark.hammerOn,
  TabTechnique.pullOff => TabMark.pullOff,
  TabTechnique.slide => TabMark.slide,
  TabTechnique.bend => TabMark.bend,
  TabTechnique.release => TabMark.release,
  TabTechnique.vibrato => TabMark.vibrato,
  TabTechnique.palmMute => TabMark.palmMute,
  TabTechnique.dead => TabMark.dead,
};

/// Lo que se explica debajo de una tablatura.
enum TabMark { rest, triplet, chord, hammerOn, pullOff, slide, bend, release, vibrato, palmMute, dead, pick }

/// Grupos de tresillo de [notes]: índices de cada tres notas seguidas con
/// duración de tresillo (un tresillo incompleto no forma grupo).
List<List<int>> tabTripletGroups(List<TabNote> notes) {
  final groups = <List<int>>[];
  var run = <int>[];
  for (final (i, n) in notes.indexed) {
    if (isTripletLength(n.length) && (run.isEmpty || notes[run.first].length == n.length)) {
      run.add(i);
      if (run.length == 3) {
        groups.add(run);
        run = <int>[];
      }
    } else {
      run = isTripletLength(n.length) ? [i] : <int>[];
    }
  }
  return groups;
}

/// La tablatura lleva ritmo propio (no son todas corcheas): se dibuja el
/// conteo debajo.
bool tabHasRhythm(List<TabNote> notes, {TabSwing swing = TabSwing.none}) =>
    swing != TabSwing.none || notes.any((n) => n.isRest || n.length != tabEighth);
