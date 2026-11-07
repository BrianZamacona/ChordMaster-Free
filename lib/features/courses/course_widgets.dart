import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import 'course_progress.dart';

/// Etiqueta del tipo de paso.
String courseKindName(CourseStepKind kind) => switch (kind) {
  CourseStepKind.theory => AppStrings.courseTheory,
  CourseStepKind.exercise => AppStrings.courseExercise,
  CourseStepKind.song => AppStrings.courseSong,
};

/// Tres estrellas, llenas las ganadas.
class CourseStars extends StatelessWidget {
  const CourseStars({super.key, required this.stars, this.size = 18});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < courseStarTempos.length; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? p.accent : p.textSecondary,
          ),
      ],
    );
  }
}

/// Un curso de arriba abajo: cada nivel con su número, título e idea, y sus
/// pasos en una línea vertical (teoría, ejercicios y canciones con sus
/// estrellas); al final, los resultados del curso.
class CourseOverview<S extends CourseStep> extends ConsumerWidget {
  const CourseOverview({
    super.key,
    required this.course,
    required this.intro,
    required this.levels,
    required this.routeOf,
    this.header = const [],
    this.footer = const [],
  });

  final CourseId course;
  final String intro;
  final List<CourseLevel<S>> levels;

  /// Lo que va antes de la presentación y después de los resultados (en el
  /// mapa: el encabezado de la unidad y la que sigue).
  final List<Widget> header;
  final List<Widget> footer;

  /// Ruta del paso con ese id.
  final String Function(String stepId) routeOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(courseProgressProvider(course));
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        ...header,
        Text(intro, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
        for (final (i, level) in levels.indexed) ...[
          const SizedBox(height: 24),
          Text(
            AppStrings.courseLevel(i + 1),
            style: text.titleSmall?.copyWith(color: p.accent),
          ),
          Text(
            level.title.text,
            key: Key('course-level-$i'),
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
              number: courseExerciseNumber(level, step),
              isFirst: j == 0,
              isLast: j == level.steps.length - 1,
              route: routeOf(step.id),
            ),
        ],
        const SizedBox(height: 24),
        _CourseResults(progress: progress, steps: courseSteps(levels)),
        ...footer,
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
    required this.route,
  });

  final CourseStep step;
  final CourseProgress progress;
  final int? number;
  final bool isFirst;
  final bool isLast;
  final String route;

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
      courseKindName(step.kind),
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
                  key: Key('course-step-${step.id}'),
                  onTap: () => context.push(route),
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
                              if (step.kind == CourseStepKind.theory)
                                Icon(
                                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: done ? p.success : p.textSecondary,
                                )
                              else
                                CourseStars(
                                  key: Key('course-stars-${step.id}'),
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
  const _CourseResults({required this.progress, required this.steps});

  final CourseProgress progress;
  final List<CourseStep> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (stars, maxStars) = progress.starTotals(steps);
    final (songs, maxSongs) = progress.songTotals(steps);
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
      key: const Key('course-results'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.courseResults, style: text.titleMedium),
            const SizedBox(height: 8),
            row(Icons.star_rounded, '$stars', '$maxStars', AppStrings.courseStarsLabel),
            row(Icons.music_note, '$songs', '$maxSongs', AppStrings.courseSongsLabel),
            const SizedBox(height: 4),
            Text(
              AppStrings.courseStarRule,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un paso de un curso: encabezado (nivel, tipo, título, origen), el
/// contenido propio [body] y, según el tipo, "Entendido" (teoría) o la
/// tarjeta de tempo con su reproductor; al final, el siguiente paso, que
/// reemplaza la pantalla (atrás vuelve al curso, no apila pasos).
class CourseStepView<S extends CourseStep> extends ConsumerStatefulWidget {
  const CourseStepView({
    super.key,
    required this.course,
    required this.levels,
    required this.step,
    required this.body,
    required this.player,
    required this.routeOf,
    this.playerNote,
  });

  final CourseId course;
  final List<CourseLevel<S>> levels;
  final S step;
  final Widget body;

  /// El reproductor del paso al tempo dado (no se usa en teoría).
  final Widget Function(int bpm) player;
  final String Function(String stepId) routeOf;

  /// Aclaración bajo el reproductor.
  final String? playerNote;

  @override
  ConsumerState<CourseStepView<S>> createState() => _CourseStepViewState<S>();
}

class _CourseStepViewState<S extends CourseStep> extends ConsumerState<CourseStepView<S>> {
  int? _bpm;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final progress = ref.watch(courseProgressProvider(widget.course));
    final vm = ref.read(courseProgressProvider(widget.course).notifier);
    final best = progress.best[step.id];
    final bpm = _bpm ?? startTempoFor(best);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final next = nextCourseStep(widget.levels, step);
    final level = courseLevelOf(widget.levels, step);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          '${AppStrings.courseLevel(level)} · ${courseKindName(step.kind)}',
          style: text.titleSmall?.copyWith(color: p.accent),
        ),
        Text(step.title.text, key: const Key('course-title'), style: text.headlineSmall),
        if (step.origin case final o?)
          Text(o.text, style: text.bodySmall?.copyWith(color: p.textSecondary)),
        const SizedBox(height: 10),
        widget.body,
        const SizedBox(height: 16),
        if (step.kind == CourseStepKind.theory)
          Align(
            alignment: Alignment.centerLeft,
            child: progress.isDone(step)
                ? OutlinedButton.icon(
                    key: const Key('course-read'),
                    icon: Icon(Icons.check_circle, color: p.success),
                    label: Text(AppStrings.courseUnread),
                    onPressed: () => vm.toggleRead(step.id),
                  )
                : FilledButton.icon(
                    key: const Key('course-read'),
                    icon: const Icon(Icons.check),
                    label: Text(AppStrings.courseRead),
                    onPressed: () => vm.toggleRead(step.id),
                  ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CourseStars(
                        key: const Key('course-step-stars'),
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
                    AppStrings.courseStarRule,
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  _TempoStepper(
                    bpm: bpm,
                    onChanged: (v) => setState(() => _bpm = v),
                  ),
                  const SizedBox(height: 10),
                  widget.player(bpm),
                  if (widget.playerNote case final note?) ...[
                    const SizedBox(height: 6),
                    Text(note, style: text.bodySmall?.copyWith(color: p.textSecondary)),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      key: const Key('course-clean'),
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
        if (next != null) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('course-next'),
            icon: const Icon(Icons.arrow_forward),
            label: Text('${AppStrings.courseNext}: ${next.title.text}'),
            onPressed: () => context.pushReplacement(widget.routeOf(next.id)),
          ),
        ],
      ],
    );
  }
}

class _TempoStepper extends StatelessWidget {
  const _TempoStepper({required this.bpm, required this.onChanged});

  final int bpm;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(AppStrings.techniqueTempo, style: text.labelLarge)),
        IconButton.outlined(
          key: const Key('course-slower'),
          tooltip: AppStrings.techniqueSlower,
          icon: const Icon(Icons.remove),
          onPressed: bpm > techniqueMinBpm ? () => onChanged(bpm - techniqueBpmStep) : null,
        ),
        SizedBox(
          width: 96,
          child: Text(
            AppStrings.techniqueBpm(bpm),
            key: const Key('course-bpm'),
            textAlign: TextAlign.center,
            style: musicMono(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton.outlined(
          key: const Key('course-faster'),
          tooltip: AppStrings.techniqueFaster,
          icon: const Icon(Icons.add),
          onPressed: bpm < techniqueMaxBpm ? () => onChanged(bpm + techniqueBpmStep) : null,
        ),
      ],
    );
  }
}
