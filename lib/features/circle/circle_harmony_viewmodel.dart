import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/chord_metadata.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../../domain/theory/circle_harmony.dart';
import '../../domain/theory/notes.dart';
import '../../services/audio_service.dart';
import '../chords/chord_viewmodel.dart';

/// Tempo al que suenan los acordes de esta pantalla: dos pulsos cada uno.
const circleHarmonyBpm = 90;
const circleHarmonyBeats = 2;

/// La tonalidad a la que se modula (`null` = la dominante de la elegida).
final modulationTargetProvider = NotifierProvider<ModulationTarget, int?>(ModulationTarget.new);

class ModulationTarget extends Notifier<int?> {
  @override
  int? build() => null;

  // ignore: use_setters_to_change_properties, el chip la pasa como callback.
  void choose(int? tonic) => state = tonic;
}

/// Nombre del acorde en chords.json (`A7`, `Dm7`, `Cmaj7`…).
String circleChordName(CircleChord c) => chordDisplayName(root: pitchClassName(c.root), type: c.type);

/// Hace sonar [chords] uno detrás de otro, rasgueados, con las digitaciones
/// de chords.json. Los que no están en la biblioteca se saltan.
Future<void> playCircleChords(WidgetRef ref, List<CircleChord> chords) {
  final library = ref.read(chordViewModelProvider.notifier);
  final shapes = [
    for (final c in chords)
      if (library.findByName(circleChordName(c)) case final data?)
        ChordShape(name: data.name, frets: data.fretPositions, fingers: data.fingerPositions),
  ];
  if (shapes.isEmpty) return Future.value();
  return ref.read(audioServiceProvider).playTab(
    strumEvents(shapes, bpm: circleHarmonyBpm, beatsPerSlot: circleHarmonyBeats),
    seconds: strumDurationSeconds(shapes.length, bpm: circleHarmonyBpm, beatsPerSlot: circleHarmonyBeats),
  );
}
