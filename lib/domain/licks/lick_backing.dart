/// El acompañamiento debajo de una frase: sus acordes de fondo rasgueados
/// (un golpe al entrar cada acorde y en cada pulso, `Lick.chordStrokes`), más
/// bajos que la frase para que se oiga lo que se toca encima.
library;

import '../audio/pluck_synth.dart';
import '../lessons/lesson.dart';
import '../open_chords/chord_shape.dart';
import '../practice/tab_playback.dart';

/// Volumen del acompañamiento frente a la frase (1 = igual).
const lickBackingGain = 0.4;

/// Un golpe del acompañamiento: la forma y la parte de pulso en que cae,
/// contada desde el principio de la frase.
typedef BackingStroke = ({ChordShape shape, int position});

/// Los golpes de [strokes] que caen en el tramo [from]–[to] (partes de
/// pulso), con el tiempo contado desde [from] como la frase (también con
/// swing) y con volumen [lickBackingGain].
List<StringSound> lickBacking(
  List<BackingStroke> strokes, {
  required int from,
  required int to,
  required int bpm,
  TabSwing swing = TabSwing.none,
}) {
  final start = tabSwungBeats(from, swing);
  final sounds = strumStrokes([
    for (final s in strokes)
      if (s.position >= from && s.position < to) (shape: s.shape, beat: tabSwungBeats(s.position, swing) - start),
  ], bpm: bpm);
  return [for (final s in sounds) s.withGain(lickBackingGain)];
}
