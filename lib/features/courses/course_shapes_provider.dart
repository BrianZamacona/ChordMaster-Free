import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/open_chords/chord_shape.dart';
import '../chords/chord_viewmodel.dart';

/// Las digitaciones principales de `chords.json` de los acordes [names], por
/// nombre; `null` mientras se cargan los acordes.
final courseChordShapesProvider =
    Provider.family<Map<String, ChordShape>?, List<String>>((ref, names) {
      ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
      final vm = ref.read(chordViewModelProvider.notifier);
      final shapes = <String, ChordShape>{};
      for (final name in names) {
        final chord = vm.findByName(name);
        if (chord == null) return null;
        shapes[name] = ChordShape(
          name: name,
          frets: chord.fretPositions,
          fingers: chord.fingerPositions,
        );
      }
      return shapes;
    });
