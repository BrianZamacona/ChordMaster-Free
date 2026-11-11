import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/licks/lick.dart';
import '../../domain/licks/lick_backing.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../../domain/practice/tab_playback.dart';
import '../../domain/theory/notes.dart';
import '../../models/chord.dart';
import '../../services/audio_service.dart';
import '../../ui/section_routes.dart';
import '../chords/chord_viewmodel.dart';

/// Nombre en chords.json del acorde [c] con raíz [root] (`Am7`, `E5`…).
String lickChordName(int root, LickChord c) => chordDisplayName(root: pitchClassName(root), type: c.type);

/// El acorde que entra en cada nota de [tab] (índice → nombre), para
/// escribirlo encima de la tablatura. [root] es la tónica en la que suena.
Map<int, String> lickChordLabels(Lick lick, List<TabNote> tab, int root) {
  final positions = tabPositions(tab);
  return {
    for (final c in lick.chordsIn(root))
      if (positions.indexOf(c.start) case final i when i >= 0) i: lickChordName(c.root, c.chord),
  };
}

/// Los golpes del acompañamiento de [lick] en la tónica [root], con las
/// digitaciones de chords.json; `null` si alguna todavía no está (se lee en
/// otro hilo).
List<BackingStroke>? lickBackingStrokes(Lick lick, int root, ChordViewModel library) {
  final chords = [
    for (final c in lick.chordsIn(root)) library.findByName(lickChordName(c.root, c.chord)),
  ];
  if (chords.contains(null)) return null;
  final shapes = [
    for (final c in chords.cast<Chord>())
      ChordShape(name: c.name, frets: c.fretPositions, fingers: c.fingerPositions),
  ];
  return [
    for (final s in lick.chordStrokes) (shape: shapes[s.chord], position: (s.beat * tabQuarter).round()),
  ];
}

/// La parte rítmica de una frase: los acordes que suenan debajo, con su
/// diagrama de chords.json (tocar uno abre su ficha) y ▶ para oírlos
/// rasgueados al tempo de la frase.
class LickRhythmPart extends ConsumerWidget {
  const LickRhythmPart({super.key, required this.lick, required this.root, required this.bpm});

  final Lick lick;
  final int root;
  final int bpm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se mira el estado para redibujar cuando termina de leerse chords.json.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final library = ref.read(chordViewModelProvider.notifier);
    final chords = [
      for (final c in lick.chordsIn(root)) library.findByName(lickChordName(c.root, c.chord)),
    ];
    final distinct = {for (final c in chords) ?c}.toList();
    final text = Theme.of(context).textTheme;
    return Card(
      key: const Key('lick-rhythm'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.licksRhythmPart, style: text.titleSmall),
            const SizedBox(height: 4),
            Text(AppStrings.licksRhythmHint, style: text.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in distinct)
                  InkWell(
                    key: Key('lick-chord-${c.name}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.push(context.sectionPath('chords/${Uri.encodeComponent(c.name)}')),
                    child: ChordDiagramWidget(
                      chordName: chordDisplayName(root: c.root, type: c.type, explicitDisplayName: c.displayName),
                      fretPositions: c.fretPositions,
                      fingerPositions: c.fingerPositions,
                      baseFret: c.baseFret,
                      root: c.root,
                      size: 96,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('lick-rhythm-play'),
              onPressed: chords.contains(null) ? null : () => _play(ref, chords.cast<Chord>()),
              icon: const Icon(Icons.play_arrow),
              label: Text(AppStrings.licksRhythmPlay),
            ),
          ],
        ),
      ),
    );
  }

  /// Un golpe al entrar cada acorde y en cada pulso mientras dura.
  Future<void> _play(WidgetRef ref, List<Chord> chords) {
    final shapes = [
      for (final c in chords) ChordShape(name: c.name, frets: c.fretPositions, fingers: c.fingerPositions),
    ];
    final strokes = [for (final s in lick.chordStrokes) (shape: shapes[s.chord], beat: s.beat)];
    final beats = tabLength(lick.tab) / tabQuarter;
    return ref.read(audioServiceProvider).playTab(
      strumStrokes(strokes, bpm: bpm),
      seconds: beats * 60 / bpm + 0.3,
    );
  }
}
