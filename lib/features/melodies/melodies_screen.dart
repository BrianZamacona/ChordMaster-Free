import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/melodies/melody_course.dart';
import '../../domain/melodies/melody_progress.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import 'melody_progress.dart';

/// Curso de melodías, de arriba abajo: cada nivel con su número, título e
/// idea, y sus pasos en una línea vertical (teoría, ejercicios y canciones con
/// sus estrellas); al final, los resultados del curso.
class MelodiesScreen extends ConsumerWidget {
  const MelodiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(melodyProgressProvider);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubMelodies)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.melodiesIntro,
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          for (final (i, level) in melodyCourse.indexed) ...[
            const SizedBox(height: 24),
            Text(
              AppStrings.melodiesLevel(i + 1),
              style: text.titleSmall?.copyWith(color: p.accent),
            ),
            Text(
              level.title.text,
              key: Key('melodies-level-$i'),
              style: text.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              level.intro.text,
              style: text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 12),
            for (final (j, step) in level.steps.indexed)
              _StepRow(
                step: step,
                progress: progress,
                number: _exerciseNumber(level, step),
                isFirst: j == 0,
                isLast: j == level.steps.length - 1,
              ),
          ],
          const SizedBox(height: 24),
          _CourseResults(progress: progress),
        ],
      ),
    );
  }

  /// Los ejercicios y canciones se numeran dentro del nivel; la teoría no.
  static int? _exerciseNumber(MelodyLevel level, MelodyStep step) {
    if (step.kind == MelodyStepKind.theory) return null;
    final playable = [
      for (final s in level.steps)
        if (s.kind != MelodyStepKind.theory) s,
    ];
    return playable.indexOf(step) + 1;
  }
}

/// Etiqueta del tipo de paso.
String melodyKindName(MelodyStepKind kind) => switch (kind) {
  MelodyStepKind.theory => AppStrings.melodiesTheory,
  MelodyStepKind.exercise => AppStrings.melodiesExercise,
  MelodyStepKind.song => AppStrings.melodiesSong,
};

/// Tres estrellas, llenas las ganadas.
class MelodyStars extends StatelessWidget {
  const MelodyStars({super.key, required this.stars, this.size = 18});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < melodyStarTempos.length; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? p.accent : p.textSecondary,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.progress,
    required this.number,
    required this.isFirst,
    required this.isLast,
  });

  final MelodyStep step;
  final MelodyProgress progress;
  final int? number;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final done = progress.isDone(step);
    final circle = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surface,
        shape: BoxShape.circle,
        border: Border.all(color: done ? p.accent : p.outline, width: 2.5),
      ),
      child: number == null
          ? Icon(Icons.play_arrow_rounded, color: p.accent, size: 26)
          : Text(
              '$number',
              style: musicMono(fontSize: 16, fontWeight: FontWeight.w600, color: p.accent),
            ),
    );
    final subtitle = [
      melodyKindName(step.kind),
      if (step.origin case final o?) o.text,
    ].join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepRail(
            circle: circle,
            isFirst: isFirst,
            isLast: isLast,
            topDone: done,
            bottomDone: done,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: Key('melody-${step.id}'),
                  onTap: () => context.push('/learn/melodies/${step.id}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.title.text, style: text.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: text.bodySmall?.copyWith(color: p.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              if (step.kind == MelodyStepKind.theory)
                                Icon(
                                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: done ? p.success : p.textSecondary,
                                )
                              else
                                MelodyStars(
                                  key: Key('melody-stars-${step.id}'),
                                  stars: progress.stars(step),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: p.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseResults extends StatelessWidget {
  const _CourseResults({required this.progress});

  final MelodyProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (stars, maxStars) = progress.starTotals;
    final (songs, maxSongs) = progress.songTotals;
    Widget row(IconData icon, String value, String total, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: p.accent, size: 26),
              const SizedBox(width: 12),
              Text(value, style: musicMono(fontSize: 22, fontWeight: FontWeight.w600)),
              Text(
                '/$total',
                style: musicMono(fontSize: 22, color: p.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
              ),
            ],
          ),
        );
    return Card(
      key: const Key('melodies-results'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.melodiesResults, style: text.titleMedium),
            const SizedBox(height: 8),
            row(Icons.star_rounded, '$stars', '$maxStars', AppStrings.melodiesStars),
            row(Icons.music_note, '$songs', '$maxSongs', AppStrings.melodiesSongs),
            const SizedBox(height: 4),
            Text(
              AppStrings.melodiesStarRule,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
