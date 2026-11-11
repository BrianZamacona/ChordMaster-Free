/// Cómo suena una progresión en Progresiones: un compás por acorde, un golpe
/// hacia abajo por pulso, al tempo elegido y, si se pide, en bucle (el archivo
/// se repite solo, como el metrónomo: el tiempo no lo marca un temporizador).
library;

import '../audio/pluck_synth.dart';
import '../open_chords/chord_shape.dart';
import '../practice/technique_exercises.dart';

/// Pulsos que dura cada acorde: un compás de 4/4.
const progressionBeatsPerChord = 4;

/// Tempo con el que se empieza.
const progressionDefaultBpm = 80;

/// [bpm] llevado al paso de 5 y dentro de los límites de tempo de la app.
int progressionTempo(int bpm) =>
    ((bpm / techniqueBpmStep).round() * techniqueBpmStep).clamp(techniqueMinBpm, techniqueMaxBpm);

/// Los golpes de [shapes], uno tras otro.
List<StringSound> progressionStrum(List<ChordShape> shapes, {required int bpm}) =>
    strumEvents(shapes, bpm: bpm, beatsPerSlot: progressionBeatsPerChord);

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
