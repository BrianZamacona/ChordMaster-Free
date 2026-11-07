import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/scale_names.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../domain/lessons/unit_summary.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../courses/course_progress.dart';
import '../courses/course_registry.dart';
import '../courses/course_widgets.dart';
import 'challenge_progress.dart';
import 'lesson_widgets.dart';
import 'lessons_viewmodel.dart';
import 'unit_progress.dart';

/// Una unidad del mapa, de arriba abajo: qué se aprende y cuánto llevas; sus
/// lecciones en una línea vertical, cada una con lo que practica; el reto que
/// cierra el nivel; los resultados y la unidad que sigue.
class LessonUnitScreen extends ConsumerWidget {
  const LessonUnitScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = unitsById[unitId];
    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.lessonsTitle)),
        body: Center(child: Text(AppStrings.unitNotFound)),
      );
    }
    if (unit.course case final course?) {
      return _CourseUnitScreen(unit: unit, course: course);
    }
    final path = ref.watch(learningPathProvider);
    final summary = UnitSummary(unit, completed: path.completed);
    final lessons = summary.lessons;
    final next = path.nextLesson;
    final challenge = summary.closingChallenge;
    final nextUnit = summary.nextUnit;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(unit.title.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _UnitHeader(summary: summary),
          const SizedBox(height: 20),
          _SectionTitle(AppStrings.unitLessons),
          for (final (i, lesson) in lessons.indexed)
            _LessonStep(
              lesson: lesson,
              done: summary.isDone(lesson),
              isNext: lesson == next,
              // La línea llega al reto si lo hay; si no, se corta en la última.
              isFirst: i == 0,
              isLast: i == lessons.length - 1 && challenge == null,
              lineDone: summary.isDone(lesson),
            ),
          if (challenge != null) ...[
            _ChallengeStep(challenge: challenge, reachable: summary.finished),
          ],
          const SizedBox(height: 20),
          _SectionTitle(AppStrings.unitResults),
          _UnitResults(summary: summary),
          const SizedBox(height: 20),
          _SectionTitle(AppStrings.unitNext),
          if (nextUnit != null)
            _NextUnit(unit: nextUnit, completed: path.completed)
          else
            Text(
              AppStrings.unitEndOfPath,
              key: const Key('unit-end'),
              style: text.bodyMedium?.copyWith(color: context.palette.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.summary});

  final UnitSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final unit = summary.unit;
    final total = summary.lessons.length;
    final (index, units) = summary.position;
    final pending = summary.lessons.where((l) => !summary.isDone(l)).firstOrNull;
    final track = unit.track == LessonTrack.foundations
        ? trackName(unit.track)
        : AppStrings.trackLevel(trackName(unit.track), unit.level);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El dibujo va encima: un rasgueo o una escala ocupan todo el ancho.
            UnitArtView(art: unit.art, size: 88),
            const SizedBox(height: 12),
            Text(
              '$track · ${AppStrings.unitPosition(index, units)}',
              key: const Key('unit-eyebrow'),
              style: text.labelLarge?.copyWith(color: p.accent),
            ),
            const SizedBox(height: 2),
            Text(unit.title.text, key: const Key('unit-title'), style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(
              unit.summary.text,
              key: const Key('unit-summary'),
              style: text.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.lessonsUnitCount(total, summary.minutes),
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ),
                Text(
                  AppStrings.lessonsProgress(summary.done, total),
                  key: const Key('unit-progress'),
                  style: musicMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: summary.finished ? p.success : p.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: summary.done / total,
                minHeight: 6,
                color: summary.finished ? p.success : p.accent,
                backgroundColor: p.surfaceHigh,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('unit-start'),
              onPressed: () => context.push(
                '/learn/lessons/${(pending ?? summary.lessons.first).id}',
              ),
              child: Text(
                pending == null
                    ? AppStrings.lessonsReview
                    : summary.done == 0
                        ? AppStrings.lessonsStart
                        : AppStrings.lessonsResume,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonStep extends StatelessWidget {
  const _LessonStep({
    required this.lesson,
    required this.done,
    required this.isNext,
    required this.isFirst,
    required this.isLast,
    required this.lineDone,
  });

  final Lesson lesson;
  final bool done;
  final bool isNext;
  final bool isFirst;
  final bool isLast;
  final bool lineDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (fill, ink, border) = done
        ? (p.success, p.onAccent, p.success)
        : isNext
            ? (p.accent, p.onAccent, p.accent)
            : (p.surface, p.accent, p.outline);
    final circle = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      child: done
          ? Icon(Icons.check, color: ink, size: 22)
          : Text(
              LessonPath.labelOf(lesson),
              style: musicMono(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
            ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepRail(
            circle: circle,
            isFirst: isFirst,
            isLast: isLast,
            topDone: lineDone,
            bottomDone: lineDone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isNext
                      ? BorderSide(color: p.accent, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  key: Key('lesson-${lesson.id}'),
                  // push: atrás vuelve a la unidad desde donde se abrió.
                  onTap: () => context.push('/learn/lessons/${lesson.id}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(lesson.title.text, style: text.titleSmall),
                            ),
                            Icon(Icons.chevron_right, color: p.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done
                              ? '${AppStrings.lessonMinutes(lesson.minutes)} · '
                                  '${AppStrings.lessonDone}'
                              : isNext
                                  ? '${AppStrings.lessonMinutes(lesson.minutes)} · '
                                      '${AppStrings.lessonNext}'
                                  : AppStrings.lessonMinutes(lesson.minutes),
                          style: text.bodySmall?.copyWith(
                            color: done
                                ? p.success
                                : isNext
                                    ? p.accent
                                    : p.textSecondary,
                          ),
                        ),
                        if (_contents(lesson) case final items
                            when items.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final (icon, label) in items)
                                _ContentChip(icon: icon, label: label),
                            ],
                          ),
                        ],
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

  /// Lo que practica la lección, sacado de sus datos.
  static List<(IconData, String)> _contents(Lesson lesson) => [
        if (lesson.chords.isNotEmpty)
          (Icons.library_music_outlined, AppStrings.lessonChordList(lesson.chords.join(' '))),
        if (lesson.scale case final s?)
          (
            Icons.linear_scale,
            '${pitchClassName(s.root)} ${scaleDisplayName(s.scaleId, const [])}',
          ),
        if (lesson.strumPattern != null) (Icons.swap_vert, AppStrings.lessonStrum),
        if (lesson.tab.isNotEmpty)
          (Icons.queue_music, AppStrings.lessonTabNotes(lesson.tab.length)),
        if (lesson.tool case final tool?) _tool(tool, lesson.bpm),
      ];

  static (IconData, String) _tool(LessonTool tool, int? bpm) => switch (tool) {
        LessonTool.tuner => (Icons.tune, AppStrings.moduleTuner),
        LessonTool.metronome => (
            Icons.av_timer,
            bpm == null
                ? AppStrings.moduleMetronome
                : '${AppStrings.moduleMetronome} · $bpm BPM',
          ),
        LessonTool.progressions => (Icons.queue_music, AppStrings.hubProgressions),
        LessonTool.doubleStops => (Icons.straighten, AppStrings.dsTitle),
        LessonTool.circle => (Icons.donut_large, AppStrings.circleTitle),
      };
}

class _ContentChip extends StatelessWidget {
  const _ContentChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: p.accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// El reto que cierra el nivel, al final de la línea, con el doble punto del
/// traste 12. Se supera solo con el récord del módulo.
class _ChallengeStep extends ConsumerWidget {
  const _ChallengeStep({required this.challenge, required this.reachable});

  final LessonChallenge challenge;

  /// La línea llega pintada si la unidad está terminada.
  final bool reachable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (:route, :status, :passed, best: _) = challengeProgress(ref, challenge);
    final inlay = passed ? p.success : p.accent;
    final circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: p.surface,
        shape: BoxShape.circle,
        border: Border.all(color: inlay, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: inlay, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepRail(
            circle: circle,
            isFirst: false,
            isLast: true,
            topDone: reachable,
            bottomDone: false,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: inlay, width: 2),
              ),
              child: InkWell(
                key: Key('unit-challenge-${challenge.id}'),
                onTap: () => context.go(route),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.unitChallenge,
                        style: text.labelMedium?.copyWith(color: inlay),
                      ),
                      Text(challenge.title.text, style: text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        challenge.body.text,
                        style: text.bodySmall?.copyWith(color: p.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        status,
                        key: Key('unit-challenge-status-${challenge.id}'),
                        style: musicMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: passed ? p.success : p.textSecondary,
                        ),
                      ),
                    ],
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

/// Cifras de la unidad: lecciones hechas, minutos practicados, acordes y
/// notas de tablatura.
class _UnitResults extends StatelessWidget {
  const _UnitResults({required this.summary});

  final UnitSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.check_circle_outline,
        '${summary.done}/${summary.lessons.length}',
        AppStrings.unitResultLessons,
      ),
      (
        Icons.schedule,
        '${summary.minutesDone}/${summary.minutes}',
        AppStrings.unitResultMinutes,
      ),
      if (summary.chords.isNotEmpty)
        (
          Icons.library_music_outlined,
          '${summary.chords.length}',
          AppStrings.unitResultChords,
        ),
      if (summary.tabNotes > 0)
        (Icons.queue_music, '${summary.tabNotes}', AppStrings.unitResultNotes),
    ];
    return Card(
      key: const Key('unit-results'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            for (final (icon, value, label) in items) _ResultRow(icon, value, label),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.icon, this.value, this.label);

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: p.accent),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              value,
              style: musicMono(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(label, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// La unidad que sigue en el camino: reemplaza a esta, así atrás vuelve al
/// mapa y no se apilan unidades.
class _NextUnit extends ConsumerWidget {
  const _NextUnit({required this.unit, required this.completed});

  final LessonUnit unit;
  final Set<String> completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final summary = UnitSummary(unit, completed: completed);
    final (done, total) = watchUnitProgress(ref, unit);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('unit-next'),
        onTap: () => context.pushReplacement('/learn/lessons/unit/${unit.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 72, child: UnitArtView(art: unit.art, size: 56)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.title.text, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      unit.summary.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.course == null
                          ? '${AppStrings.lessonsUnitCount(summary.lessons.length, summary.minutes)}'
                              ' · ${AppStrings.lessonsProgress(done, total)}'
                          : AppStrings.unitCourseSteps(done, total),
                      style: musicMono(fontSize: 11, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una unidad que es un curso: el encabezado de la unidad (camino, posición,
/// avance y "Empezar"), el curso con sus niveles y resultados, el reto si
/// cierra el nivel y la unidad que sigue.
class _CourseUnitScreen extends ConsumerWidget {
  const _CourseUnitScreen({required this.unit, required this.course});

  final LessonUnit unit;
  final LessonCourse course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = watchCourseLevels(ref, course);
    final path = ref.watch(learningPathProvider);
    final summary = UnitSummary(unit, completed: path.completed);
    final (done, total) = watchUnitProgress(ref, unit);
    final progress = ref.watch(courseProgressProvider(course.progressId));
    final challenge = summary.closingChallenge;
    final nextUnit = summary.nextUnit;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(unit.title.text)),
      body: levels == null
          ? const Center(child: CircularProgressIndicator())
          : CourseOverview(
              course: course.progressId,
              intro: course.intro,
              levels: levels,
              routeOf: course.stepRoute,
              header: [
                _CourseUnitHeader(
                  unit: unit,
                  summary: summary,
                  done: done,
                  total: total,
                  pending: courseSteps(levels)
                      .where((s) => !progress.isDone(s))
                      .firstOrNull
                      ?.id,
                  firstStep: courseSteps(levels).first.id,
                  course: course,
                ),
                const SizedBox(height: 20),
              ],
              footer: [
                if (challenge != null) ...[
                  const SizedBox(height: 20),
                  _SectionTitle(AppStrings.unitChallenge),
                  _ChallengeStep(challenge: challenge, reachable: total > 0 && done == total),
                ],
                const SizedBox(height: 20),
                _SectionTitle(AppStrings.unitNext),
                if (nextUnit != null)
                  _NextUnit(unit: nextUnit, completed: path.completed)
                else
                  Text(
                    AppStrings.unitEndOfPath,
                    key: const Key('unit-end'),
                    style: text.bodyMedium?.copyWith(color: context.palette.textSecondary),
                  ),
              ],
            ),
    );
  }
}

class _CourseUnitHeader extends StatelessWidget {
  const _CourseUnitHeader({
    required this.unit,
    required this.summary,
    required this.done,
    required this.total,
    required this.pending,
    required this.firstStep,
    required this.course,
  });

  final LessonUnit unit;
  final UnitSummary summary;
  final int done;
  final int total;

  /// El primer paso sin hacer (`null` si está todo hecho).
  final String? pending;
  final String firstStep;
  final LessonCourse course;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (index, units) = summary.position;
    final finished = pending == null;
    final track = unit.track == LessonTrack.foundations
        ? trackName(unit.track)
        : AppStrings.trackLevel(trackName(unit.track), unit.level);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UnitArtView(art: unit.art, size: 88),
            const SizedBox(height: 12),
            Text(
              '$track · ${AppStrings.unitPosition(index, units)}',
              key: const Key('unit-eyebrow'),
              style: text.labelLarge?.copyWith(color: p.accent),
            ),
            const SizedBox(height: 2),
            Text(unit.title.text, key: const Key('unit-title'), style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(unit.summary.text, key: const Key('unit-summary'), style: text.bodyMedium),
            const SizedBox(height: 12),
            Text(
              AppStrings.unitCourseSteps(done, total),
              key: const Key('unit-progress'),
              style: musicMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: finished ? p.success : p.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 6,
                color: finished ? p.success : p.accent,
                backgroundColor: p.surfaceHigh,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('unit-start'),
              onPressed: () => context.push(course.stepRoute(pending ?? firstStep)),
              child: Text(
                finished
                    ? AppStrings.lessonsReview
                    : done == 0
                        ? AppStrings.lessonsStart
                        : AppStrings.lessonsResume,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
