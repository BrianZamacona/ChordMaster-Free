import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../ui/theme.dart';
import 'lessons_viewmodel.dart';

/// Ruta de lecciones: Fundamentos y, debajo, el camino elegido.
class LessonsScreen extends ConsumerWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonsViewModelProvider);
    final path = state.path;
    final next = path.next;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.lessonsTitle)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _NextCard(next: next),
                const SizedBox(height: 20),
                _TrackHeader(
                  title: AppStrings.trackFoundations,
                  subtitle: AppStrings.trackFoundationsSub,
                  progress: path.progressOf(LessonTrack.foundations),
                ),
                ..._lessonTiles(LessonTrack.foundations, path, next),
                const SizedBox(height: 20),
                Text(
                  path.foundationsDone
                      ? AppStrings.lessonsChoosePath
                      : AppStrings.lessonsChooseLater,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.palette.textSecondary),
                ),
                const SizedBox(height: 10),
                _TrackChooser(path: path),
                const SizedBox(height: 16),
                ..._lessonTiles(state.chosen, path, next),
              ],
            ),
    );
  }

  List<Widget> _lessonTiles(LessonTrack track, LessonPath path, Lesson? next) {
    final tiles = <Widget>[];
    String? unit;
    for (final lesson in lessonsOf(track)) {
      if (lesson.unit.es != unit) {
        unit = lesson.unit.es;
        tiles.add(_UnitLabel(lesson.unit.text));
      }
      tiles.add(
        _LessonTile(
          lesson: lesson,
          done: path.isDone(lesson),
          isNext: lesson == next,
        ),
      );
    }
    return tiles;
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.next});

  final Lesson? next;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final lesson = next;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: lesson == null
            ? Text(AppStrings.lessonsAllDone, style: text.bodyLarge)
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.lessonsContinue.toUpperCase(),
                          style: text.labelSmall?.copyWith(
                            color: p.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(lesson.title.text, style: text.titleMedium),
                        Text(
                          '${lesson.unit.text} · '
                          '${AppStrings.lessonMinutes(lesson.minutes)}',
                          style: text.bodySmall?.copyWith(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const Key('lessons-start-next'),
                    onPressed: () => context.go('/learn/lessons/${lesson.id}'),
                    child: Text(AppStrings.lessonsStart),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final (int, int) progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (done, total) = progress;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleLarge),
              Text(
                subtitle,
                style: text.bodyMedium
                    ?.copyWith(color: context.palette.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          AppStrings.lessonsProgress(done, total),
          style: musicMono(color: context.palette.textSecondary),
        ),
      ],
    );
  }
}

/// Las dos tarjetas de camino, con el avance de cada uno.
class _TrackChooser extends ConsumerWidget {
  const _TrackChooser({required this.path});

  final LessonPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, track) in [LessonTrack.rhythm, LessonTrack.lead].indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _TrackCard(
                track: track,
                selected: path.chosen == track,
                progress: path.progressOf(track),
                onTap: () =>
                    ref.read(lessonsViewModelProvider.notifier).choose(track),
              ),
            ),
          ],
        ],
      );
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.selected,
    required this.progress,
    required this.onTap,
  });

  final LessonTrack track;
  final bool selected;
  final (int, int) progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (done, total) = progress;
    final (title, subtitle, icon) = switch (track) {
      LessonTrack.lead => (
          AppStrings.trackLead,
          AppStrings.trackLeadSub,
          Icons.linear_scale,
        ),
      _ => (
          AppStrings.trackRhythm,
          AppStrings.trackRhythmSub,
          Icons.library_music_outlined,
        ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? p.accent : p.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: Key('lessons-track-${track.name}'),
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: selected ? p.accent : p.textSecondary),
                const SizedBox(height: 6),
                Text(title, style: text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  color: p.accent,
                  backgroundColor: p.surfaceHigh,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.lessonsProgress(done, total),
                  style: musicMono(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitLabel extends StatelessWidget {
  const _UnitLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.done,
    required this.isNext,
  });

  final Lesson lesson;
  final bool done;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (badgeColor, badgeText) = done
        ? (p.success, p.onAccent)
        : isNext
            ? (p.accent, p.onAccent)
            : (p.surfaceHigh, p.textSecondary);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext ? BorderSide(color: p.accent) : BorderSide.none,
      ),
      child: InkWell(
        key: Key('lesson-${lesson.id}'),
        onTap: () => context.go('/learn/lessons/${lesson.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: badgeColor,
                child: done
                    ? Icon(Icons.check, color: badgeText, size: 20)
                    : Text(
                        LessonPath.labelOf(lesson),
                        style: musicMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title.text, style: text.titleSmall),
                    Text(
                      AppStrings.lessonMinutes(lesson.minutes),
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              if (done)
                Text(
                  AppStrings.lessonDone,
                  style: text.labelMedium?.copyWith(color: p.success),
                )
              else if (isNext)
                Text(
                  AppStrings.lessonNext,
                  style: text.labelMedium?.copyWith(color: p.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
