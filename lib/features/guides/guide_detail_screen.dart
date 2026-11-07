import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/guides/guide_progress.dart';
import '../../domain/guides/guides.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import 'guide_navigation.dart';
import 'guides_viewmodel.dart';

/// Una guía: qué es, cuánto tarda y cuánto llevas; sus capítulos en orden,
/// cada uno con su enlace y su marca de hecho; al final, la guía que sigue.
class GuideDetailScreen extends ConsumerWidget {
  const GuideDetailScreen({super.key, required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = guidesById[guideId];
    if (guide == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.guidesTitle)),
        body: Center(child: Text(AppStrings.guideNotFound)),
      );
    }
    final progress = ref.watch(guideProgressProvider);
    final next = progress.nextChapter(guide);
    final nextGuide = progress.nextGuide(guide);
    return Scaffold(
      appBar: AppBar(title: Text(guide.title.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _GuideHeader(guide: guide, progress: progress),
          const SizedBox(height: 8),
          for (final (i, chapter) in guide.chapters.indexed)
            _ChapterCard(
              index: i,
              chapter: chapter,
              done: progress.isDone(guide, i),
              // Solo se señala el siguiente si ya empezaste.
              isNext: i == next && progress.doneCount(guide) > 0,
              onToggle: () =>
                  ref.read(guideChecksProvider.notifier).toggle(guide, i),
              onOpen: () => openGuideTarget(context, ref, chapter.target),
            ),
          if (nextGuide != null) ...[
            const SizedBox(height: 16),
            _NextGuide(guide: nextGuide),
          ],
        ],
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.guide, required this.progress});

  final Guide guide;
  final GuideProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final done = progress.doneCount(guide);
    final total = guide.chapters.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UnitArtView(art: guide.art, size: 88),
            const SizedBox(height: 12),
            Text(
              guideCategoryTitle(guide.category).text,
              style: text.labelMedium?.copyWith(color: p.textSecondary),
            ),
            Text(
              guide.title.text,
              key: const Key('guide-title'),
              style: text.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(guide.subtitle.text, style: text.bodyMedium),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.guideChapters(total)} · '
              '${AppStrings.guideMinutes(guideMinutes(guide))}',
              key: const Key('guide-meta'),
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: done / total,
                minHeight: 6,
                backgroundColor: p.surfaceHigh,
                color: progress.isFinished(guide) ? p.success : p.accent,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.guideDoneCount(done, total),
                    key: const Key('guide-progress'),
                    style: musicMono(fontSize: 12, color: p.textSecondary),
                  ),
                ),
                if (progress.isFinished(guide))
                  Row(
                    key: const Key('guide-finished'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 18, color: p.success),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.guideFinished,
                        style: text.labelLarge?.copyWith(color: p.success),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.index,
    required this.chapter,
    required this.done,
    required this.isNext,
    required this.onToggle,
    required this.onOpen,
  });

  final int index;
  final GuideChapter chapter;
  final bool done;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Card(
      key: Key('guide-chapter-$index'),
      shape: isNext
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: p.accent, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done ? p.success : p.surfaceHigh,
                  child: done
                      ? Icon(Icons.check, size: 16, color: p.onAccent)
                      : Text(
                          '${index + 1}',
                          style: musicMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.accent,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isNext)
                        Text(
                          AppStrings.guideContinueHere,
                          key: Key('guide-next-chapter-$index'),
                          style: text.labelSmall?.copyWith(color: p.accent),
                        ),
                      Text(chapter.title.text, style: text.titleSmall),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('guide-check-$index'),
                  tooltip: done
                      ? AppStrings.guideMarkPending
                      : AppStrings.guideMarkDone,
                  icon: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? p.success : p.textSecondary,
                  ),
                  onPressed: onToggle,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(chapter.body.text, style: text.bodyMedium),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: OutlinedButton.icon(
                    key: Key('guide-open-$index'),
                    icon: Icon(guideTargetIcon(chapter.target)),
                    label: Text(
                      guideTargetLabel(chapter.target),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onOpen,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.guideMinutes(chapterMinutes(chapter.target)),
                  style: musicMono(fontSize: 12, color: p.textSecondary),
                ),
                // El resto de la tarjeta tiene 14 a la derecha; la fila de
                // arriba deja 6 para que el círculo de marcar no se achique.
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// La guía que conviene después: reemplaza a esta, así atrás vuelve al
/// catálogo y no se apilan guías.
class _NextGuide extends StatelessWidget {
  const _NextGuide({required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.guideNext, style: text.titleMedium),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('guide-next'),
            onTap: () => context.pushReplacement('/learn/guides/${guide.id}'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(width: 72, child: UnitArtView(art: guide.art, size: 56)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guide.title.text, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          guide.subtitle.text,
                          style: text.bodySmall?.copyWith(color: p.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.guideMinutes(guideMinutes(guide)),
                          style: musicMono(fontSize: 12, color: p.textSecondary),
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
      ],
    );
  }
}
