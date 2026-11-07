import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/scale_names.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/fingering_systems/fingering_systems_registry.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/scale_workouts.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../lessons/tab_player.dart';
import 'workouts_viewmodel.dart';

/// Rutinas de escala: eliges escala, tónica, nivel y posición, y cada patrón
/// del nivel aparece en tablatura, listo para escuchar y tocar a su tempo.
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key, this.scaleId = 'major', this.root = 0});

  final String scaleId;
  final int root;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (scaleId: scaleId, root: root);
    final state = ref.watch(workoutsViewModelProvider(args));
    final vm = ref.read(workoutsViewModelProvider(args).notifier);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final scale = state.scale;
    final position = state.position;
    final ladder = state.ladder;
    final bpm = workoutBpm[state.level]!;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.workoutsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.workoutsIntro,
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SelectorPill(
                key: const Key('workouts-scale'),
                label: AppStrings.workoutsScale,
                value: scale == null
                    ? null
                    : scaleDisplayName(scale.id, scale.intervals, fallback: scale.name),
                onOpen: () => _showScales(context, state, vm.changeScale),
              ),
              SelectorPill(
                key: const Key('workouts-root'),
                label: AppStrings.scaleTonic,
                value: pitchClassName(state.root),
                onOpen: () => showNotePicker(
                  context,
                  title: AppStrings.scaleTonic,
                  selected: pitchClassName(state.root),
                  onPicked: (note) {
                    if (note != null) vm.changeRoot(noteIndex(note));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<WorkoutLevel>(
            key: const Key('workouts-level'),
            showSelectedIcon: false,
            segments: [
              for (final level in WorkoutLevel.values)
                ButtonSegment(
                  value: level,
                  label: Text(
                    workoutLevelName(level).text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {state.level},
            onSelectionChanged: (v) => vm.changeLevel(v.first),
          ),
          const SizedBox(height: 12),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (position == null)
            Text(AppStrings.scaleNoPositions)
          else ...[
            Row(
              children: [
                IconButton(
                  key: const Key('workouts-previous'),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: AppStrings.workoutsPrevious,
                  onPressed: state.positionIndex > 0
                      ? () => vm.stepPosition(-1)
                      : null,
                ),
                Expanded(
                  child: Text(
                    AppStrings.workoutsPosition(
                      positionDisplayName(position.positionName),
                      FingeringSystemsRegistry.theoryFor(position.systemId)
                              ?.name
                              .text ??
                          position.systemName,
                      position.startingFret,
                      position.endFret,
                    ),
                    key: const Key('workouts-position'),
                    textAlign: TextAlign.center,
                    style: text.labelLarge,
                  ),
                ),
                IconButton(
                  key: const Key('workouts-next'),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: AppStrings.workoutsNext,
                  onPressed: state.positionIndex < state.positions.length - 1
                      ? () => vm.stepPosition(1)
                      : null,
                ),
              ],
            ),
            Text(
              AppStrings.workoutsPositionCount(
                state.positionIndex + 1,
                state.positions.length,
              ),
              textAlign: TextAlign.center,
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final pattern in workoutPatterns[state.level]!)
              if (workoutNotes(pattern, ladder).isNotEmpty)
                _WorkoutCard(
                  // Otra posición o escala vuelve a mostrar solo la subida.
                  key: ValueKey('workout-${pattern.name}-${position.positionId}-'
                      '${state.scaleId}-${state.root}'),
                  pattern: pattern,
                  ladder: ladder,
                  bpm: bpm,
                ),
          ],
        ],
      ),
    );
  }

  void _showScales(
    BuildContext context,
    WorkoutsState state,
    ValueChanged<String> onPicked,
  ) =>
      showSelectorSheet(
        context,
        title: AppStrings.workoutsScale,
        builder: (sheet) => Column(
          children: [
            for (final s in state.scales)
              ListTile(
                key: Key('workouts-scale-${s.id}'),
                title: Text(
                  scaleDisplayName(s.id, s.intervals, fallback: s.name),
                ),
                trailing: s.id == state.scaleId
                    ? Icon(Icons.check, color: sheet.palette.accent)
                    : null,
                onTap: () {
                  onPicked(s.id);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      );
}

/// Un patrón de la rutina. Muestra solo la subida, para que la tablatura no
/// se haga larguísima; "Agregar la bajada" suma el mismo dibujo al revés.
class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({
    super.key,
    required this.pattern,
    required this.ladder,
    required this.bpm,
  });

  final WorkoutPattern pattern;
  final List<TabNote> ladder;
  final int bpm;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  var _withDown = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final notes = workoutNotes(
      widget.pattern,
      widget.ladder,
      direction: _withDown ? WorkoutDirection.both : WorkoutDirection.up,
    );
    return Card(
      key: Key('workout-${widget.pattern.name}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(workoutPatternName(widget.pattern).text, style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              workoutPatternHint(widget.pattern).text,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.workoutsNoteCount(notes.length),
              key: Key('workout-count-${widget.pattern.name}'),
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(height: 10),
            TabPlayer(notes: notes, bpm: widget.bpm),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('workout-down-${widget.pattern.name}'),
                onPressed: () => setState(() => _withDown = !_withDown),
                icon: Icon(_withDown ? Icons.remove : Icons.add),
                label: Text(
                  _withDown ? AppStrings.workoutsOnlyUp : AppStrings.workoutsAddDown,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
