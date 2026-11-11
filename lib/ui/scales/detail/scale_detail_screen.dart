import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/chord_metadata.dart';
import '../../../core/constants/scale_names.dart';
import '../../../core/widgets/fingering_theory_card.dart';
import '../../../core/widgets/interval_legend.dart';
import '../../../core/widgets/selector_pill.dart';
import '../../../data/models/note_coordinate.dart';
import '../../../data/models/scale_definition.dart';
import '../../../data/repository/scale_repository.dart';
import '../../../domain/theory/intervals.dart';
import '../../../domain/theory/notes.dart';
import '../../../domain/theory/scale_arpeggio.dart';
import '../../../ui/widgets/fretboard_diagram.dart';
import '../../theme.dart';
import 'scale_detail_notifier.dart';
import 'scale_fretboard_fullscreen.dart';
import 'widgets/pattern_selector.dart';
import 'widgets/scale_info_panel.dart';
import 'widgets/scale_theory_cards.dart';

/// Detalle de una escala: la tónica arriba y la posición predeterminada como
/// vista previa. Sistema y digitación se eligen en la vista ampliada; aquí, lo
/// elegido se muestra y debajo van el sistema y las notas.
class ScaleDetailScreen extends ConsumerWidget {
  const ScaleDetailScreen({
    super.key,
    required this.scale,
    this.initialRoot = 0,
    this.initialPosition,
  });

  final ScaleDefinition scale;

  /// Tónica con la que abre (semitono, C = 0); p. ej. desde un acorde.
  final int initialRoot;

  /// Digitación con la que abre (id de `scales_master.json`), p. ej. desde
  /// una guía; `null` = la predeterminada.
  final String? initialPosition;

  String get _scaleName =>
      scaleDisplayName(scale.id, scale.intervals, fallback: scale.name);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (scale: scale, root: initialRoot, position: initialPosition);
    final state = ref.watch(scaleDetailProvider(args));
    final notifier = ref.read(scaleDetailProvider(args).notifier);
    final pattern = state.currentPattern;

