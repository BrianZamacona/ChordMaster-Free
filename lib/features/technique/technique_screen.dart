import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/practice/play_along.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../ui/theme.dart';
import '../lessons/tab_player.dart';
import 'technique_viewmodel.dart';

/// Ejercicios de técnica: eliges dónde empieza la ventana y el tempo; cada
/// ejercicio se escucha en tablatura y guarda el mejor tempo tocado limpio.
class TechniqueScreen extends ConsumerWidget {
  const TechniqueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(techniqueViewModelProvider);
    final vm = ref.read(techniqueViewModelProvider.notifier);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubTechnique)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.techniqueIntro,
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.techniqueStartFret, style: text.labelLarge),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            key: const Key('technique-start'),
            showSelectedIcon: false,
            segments: [
              for (final f in techniqueStartFrets)
                ButtonSegment(value: f, label: Text('$f')),
            ],
            selected: {state.startFret},
            onSelectionChanged: (v) => vm.changeStartFret(v.first),
          ),
          const SizedBox(height: 12),
          _TempoRow(
            bpm: state.bpm,
            onStep: vm.stepBpm,
          ),
          const SizedBox(height: 8),
          for (final e in TechniqueExercise.values)
            _ExerciseCard(
              key: Key('technique-${e.name}'),
              exercise: e,
              startFret: state.startFret,
              bpm: state.bpm,
              record: state.records[e],
              onClean: () => vm.saveRecord(e),
              onPlayed: (r) => _savePlayed(context, vm, e, state.records[e], r),
            ),
        ],
      ),
    );
  }
}

class _TempoRow extends StatelessWidget {
  const _TempoRow({required this.bpm, required this.onStep});

  final int bpm;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(AppStrings.techniqueTempo, style: text.labelLarge)),
        IconButton.outlined(
          key: const Key('technique-slower'),
          tooltip: AppStrings.techniqueSlower,
          icon: const Icon(Icons.remove),
          onPressed: bpm > techniqueMinBpm ? () => onStep(-1) : null,
        ),
        SizedBox(
          width: 96,
          child: Text(
            AppStrings.techniqueBpm(bpm),
            key: const Key('technique-bpm'),
            textAlign: TextAlign.center,
            style: musicMono(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton.outlined(
          key: const Key('technique-faster'),
          tooltip: AppStrings.techniqueFaster,
          icon: const Icon(Icons.add),
          onPressed: bpm < techniqueMaxBpm ? () => onStep(1) : null,
        ),
      ],
    );
  }
}

/// Tocado con el micrófono: una pasada limpia que supera el récord se guarda.
void _savePlayed(
  BuildContext context,
  TechniqueViewModel vm,
  TechniqueExercise exercise,
  int? record,
  PlayAlongResult result,
) {
  final bpm = result.cleanBpm;
  if (bpm == null || (record != null && record >= bpm)) return;
  vm.saveRecord(exercise, bpm: bpm);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppStrings.tabMicSaved(bpm))));
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.startFret,
    required this.bpm,
    required this.record,
    required this.onClean,
    required this.onPlayed,
  });

  final TechniqueExercise exercise;
  final int startFret;
  final int bpm;
  final int? record;
  final VoidCallback onClean;
  final ValueChanged<PlayAlongResult> onPlayed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final notes = techniqueNotes(exercise, startFret: startFret);
    final record = this.record;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(techniqueName(exercise).text, style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              techniqueHint(exercise).text,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.workoutsNoteCount(notes.length),
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(height: 10),
            TabPlayer(notes: notes, bpm: bpm, onPlayed: onPlayed),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: record == null ? p.textSecondary : p.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record == null
                        ? AppStrings.techniqueNoRecord
                        : '${AppStrings.techniqueRecord(record)} · '
                            '${AppStrings.techniqueTryNext(techniqueNextBpm(record))}',
                    key: Key('technique-record-${exercise.name}'),
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('technique-clean-${exercise.name}'),
                icon: const Icon(Icons.check),
                label: Text(AppStrings.techniqueSaveClean(bpm)),
                // Solo cuenta si supera el récord.
                onPressed: record != null && record >= bpm ? null : onClean,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
