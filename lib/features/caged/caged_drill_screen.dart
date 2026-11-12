import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../domain/practice/caged_drill.dart';
import '../../domain/theory/notes.dart';
import '../../domain/theory/scale_arpeggio.dart';
import '../../domain/theory/scale_insights.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/fretboard_diagram.dart';
import '../chords/chord_viewmodel.dart';
import 'caged_drill_viewmodel.dart';

/// Práctica CAGED sorteada: una tónica y una forma al azar y tres fases (la
/// escala mayor en esa forma, su arpegio y el acorde de la forma).
class CagedDrillScreen extends ConsumerWidget {
  const CagedDrillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cagedDrillProvider);
    final vm = ref.read(cagedDrillProvider.notifier);
    final key = pitchClassName(state.draw.root);
    final shape = state.draw.shape;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final phase = state.phase.index;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubCagedDrill)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.cagedDrillDraw(key, shape),
            key: const Key('caged-drill-draw'),
            style: text.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.cagedDrillPhaseOf(phase + 1, CagedDrillPhase.values.length),
            key: const Key('caged-drill-phase'),
            style: text.labelLarge?.copyWith(color: p.accent),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.cagedDrillPhaseTitle(phase), style: text.titleLarge),
          const SizedBox(height: 6),
          Text(AppStrings.cagedDrillPhaseBody(phase, key: key, shape: shape), style: text.bodyLarge),
          const SizedBox(height: 16),
          switch (state.phase) {
            CagedDrillPhase.chord => _Chord(root: state.draw.root, shape: shape),
            _ => _Scale(draw: state.draw, arpeggio: state.phase == CagedDrillPhase.arpeggio),
          },
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!state.isLastPhase)
                FilledButton.icon(
                  key: const Key('caged-drill-next'),
                  onPressed: vm.nextPhase,
                  icon: const Icon(Icons.chevron_right),
                  label: Text(AppStrings.cagedNext),
                ),
              OutlinedButton.icon(
                key: const Key('caged-drill-reroll'),
                onPressed: vm.reroll,
                icon: const Icon(Icons.casino_outlined),
                label: Text(AppStrings.cagedDrillReroll),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La escala mayor en la forma sorteada; en la fase del arpegio, sus notas
/// resaltadas (`tonicTriad`).
class _Scale extends ConsumerWidget {
  const _Scale({required this.draw, required this.arpeggio});

  final CagedDraw draw;
  final bool arpeggio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pattern = ref.watch(cagedDrillPositionProvider(draw)).value;
    if (pattern == null) return const SizedBox(height: 180);
    final triad = tonicTriad(majorScale)!;
    return FretboardDiagram(
      key: Key(arpeggio ? 'caged-drill-arpeggio' : 'caged-drill-scale'),
      pattern: pattern,
      highlighted: arpeggio
          ? {
              for (final c in pattern.coordinates)
                if (isTriadNote(c.string, c.fret, draw.root, triad)) c,
            }
          : null,
    );
  }
}

/// El acorde mayor de la tónica en la forma sorteada, de chords.json.
class _Chord extends ConsumerWidget {
  const _Chord({required this.root, required this.shape});

  final int root;
  final String shape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final chord = ref.read(chordViewModelProvider.notifier).findByName(pitchClassName(root));
    final position = chord?.cagedPositions.where((c) => c.shape == shape).firstOrNull;
    if (position == null) return const SizedBox(height: 200);
    return Center(
      child: ChordDiagramWidget(
        key: const Key('caged-drill-chord'),
        chordName: '${pitchClassName(root)} · $shape',
        fretPositions: position.fretPositions,
        fingerPositions: position.fingerPositions,
        baseFret: position.baseFret,
        root: pitchClassName(root),
        size: 180,
      ),
    );
  }
}
