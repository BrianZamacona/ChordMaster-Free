import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/theory/caged_anchor.dart';
import '../../domain/theory/notes.dart';
import '../../models/chord.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';

/// «CAGED desde el ancla»: en cinco pasos, la tónica en la 6ª, la 5ª y la 4ª
/// cuerda y cada forma mayor armada desde su ancla. Los trastes salen por regla
/// (`caged_anchor.dart`) y las formas, de chords.json.
class CagedAnchorScreen extends ConsumerStatefulWidget {
  const CagedAnchorScreen({super.key});

  @override
  ConsumerState<CagedAnchorScreen> createState() => _CagedAnchorScreenState();
}

class _CagedAnchorScreenState extends ConsumerState<CagedAnchorScreen> {
  var _root = 0;
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    // Se mira el estado para redibujar cuando termina de leerse chords.json.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final chord = ref.read(chordViewModelProvider.notifier).findByName(pitchClassName(_root));
    final step = CagedAnchorStep.values[_step];
    final key = pitchClassName(_root);
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final last = CagedAnchorStep.values.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubCaged)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SelectorPill(
              key: const Key('caged-key'),
              label: AppStrings.capoKey,
              value: key,
              onOpen: () => showNotePicker(
                context,
                title: AppStrings.capoKey,
                selected: key,
                onPicked: (note) {
                  if (note != null) setState(() => _root = noteIndex(note));
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.cagedStepOf(_step + 1, last + 1),
            key: const Key('caged-step'),
            style: text.labelLarge?.copyWith(color: p.accent),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.cagedStepTitle(_step), style: text.titleLarge),
          const SizedBox(height: 8),
          Text(
            AppStrings.cagedStepBody(
              _step,
              key: key,
              six: anchorFret(6, _root),
              five: anchorFret(5, _root),
              four: anchorFret(4, _root),
            ),
            key: const Key('caged-body'),
            style: text.bodyLarge,
          ),
          for (final shape in shapesOf(step)) ...[
            const SizedBox(height: 16),
            _ShapeCard(shape: shape, root: _root, chord: chord),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (_step > 0)
                OutlinedButton.icon(
                  key: const Key('caged-prev'),
                  onPressed: () => setState(() => _step--),
                  icon: const Icon(Icons.chevron_left),
                  label: Text(AppStrings.cagedPrevious),
                ),
              const Spacer(),
              if (_step < last)
                FilledButton.icon(
                  key: const Key('caged-next'),
                  onPressed: () => setState(() => _step++),
                  icon: const Icon(Icons.chevron_right),
                  label: Text(AppStrings.cagedNext),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una forma: su diagrama de chords.json y dónde cae su raíz.
class _ShapeCard extends StatelessWidget {
  const _ShapeCard({required this.shape, required this.root, required this.chord});

  final String shape;
  final int root;
  final Chord? chord;

  @override
  Widget build(BuildContext context) {
    final position = chord?.cagedPositions.where((c) => c.shape == shape).firstOrNull;
    final text = Theme.of(context).textTheme;
    final anchor = position == null ? null : shapeAnchorFret(shape, position.fretPositions, root);
    return Card(
      key: Key('caged-shape-$shape'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.cagedShapeName(shape), style: text.titleMedium),
            if (position != null && anchor != null) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.cagedShapeAnchor(
                  string: cagedAnchorString[shape]!,
                  fret: anchor,
                  up: shapeGoesUp(position.fretPositions, anchor),
                ),
                key: Key('caged-shape-$shape-text'),
                style: text.bodyMedium,
              ),
              const SizedBox(height: 8),
              Center(
                child: ChordDiagramWidget(
                  chordName: '${pitchClassName(root)} · $shape',
                  fretPositions: position.fretPositions,
                  fingerPositions: position.fingerPositions,
                  baseFret: position.baseFret,
                  root: pitchClassName(root),
                  size: 160,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
