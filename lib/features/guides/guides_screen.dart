import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/guides/guide_progress.dart';
import '../../domain/guides/guides.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import 'guides_viewmodel.dart';

/// Catálogo de guías: una fila por categoría, que se desliza de lado, y un
/// buscador que filtra en vivo y oculta las filas que quedan vacías. Arriba,
/// sin búsqueda, las guías empezadas y sin terminar.
class GuidesScreen extends ConsumerStatefulWidget {
  const GuidesScreen({super.key});

  @override
  ConsumerState<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends ConsumerState<GuidesScreen> {
  final _search = TextEditingController();
  var _query = '';

  /// Nivel elegido; `null` = todos.
  GuideLevel? _level;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final found = searchGuides(_query, level: _level).toSet();
    final started = _query.trim().isEmpty
        ? [
            for (final g in ref.watch(guideProgressProvider).inProgress())
              if (_level == null || g.level == _level) g,
          ]
        : const <Guide>[];
    final rows = [
      for (final category in GuideCategory.values)
        (category, [for (final g in guidesIn(category)) if (found.contains(g)) g]),
    ].where((row) => row.$2.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.guidesTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              AppStrings.guidesIntro,
              style: text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              key: const Key('guides-search'),
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.guidesSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('guides-search-clear'),
                        icon: const Icon(Icons.close),
                        tooltip: AppStrings.filterClear,
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              key: const Key('guides-levels'),
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(AppStrings.guidesLevel, style: text.labelLarge),
                ChoiceChip(
                  key: const Key('guides-level-all'),
                  label: Text(AppStrings.guidesAllLevels),
                  selected: _level == null,
                  onSelected: (_) => setState(() => _level = null),
                ),
                for (final l in GuideLevel.values)
                  ChoiceChip(
                    key: Key('guides-level-${l.name}'),
                    label: Text(guideLevelTitle(l).text),
                    selected: _level == l,
                    onSelected: (_) => setState(() => _level = l),
                  ),
              ],
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppStrings.guidesNoResults,
                key: const Key('guides-empty'),
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: p.textSecondary),
              ),
            ),
          if (started.isNotEmpty)
            ..._row(
              context,
              title: AppStrings.guidesInProgress,
              id: 'in-progress',
              items: started,
            ),
          for (final (category, items) in rows)
            ..._row(
              context,
              title: guideCategoryTitle(category).text,
              id: category.name,
              items: items,
            ),
        ],
      ),
    );
  }

  List<Widget> _row(
    BuildContext context, {
    required String title,
    required String id,
    required List<Guide> items,
  }) =>
      [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: Key('guides-category-$id'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        Padding(
          key: Key('guides-row-$id'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            spacing: 8,
            children: [for (final g in items) GuideCard(guide: g)],
          ),
        ),
      ];
}

/// Fila de una guía: el dibujo a la izquierda; título, subtítulo, capítulos,
/// minutos y, si la empezaste, cuánto llevas.
class GuideCard extends ConsumerWidget {
  const GuideCard({super.key, required this.guide});

  final Guide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(guideProgressProvider);
    final done = progress.doneCount(guide);
    final total = guide.chapters.length;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('guide-${guide.id}'),
        onTap: () => context.push('/learn/guides/${guide.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              SizedBox(width: 76, child: UnitArtView(art: guide.art, size: 60)),
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
                      guideLevelTitle(guide.level).text,
                      key: Key('guide-level-${guide.id}'),
                      style: musicMono(fontSize: 11, fontWeight: FontWeight.w600, color: p.accent),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.guideChapters(total)} · '
                            '${AppStrings.guideMinutes(guideMinutes(guide))}',
                            style: musicMono(fontSize: 11, color: p.textSecondary),
                          ),
                        ),
                        if (done > 0)
                          Text(
                            '$done/$total',
                            style: musicMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: done == total ? p.success : p.accent,
                            ),
                          ),
                      ],
                    ),
                    if (done > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        key: Key('guide-card-progress-${guide.id}'),
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: done / total,
                          minHeight: 5,
                          backgroundColor: p.surfaceHigh,
                          color: done == total ? p.success : p.accent,
                        ),
                      ),
                    ],
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
