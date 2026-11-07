import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/chord_diagram.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../chords/chord_viewmodel.dart';

/// Los diagramas de [shapes] en fila (enteros o a medio armar), con los
/// colores de intervalo de su acorde.
class ChordShapeDiagrams extends ConsumerWidget {
  const ChordShapeDiagrams({super.key, required this.shapes, this.size = 120});

  final List<ChordShape> shapes;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(chordViewModelProvider.notifier);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        for (final (i, shape) in shapes.indexed)
          ChordDiagramWidget(
            key: Key('course-diagram-$i'),
            chordName: shape.name,
            fretPositions: shape.frets,
            fingerPositions: shape.fingers,
            root: vm.findByName(shape.name)?.root,
            size: size,
          ),
      ],
    );
  }
}
