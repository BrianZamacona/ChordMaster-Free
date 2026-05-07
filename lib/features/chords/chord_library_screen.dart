import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/constants/music_theory.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/donation_button.dart';
import '../../models/chord.dart';
import '../../ui/animations.dart';
import 'chord_viewmodel.dart';

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
    final availableTags = chordPrimaryTagOrder
        .where(
          (tag) => state.allChords.any(
            (chord) => chordTags(chord.type, chord.tags).contains(tag),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.moduleChords),
        backgroundColor: AppColors.chords,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: vm.search,
          ),
          _TagFilterRow(
            selected: state.selectedTag,
            availableTags: availableTags,
            onSelected: vm.filterByTag,
          ),
          _RootFilterRow(
            selected: state.selectedRoot,
            onSelected: vm.filterByRoot,
          ),
          _TypeFilterRow(
            selected: state.selectedType,
            types: availableTypes,
            onSelected: vm.filterByType,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Text(
                  '${state.filteredChords.length} results',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: state.searchQuery.isEmpty &&
                          state.selectedRoot == null &&
                          state.selectedType == null &&
                          state.selectedTag == null
                      ? null
                      : () {
                          _searchController.clear();
                          vm.clearFilters();
                        },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text(AppStrings.reset),
                ),
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
                                const Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppStrings.emptyChordsSearch,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _ChordGrid(chords: state.filteredChords),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: DonationButton(),
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

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    required this.selected,
    required this.availableTags,
    required this.onSelected,
  });

  final String? selected;
  final List<String> availableTags;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: availableTags.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final tag = index == 0 ? null : availableTags[index - 1];
            final isSelected = selected == tag || (selected == null && tag == null);
            final label = tag == null ? AppStrings.all : chordTagLabel(tag);
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.chords.withAlpha(190),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 12,
              ),
              onSelected: (_) => onSelected(tag),
            );
          },
        ),
      );
}

class _RootFilterRow extends StatelessWidget {
  const _RootFilterRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: chromaticNotes.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final root = index == 0 ? null : chromaticNotes[index - 1];
            final isSelected = selected == root || (selected == null && root == null);
            return FilterChip(
              label: Text(root ?? AppStrings.all),
              selected: isSelected,
              selectedColor: AppColors.chords,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 12,
              ),
              onSelected: (_) => onSelected(root),
            );
          },
        ),
      );
}

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({
    required this.selected,
    required this.types,
    required this.onSelected,
  });

  final String? selected;
  final List<ChordTypeDefinition> types;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: types.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final type = index == 0 ? null : types[index - 1];
            final isSelected = selected == type?.key || (selected == null && type == null);
            return FilterChip(
              label: Text(type?.displayName ?? AppStrings.all),
              selected: isSelected,
              selectedColor: AppColors.chords.withAlpha(200),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontSize: 12,
              ),
              onSelected: (_) => onSelected(type?.key),
            );
          },
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
        context.go('/chords/$encoded');
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: ChordDiagramWidget(
                  chordName: chord.name,
                  fretPositions: chord.fretPositions,
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
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _DifficultyStars(difficulty: chord.difficulty),
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
            color: AppColors.secondary,
          ),
        ),
      );
}
