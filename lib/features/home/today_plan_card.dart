import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/scale_names.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../domain/practice/daily_plan.dart';
import '../../domain/practice/multi_day_challenges.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../domain/theory/notes.dart';
import '../../services/activity_log.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import '../lessons/lessons_viewmodel.dart';

/// "Práctica de hoy": la siguiente lección, la rutina y la técnica del día,
/// con su marca de hecho, y el avance de los retos de la semana.
class TodayPlanCard extends ConsumerWidget {
  const TodayPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final log = ref.watch(activityLogProvider);
    final next = ref.watch(learningPathProvider.select((p) => p.next));
    final today = DateTime.now();
    bool doneToday(PracticeActivity a) => log[a]?.contains(dayKey(today)) ?? false;
    final done = dailyPlanDone(log, today);
    final total = dailyPlanActivities.length;
    final scale = dailyWorkoutScale(today);
    final exercise = dailyTechnique(today);
    final passed = [
      for (final c in multiDayChallenges)
        if (challengeDays(c, log, today) >= c.goal) c,
    ].length;

    return Card(
      key: const Key('today-plan'),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppStrings.todayPlanTitle, style: text.titleMedium),
                  ),
                  Text(
                    done == total
                        ? AppStrings.todayPlanDone
                        : AppStrings.lessonsProgress(done, total),
                    key: const Key('today-plan-progress'),
                    style: musicMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: done == total ? p.success : p.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: done / total,
                  minHeight: 6,
                  color: done == total ? p.success : p.accent,
                  backgroundColor: p.surfaceHigh,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _Step(
              key: const Key('today-lesson'),
              icon: Icons.school_outlined,
              title: switch (next) {
                null => AppStrings.todayLessonsAllDone,
                NextLesson(:final lesson) => AppStrings.guideOpenLesson(lesson.title.text),
                NextCourse(:final unit) => AppStrings.guideOpenLesson(unit.title.text),
              },
              subtitle: switch (next) {
                null => AppStrings.lessonsReview,
                NextLesson(:final lesson) =>
                  '${LessonPath.labelOf(lesson)} · ${AppStrings.lessonMinutes(lesson.minutes)}',
                NextCourse(:final unit) => trackName(unit.track),
              },
              done: doneToday(PracticeActivity.lessons),
              onTap: () => context.go(switch (next) {
                null => '/learn/lessons',
                NextLesson(:final lesson) => '/learn/lessons/${lesson.id}',
                NextCourse(:final unit) => '/learn/lessons/unit/${unit.id}',
              }),
            ),
            _Step(
              key: const Key('today-workout'),
              icon: Icons.fitness_center,
              title: AppStrings.todayWorkout(
                '${pitchClassName(scale.root)} ${scaleDisplayName(scale.scaleId, const [])}',
              ),
              subtitle: AppStrings.todayWorkoutHint,
              done: doneToday(PracticeActivity.workouts),
              onTap: () => context.go(
                '/practice/workouts?scale=${scale.scaleId}&root=${scale.root}',
              ),
            ),
            _Step(
              key: const Key('today-technique'),
              icon: Icons.back_hand_outlined,
              title: AppStrings.todayTechnique(techniqueName(exercise).text),
              subtitle: AppStrings.todayTechniqueHint,
              done: doneToday(PracticeActivity.technique),
              onTap: () => context.go('/practice/technique'),
            ),
            const Divider(height: 8),
            TextButton.icon(
              key: const Key('today-challenges'),
              style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              icon: const Icon(Icons.event_available),
              label: Text(
                '${AppStrings.hubMultiDay} · '
                '${AppStrings.multiDayPassed(passed, multiDayChallenges.length)}',
              ),
              onPressed: () => context.go('/practice/challenges'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? p.success : p.surfaceHigh,
              ),
              child: Icon(
                done ? Icons.check : icon,
                size: 20,
                color: done ? p.onAccent : p.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
