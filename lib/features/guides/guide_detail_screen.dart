import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/guides/guides.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import 'guide_navigation.dart';

/// Una guía: qué es y sus capítulos en orden; cada uno abre la lección, la
/// escala, el acorde o el módulo que enlaza.
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
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(guide.title.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
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
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.guideChapters(guide.chapters.length),
                    style: musicMono(fontSize: 12, color: p.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final (i, chapter) in guide.chapters.indexed)
            Card(
              key: Key('guide-chapter-$i'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: p.surfaceHigh,
                          child: Text(
                            '${i + 1}',
                            style: musicMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(chapter.title.text, style: text.titleSmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(chapter.body.text, style: text.bodyMedium),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: Key('guide-open-$i'),
                        icon: Icon(guideTargetIcon(chapter.target)),
                        label: Text(
                          guideTargetLabel(chapter.target),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () =>
                            openGuideTarget(context, ref, chapter.target),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
