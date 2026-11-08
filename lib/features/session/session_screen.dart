import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/session_summary.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../services/session_log.dart';
import '../../ui/theme.dart';
import '../courses/course_registry.dart';

/// "Tu sesión de hoy": lo tocado con el micrófono, lo que conviene repetir
/// (renglón, errores y un tempo más lento) y lo que salió limpio. Cada cosa
/// abre su paso o su ejercicio.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionLogProvider);
    final s = ref.read(sessionLogProvider.notifier).summary;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.sessionTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: s.isEmpty
            ? [
                Text(
                  AppStrings.sessionEmpty,
                  key: const Key('session-empty'),
                  style: text.bodyLarge?.copyWith(color: p.textSecondary),
                ),
              ]
            : [
                _Totals(summary: s),
                if (s.toRepeat.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(AppStrings.sessionToRepeat, style: text.titleMedium),
                  const SizedBox(height: 6),
                  for (final r in s.toRepeat)
                    _TargetTile(
                      key: Key('session-repeat-${r.target.key}'),
                      target: r.target,
                      icon: Icons.replay,
                      detail: AppStrings.sessionRepeatDetail(r.line, r.mistakes, r.slowerBpm),
                      color: p.warning,
                    ),
                ],
                if (s.cleanToday.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(AppStrings.sessionCleanToday, style: text.titleMedium),
                  const SizedBox(height: 6),
                  for (final c in s.cleanToday)
                    _TargetTile(
                      key: Key('session-clean-${c.target.key}'),
                      target: c.target,
                      icon: Icons.check_circle,
                      detail: [
                        AppStrings.sessionBest(c.bestBpm),
                        if (s.records[c.target.key] case final rec?)
                          AppStrings.sessionNewRecord(rec),
                      ].join(' · '),
                      color: p.success,
                    ),
                ],
              ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    Widget total(String key, int value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            key: Key(key),
            style: musicMono(fontSize: 26, fontWeight: FontWeight.w600, color: p.textPrimary),
          ),
          Text(label, style: text.bodySmall?.copyWith(color: p.textSecondary)),
        ],
      ),
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            total('session-runs', summary.runs, AppStrings.sessionRuns),
            total('session-clean', summary.cleanRuns, AppStrings.sessionCleanRuns),
            total('session-records', summary.records.length, AppStrings.sessionRecords),
          ],
        ),
      ),
    );
  }
}

/// Una cosa tocada hoy: su nombre, de dónde es, el detalle y el enlace.
class _TargetTile extends ConsumerWidget {
  const _TargetTile({
    super.key,
    required this.target,
    required this.icon,
    required this.detail,
    required this.color,
  });

  final RunTarget target;
  final IconData icon;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (title, place, route) = _describe(ref, target);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    Text(place, style: text.bodySmall?.copyWith(color: p.textSecondary)),
                    const SizedBox(height: 2),
                    Text(detail, style: musicMono(fontSize: 13, color: p.textPrimary)),
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

/// Nombre, lugar y ruta de [target]. Un paso que ya no existe (ids viejos)
/// lleva a su curso.
(String, String, String) _describe(WidgetRef ref, RunTarget target) {
  switch (target) {
    case CourseStepTarget(:final course, :final stepId):
      final c = LessonCourse.values.where((x) => x.name == course).firstOrNull;
      if (c == null) return (stepId, '', '/learn/lessons');
      final levels = watchCourseLevels(ref, c);
      final step = levels == null
          ? null
          : courseSteps(levels).where((s) => s.id == stepId).firstOrNull;
      final unit = unitOfCourse(c);
      return (
        step?.title.text ?? unit.title.text,
        unit.title.text,
        step == null ? '/learn/lessons/unit/${unit.id}' : c.stepRoute(stepId),
      );
    case TechniqueTarget(:final exercise, :final startFret):
      return (
        techniqueName(exercise).text,
        AppStrings.sessionTechniqueFrom(startFret),
        '/practice/technique',
      );
  }
}
