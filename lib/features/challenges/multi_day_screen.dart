import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/practice/multi_day_challenges.dart';
import '../../services/activity_log.dart';
import '../../ui/theme.dart';

/// Retos de varios días: cada uno con los días de la semana (o la racha) que
/// ya cuentan y un botón al módulo que lo mueve. Se superan solos.
class MultiDayChallengesScreen extends ConsumerWidget {
  const MultiDayChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(activityLogProvider);
    final today = DateTime.now();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final passed = [
      for (final c in multiDayChallenges)
        if (challengeDays(c, log, today) >= c.goal) c,
    ].length;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.hubMultiDay)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.multiDayIntro,
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.multiDayPassed(passed, multiDayChallenges.length),
            key: const Key('multi-day-summary'),
            style: musicMono(fontSize: 13, fontWeight: FontWeight.w600, color: p.accent),
          ),
          const SizedBox(height: 8),
          for (final c in multiDayChallenges)
            _ChallengeCard(challenge: c, log: log, today: today),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.log,
    required this.today,
  });

  final MultiDayChallenge challenge;
  final Map<PracticeActivity, Set<String>> log;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final count = challengeDays(challenge, log, today);
    final done = count >= challenge.goal;
    final days = daysFor(challenge, log);
    // Los días reales, del más viejo a hoy (a la derecha). En los seguidos se
    // muestran tantos como pide la racha.
    final dots = [
      for (final d in windowDays(
        days,
        today,
        challenge.consecutive ? challenge.goal : challenge.window,
      ))
        d.practiced,
    ];
    final route = _route(challenge.activity);
    return Card(
      key: Key('multi-day-${challenge.id}'),
      shape: done
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: p.success, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(challenge.title.text, style: text.titleSmall)),
                Text(
                  done
                      ? AppStrings.challengePassed
                      : '$count/${challenge.goal}',
                  key: Key('multi-day-status-${challenge.id}'),
                  style: musicMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: done ? p.success : p.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              challenge.body.text,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final (i, filled) in dots.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? (done ? p.success : p.accent) : p.surfaceHigh,
                      border: filled ? null : Border.all(color: p.outline),
                    ),
                    child: filled
                        ? Icon(Icons.check, size: 14, color: p.onAccent)
                        : null,
                  ),
                ],
              ],
            ),
            if (route != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: Key('multi-day-open-${challenge.id}'),
                  onPressed: () => context.go(route.$1),
                  child: Text(route.$2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (String, String)? _route(PracticeActivity? activity) => switch (activity) {
        null => null,
        PracticeActivity.lessons => ('/learn/lessons', AppStrings.lessonsTitle),
        PracticeActivity.workouts => ('/practice/workouts', AppStrings.hubWorkouts),
        PracticeActivity.technique => ('/practice/technique', AppStrings.hubTechnique),
        PracticeActivity.ear => ('/practice/ear-training', AppStrings.hubEar),
        PracticeActivity.rhythm => ('/practice/rhythm', AppStrings.hubRhythm),
      };
}
