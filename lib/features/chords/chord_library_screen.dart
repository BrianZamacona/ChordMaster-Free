import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/constants/chord_texts.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../models/chord.dart';
import '../../ui/animations.dart';
import '../../ui/palette.dart';
import '../../ui/section_routes.dart';
import 'chord_filters.dart';
import 'chord_viewmodel.dart';
import 'fingering_selection.dart';

/// Chord library screen with search, style/root/type filters, and chord card grid.
class ChordLibraryScreen extends ConsumerStatefulWidget {
  /// Creates the [ChordLibraryScreen].
  const ChordLibraryScreen({super.key});

  @override
  ConsumerState<ChordLibraryScreen> createState() =>
      _ChordLibraryScreenState();
}

class _ChordLibraryScreenState extends ConsumerState<ChordLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chordViewModelProvider);
    final vm = ref.read(chordViewModelProvider.notifier);
    final theme = Theme.of(context);
    final availableTypes = orderedChordTypes(
      state.allChords.map((chord) => chord.type),
    );
    final hasActiveFilters = state.searchQuery.isNotEmpty ||
        state.selectedRoot != ChordViewModel.defaultRoot ||
        state.selectedType != null ||
        state.selectedTag != null;
    final availableTags = chordPrimaryTagOrder
        .where(
          (tag) => state.allChords.any(
            (chord) => chordTags(chord.type, chord.tags).contains(tag),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.moduleChords),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: vm.search,
          ),
          const SizedBox(height: 4),
          ChordFilterBar(
            root: state.selectedRoot,
            type: state.selectedType,
            tag: state.selectedTag,
            availableTypes: [for (final t in availableTypes) t.key],
            availableTags: availableTags,
            onRoot: vm.filterByRoot,
            onType: vm.filterByType,
            onTag: vm.filterByTag,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Text(
                  AppStrings.chordsCount(state.filteredChords.length),
                  key: const Key('chords-count'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                const Spacer(),
                if (hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      vm.clearFilters();
                    },
                    child: Text(AppStrings.filterClearAll),
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errorMessage != null
                    ? Center(
                        child: Text(
                          AppStrings.errorGeneric,
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : state.filteredChords.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: context.palette.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppStrings.emptyChordsSearch,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: context.palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : state.filteredChords.length == 1
                            // Un solo acorde (p. ej. raíz C + tipo Mayor):
                            // se ven todas sus posiciones, no solo la abierta.
                            ? _SingleChordPositions(chord: state.filteredChords.first)
                            : _ChordGrid(chords: state.filteredChords),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      );
}




class _ChordGrid extends StatelessWidget {
  const _ChordGrid({required this.chords});

  final List<Chord> chords;

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: chords.length,
        itemBuilder: (context, index) {
          final chord = chords[index];
          return scaleIn(
            _ChordCard(chord: chord),
            duration: Duration(milliseconds: 200 + (index % 6) * 30),
          );
        },
      );
}

class _ChordCard extends StatelessWidget {
  const _ChordCard({required this.chord});

  final Chord chord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = chordDisplayName(
      root: chord.root,
      type: chord.type,
      explicitDisplayName: chord.displayName,
    );

    return GestureDetector(
      onTap: () {
        final encoded = Uri.encodeComponent(chord.name);
        context.go(context.sectionPath('chords/$encoded'));
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: ChordDiagramWidget(
                  chordName: chord.name,
                  fretPositions: chord.fretPositions,
                  fingerPositions: chord.fingerPositions,
                  root: chord.root,
                  size: 120,
                  showChordName: false,
                  baseFret: chord.baseFret,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                chordTypeLabel(chord.type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.palette.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _DifficultyStars(difficulty: chord.difficulty),
              const SizedBox(height: 2),
              Text(
                AppStrings.positionsCount(positionCount(chord)),
                key: Key('positions-${chord.name}'),
                style: theme.textTheme.labelSmall?.copyWith(color: context.palette.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  const _DifficultyStars({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Icon(
            index < difficulty ? Icons.star : Icons.star_border,
            size: 12,
            color: context.palette.accent,
          ),
        ),
      );
}

/// Todas las digitaciones de un acorde, agrupadas por sección. Tocar una
/// abre el explorador (donde se pueden comparar).
class _SingleChordPositions extends StatelessWidget {
  const _SingleChordPositions({required this.chord});

  final Chord chord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;
    final encoded = Uri.encodeComponent(chord.name);
    final name = chordDisplayName(
      root: chord.root,
      type: chord.type,
      explicitDisplayName: chord.displayName,
    );
    final shared = sharedShapeLabels(chord.cagedPositions);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        final width = (constraints.maxWidth - 24 - gap * (columns - 1)) / columns;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          children: [
            Text(
              AppStrings.allPositionsOf(name, positionCount(chord)),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go(context.sectionPath('chords/$encoded')),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(AppStrings.openDetail),
                ),
                OutlinedButton.icon(
                  key: const Key('open-explorer'),
                  onPressed: () => context.go(context.sectionPath('chords/$encoded/explorer')),
                  icon: const Icon(Icons.compare_arrows, size: 18),
                  label: Text(AppStrings.openExplorerToCompare),
                ),
              ],
            ),
            for (final section in compareSections)
              if (sectionItems(chord, section).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  section == 'caged' ? AppStrings.cagedPositions : sectionTitle(section),
                  style: theme.textTheme.titleSmall?.copyWith(color: p.accent),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (i, item) in sectionItems(chord, section).indexed)
                      SizedBox(
                        width: width,
                        child: Card(
                          key: Key('position-$section-$i'),
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.go(context.sectionPath('chords/$encoded/explorer')),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text(
                                    section == 'main'
                                        ? AppStrings.compareMainSection
                                        : section == 'caged'
                                            ? shared[i] ?? chordDataText(item.title)
                                            : chordDataText(item.title),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  ChordDiagramWidget(
                                    chordName: item.title,
                                    fretPositions: item.fretPositions,
                                    fingerPositions: item.fingerPositions,
                                    root: chord.root,
                                    baseFret: item.baseFret,
                                    size: (width - 16).clamp(90, 150).toDouble(),
                                    showChordName: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
          ],
        );
      },
    );
  }
}
