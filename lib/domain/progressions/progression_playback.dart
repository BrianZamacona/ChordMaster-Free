/// Cómo suena una progresión en Progresiones: un compás por acorde, un golpe
/// hacia abajo por pulso, al tempo elegido y, si se pide, en bucle (el archivo
/// se repite solo, como el metrónomo: el tiempo no lo marca un temporizador).
library;

import '../audio/pluck_synth.dart';
import '../open_chords/chord_shape.dart';
import '../practice/technique_exercises.dart';
import 'progression_data.dart';

/// Pulsos que dura cada acorde: un compás de 4/4.
const progressionBeatsPerChord = 4;

/// Tempo con el que se empieza.
const progressionDefaultBpm = 80;

/// [bpm] llevado al paso de 5 y dentro de los límites de tempo de la app.
int progressionTempo(int bpm) =>
    ((bpm / techniqueBpmStep).round() * techniqueBpmStep).clamp(techniqueMinBpm, techniqueMaxBpm);

/// Golpes por pulso: uno, o tres en 12/8.
int strokesPerBeat(ProgressionFeel feel) => feel == ProgressionFeel.triplet ? 3 : 1;

/// Los golpes de [shapes], uno tras otro: con [pattern] (una letra por
/// corchea, los de `strummingPatterns`), ese rasgueo en cada compás; sin él,
/// un golpe hacia abajo por pulso, o tres parejos (como un tresillo) en 12/8.
/// El 12/8 no lleva patrón: sus corcheas son de tresillo.
List<StringSound> progressionStrum(
  List<ChordShape> shapes, {
  required int bpm,
  ProgressionFeel feel = ProgressionFeel.straight,
  String? pattern,
}) {
  if (feel == ProgressionFeel.straight) {
    return strumEvents(
      shapes,
      bpm: bpm,
      beatsPerSlot: progressionBeatsPerChord,
      patterns: pattern == null ? null : List.filled(shapes.length, pattern),
    );
  }
  final per = strokesPerBeat(feel);
  return strumStrokes([
    for (final (i, shape) in shapes.indexed)
      for (var k = 0; k < progressionBeatsPerChord * per; k++)
        (shape: shape, beat: i * progressionBeatsPerChord + k / per),
  ], bpm: bpm);
}

/// Segundos de una vuelta entera de [count] acordes.
double progressionLapSeconds(int count, {required int bpm}) =>
    count * progressionBeatsPerChord * 60 / bpm;

/// Segundos del archivo: en bucle, la vuelta justa (si sobrara, se oiría un
/// hueco al repetir); si no, la vuelta y lo que tarda en apagarse.
double progressionAudioSeconds(int count, {required int bpm, required bool loop}) => loop
    ? progressionLapSeconds(count, bpm: bpm)
    : strumDurationSeconds(count, bpm: bpm, beatsPerSlot: progressionBeatsPerChord);

/// El acorde que suena a los [elapsed] segundos; en bucle se vuelve a empezar,
/// y sin bucle es `null` al terminar la vuelta.
int? progressionChordAt(double elapsed, int count, {required int bpm, required bool loop}) {
  if (count == 0 || elapsed < 0) return null;
  final i = (elapsed / (progressionBeatsPerChord * 60 / bpm)).floor();
  if (loop) return i % count;
  return i < count ? i : null;
}
