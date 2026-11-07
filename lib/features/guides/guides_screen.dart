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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final found = searchGuides(_query).toSet();
    final started = _query.trim().isEmpty
        ? ref.watch(guideProgressProvider).inProgress()
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
        // Cada fila tiene pocas guías: se construyen todas y se deslizan.
        SingleChildScrollView(
          key: Key('guides-row-$id'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              for (final g in items)
                SizedBox(height: GuideCard.height, child: GuideCard(guide: g)),
            ],
          ),
        ),
      ];
}

/// Tarjeta de una guía: el dibujo arriba, el título con su subtítulo y, abajo,
/// cuánto llevas o cuánto tarda.
class GuideCard extends ConsumerWidget {
  const GuideCard({super.key, required this.guide});

  // A 360 dp caben dos y asoma la tercera: se nota que la fila se desliza.
  static const width = 148.0;
  static const height = 236.0;

  final Guide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final progress = ref.watch(guideProgressProvider);
    final done = progress.doneCount(guide);
    final total = guide.chapters.length;
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('guide-${guide.id}'),
          onTap: () => context.push('/learn/guides/${guide.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UnitArtView(art: guide.art, size: 72),
                const SizedBox(height: 10),
                Text(
                  guide.title.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    guide.subtitle.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ),
                Text(
                  AppStrings.guideChapters(total),
                  style: musicMono(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 4),
                if (done == 0)
                  Text(
                    AppStrings.guideMinutes(guideMinutes(guide)),
                    style: musicMono(fontSize: 12, color: p.textSecondary),
                  )
                else
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
            ),
          ),
        ),
      ),
    );
  }
}
