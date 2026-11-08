import 'dart:async';
import 'dart:typed_data';

import 'package:chordmaster_free/core/errors/failures.dart';
import 'package:chordmaster_free/domain/audio/pitch_detection.dart';
import 'package:chordmaster_free/domain/audio/pluck_synth.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/practice/tab_playback.dart';
import 'package:chordmaster_free/services/audio_service.dart';
import 'package:chordmaster_free/services/pitch_service.dart';

/// Dobles para tocar con el micrófono en tests de pantalla: un audio que
/// anota lo que se pidió sonar, un micrófono cuyas ventanas pone el test y
/// las ventanas de una tablatura sintetizada.
class FakeAudio extends AudioService {
  FakeAudio() : super.forTesting();

  int stops = 0;
  final played = <List<NoteEvent>>[];

  @override
  Future<void> playNotes(List<NoteEvent> events, {double seconds = 2.5, double? ring}) async =>
      played.add(events);

  @override
  Future<void> stopAll() async => stops++;
}

/// Un micrófono de mentira: las ventanas las pone el test.
class FakeMic extends PitchService {
  FakeMic({this.deny = false}) : super.forTesting();

  final bool deny;
  bool listening = false;
  // Lo cierra cada test con addTearDown.
  // ignore: close_sinks
  final windows = StreamController<MicWindow>.broadcast();

  @override
  Stream<MicWindow> get windowStream => windows.stream;

  @override
  Future<void> startListening() async {
    if (deny) throw const PermissionFailure(message: 'denied');
    listening = true;
  }

  @override
  Future<void> stopListening() async => listening = false;
}

/// Las ventanas que daría el micrófono con [tab] tocada a [bpm] (cada nota se
/// corta con la siguiente), como las arma [PitchService].
List<MicWindow> micWindows(List<TabNote> tab, int bpm) {
  final step = tabStepSeconds(bpm);
  final audio = renderNotes(
    [for (final (i, n) in tab.indexed) (midi: tabMidi(n), at: 0.3 + i * step)],
    seconds: 0.3 + tab.length * step + 0.6,
    ring: step,
  );
  final half = decimateByTwo(audio);
  const size = 2048;
  return [
    for (var start = 0; start + size <= half.length; start += PitchService.hop)
      (
        samples: Float64List.sublistView(half, start, start + size),
        at: (start + size) / PitchService.sampleRate,
      ),
  ];
}