    return Scaffold(
      appBar: AppBar(title: Text('${state.rootName} $_scaleName')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SelectorPill(
                    key: const Key('scale-root'),
                    label: AppStrings.scaleTonic,
                    value: state.rootName,
                    onOpen: () => showNotePicker(
                      context,
                      title: AppStrings.scaleTonic,
                      selected: state.rootName,
                      onPicked: (note) {
                        if (note != null) notifier.changeRoot(noteIndex(note));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (pattern != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ArpeggioBoard(state: state, pattern: pattern),
                ),
                _PatternContext(
                  state: state,
                  onExpand: () => openScaleFretboardFullscreen(context, args),
                ),
                _ArpeggioChips(state: state, onArpeggio: notifier.setArpeggio, onOnly: notifier.setArpeggioOnly),
                IntervalLegend(
                  labels: [
                    for (final c in pattern.coordinates)
                      if (c.isRoot) '1' else c.interval,
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: PageStorageKey('theory-${pattern.systemId}'),
                    shape: const Border(),
                    leading: Icon(
                      Icons.lightbulb_outline,
                      color: context.palette.accent,
                    ),
                    title: Text(
                      AppStrings.scaleHowItWorks(patternSystemName(pattern)),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [FingeringTheoryCard(systemId: pattern.systemId)],
                  ),
                ),
              ] else if (state.isLoading)
                const _DiagramPlaceholder()
              else
                _DiagramPlaceholder(message: AppStrings.scaleNoPositions),
              ScaleInfoPanel(
                scaleName: _scaleName,
                category: scaleCategoryName(scale.category),
                rootName: state.rootName,
                notes: state.scaleNoteNames,
                degrees: scaleDegreeLabels(scale.intervals),
              ),
              ScaleWhyCard(
                intervals: scale.intervals,
                rootSemitone: noteIndex(state.rootName),
              ),
              ScaleHarmonyCard(
                intervals: scale.intervals,
                rootSemitone: noteIndex(state.rootName),
              ),
              ScaleOctavesCard(rootSemitone: noteIndex(state.rootName)),
              ScaleImproviseCard(
                scaleId: scale.id,
                intervals: scale.intervals,
                rootName: state.rootName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El diapasón de la forma; con el arpegio encendido, resalta las notas del
/// acorde de la tónica (`tonicTriad`) y atenúa u oculta las demás.
class _ArpeggioBoard extends StatelessWidget {
  const _ArpeggioBoard({required this.state, required this.pattern});

  final ScaleDetailState state;
  final ResolvedPattern pattern;

  @override
  Widget build(BuildContext context) {
    final triad = state.arpeggio ? tonicTriad(state.scale.intervals) : null;
    if (triad == null) return FretboardDiagram(pattern: pattern);
    final notes = {
      for (final c in pattern.coordinates)
        if (isTriadNote(c.string, c.fret, state.rootSemitone, triad)) c,
    };
    return FretboardDiagram(
      key: const Key('scale-arpeggio-board'),
      pattern: state.arpeggioOnly ? _onlyThese(pattern, notes) : pattern,
      highlighted: state.arpeggioOnly ? null : notes,
    );
  }
}

ResolvedPattern _onlyThese(ResolvedPattern p, Set<NoteCoordinate> notes) => ResolvedPattern(
  scaleId: p.scaleId,
  scaleName: p.scaleName,
  systemId: p.systemId,
  systemName: p.systemName,
  positionId: p.positionId,
  positionName: p.positionName,
  startingFret: p.startingFret,
  endFret: p.endFret,
  coordinates: [for (final c in p.coordinates) if (notes.contains(c)) c],
  declaredOrder: p.declaredOrder,
);

/// «Arpegio de C» y, encendido, «Solo el arpegio», con las notas que lo forman.
class _ArpeggioChips extends StatelessWidget {
  const _ArpeggioChips({required this.state, required this.onArpeggio, required this.onOnly});

  final ScaleDetailState state;
  final void Function({required bool on}) onArpeggio;
  final void Function({required bool on}) onOnly;

  @override
  Widget build(BuildContext context) {
    final triad = tonicTriad(state.scale.intervals);
    if (triad == null) return const SizedBox.shrink();
    final chord = chordDisplayName(root: state.rootName, type: triadType(triad));
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                key: const Key('scale-arpeggio'),
                label: Text(AppStrings.scaleArpeggioOf(chord)),
                selected: state.arpeggio,
                onSelected: (v) => onArpeggio(on: v),
              ),
              if (state.arpeggio)
                FilterChip(
                  key: const Key('scale-arpeggio-only'),
                  label: Text(AppStrings.scaleArpeggioOnly),
                  selected: state.arpeggioOnly,
                  onSelected: (v) => onOnly(on: v),
                ),
            ],
          ),
          if (state.arpeggio)
            Text(
              AppStrings.scaleArpeggioHint(
                chord,
                [for (final i in triad) pitchClassName(state.rootSemitone + i)].join(' '),
              ),
              key: const Key('scale-arpeggio-hint'),
              style: text.bodySmall?.copyWith(color: context.palette.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// Bajo el diapasón: qué posición muestra y, en la esquina derecha, el botón de
/// ampliar (fuera del lienzo, para no tapar notas).
class _PatternContext extends StatelessWidget {
  const _PatternContext({required this.state, required this.onExpand});

  final ScaleDetailState state;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final pattern = state.currentPattern!;
    final name = positionDisplayName(pattern.positionName);
    final system = patternSystemName(pattern);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.hasSelectedPattern
                  ? AppStrings.scalePatternContext(
                      name,
                      system,
                      pattern.startingFret,
                      pattern.endFret,
                    )
                  : AppStrings.scalePreviewHint(name, system),
              key: const Key('scale-pattern-context'),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: context.palette.textSecondary),
            ),
          ),
          IconButton(
            key: const Key('scale-expand'),
            icon: const Icon(Icons.fullscreen),
            tooltip: AppStrings.scaleExpandBoard,
            onPressed: onExpand,
          ),
        ],
      ),
    );
  }
}

class _DiagramPlaceholder extends StatelessWidget {
  const _DiagramPlaceholder({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          color: context.palette.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: message == null ? null : Text(message!),
      );
}
