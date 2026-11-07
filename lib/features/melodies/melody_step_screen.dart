import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/melodies/melody_course.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../ui/theme.dart';
import '../lessons/tab_player.dart';
import 'melodies_screen.dart';
import 'melody_progress.dart';

/// Un paso del curso: la teoría se lee y se marca; un ejercicio o una canción
/// se escucha en tablatura al tempo elegido y guarda el mejor tempo limpio,
/// que da sus estrellas.
class MelodyStepScreen extends ConsumerStatefulWidget {
  const MelodyStepScreen({super.key, required this.stepId});

  final String stepId;

  @override
  ConsumerState<MelodyStepScreen> createState() => _MelodyStepScreenState();
}

class _MelodyStepScreenState extends ConsumerState<MelodyStepScreen> {
  int? _bpm;

  @override
  Widget build(BuildContext context) {
    final step = melodyStepsById[widget.stepId];
    if (step == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.hubMelodies)),
        body: Center(child: Text(AppStrings.guideNotFound)),
      );
    }
    final progress = ref.watch(melodyProgressProvider);
    final vm = ref.read(melodyProgressProvider.notifier);
    final best = progress.best[step.id];
    // Empieza en el tempo de la próxima estrella.
    final bpm = _bpm ??
        melodyStarTempos.firstWhere(
          (t) => best == null || t > best,
          orElse: () => melodyStarTempos.last,
        );
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final next = _nextStep(step);

    return Scaffold(
      appBar: AppBar(title: Text(step.title.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            '${AppStrings.melodiesLevel(levelOf(step))} · ${melodyKindName(step.kind)}',
            style: text.titleSmall?.copyWith(color: p.accent),
          ),
          Text(step.title.text, key: const Key('melody-title'), style: text.headlineSmall),
          if (step.origin case final o?)
            Text(o.text, style: text.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 10),
          Text(step.body.text, style: text.bodyLarge),
          const SizedBox(height: 16),
          if (step.kind == MelodyStepKind.theory)
            Align(
              alignment: Alignment.centerLeft,
              child: progress.isDone(step)
                  ? OutlinedButton.icon(
                      key: const Key('melody-read'),
                      icon: Icon(Icons.check_circle, color: p.success),
                      label: Text(AppStrings.melodiesUnread),
                      onPressed: () => vm.toggleRead(step.id),
                    )
                  : FilledButton.icon(
                      key: const Key('melody-read'),
                      icon: const Icon(Icons.check),
                      label: Text(AppStrings.melodiesRead),
                      onPressed: () => vm.toggleRead(step.id),
                    ),
            )
          else ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        MelodyStars(
                          key: const Key('melody-step-stars'),
                          stars: progress.stars(step),
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            best == null
                                ? AppStrings.techniqueNoRecord
                                : AppStrings.techniqueRecord(best),
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.melodiesStarRule,
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(AppStrings.techniqueTempo, style: text.labelLarge),
                        ),
                        IconButton.outlined(
                          key: const Key('melody-slower'),
                          tooltip: AppStrings.techniqueSlower,
                          icon: const Icon(Icons.remove),
                          onPressed: bpm > techniqueMinBpm
                              ? () => setState(() => _bpm = bpm - techniqueBpmStep)
                              : null,
                        ),
                        SizedBox(
                          width: 96,
                          child: Text(
                            AppStrings.techniqueBpm(bpm),
                            key: const Key('melody-bpm'),
                            textAlign: TextAlign.center,
                            style: musicMono(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton.outlined(
                          key: const Key('melody-faster'),
                          tooltip: AppStrings.techniqueFaster,
                          icon: const Icon(Icons.add),
                          onPressed: bpm < techniqueMaxBpm
                              ? () => setState(() => _bpm = bpm + techniqueBpmStep)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TabPlayer(notes: step.tab, bpm: bpm),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.melodiesEvenRhythm,
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        key: const Key('melody-clean'),
                        icon: const Icon(Icons.check),
                        label: Text(AppStrings.techniqueSaveClean(bpm)),
                        onPressed: best != null && best >= bpm
                            ? null
                            : () => vm.saveClean(step.id, bpm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (next != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              key: const Key('melody-next'),
              icon: const Icon(Icons.arrow_forward),
              label: Text('${AppStrings.melodiesNext}: ${next.title.text}'),
              // Reemplaza: atrás vuelve al curso, no apila pasos.
              onPressed: () => context.pushReplacement('/learn/melodies/${next.id}'),
            ),
          ],
        ],
      ),
    );
  }

  static MelodyStep? _nextStep(MelodyStep step) {
    final all = [for (final l in melodyCourse) ...l.steps];
    final i = all.indexOf(step);
    return i + 1 < all.length ? all[i + 1] : null;
  }
}
