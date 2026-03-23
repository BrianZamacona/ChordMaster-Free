import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/donation_button.dart';
import '../../models/chord.dart';
import '../../ui/animations.dart';
import 'chord_viewmodel.dart';

const List<String> _chordTypes = [
  'major',
  'minor',
  'dominant7',
  'major7',
  'minor7',
  'diminished',
  'augmented',
  'sus2',
  'sus4',
];

const Map<String, String> _typeLabels = {
  'major': 'Major',
  'minor': 'Minor',
  'dominant7': 'Dom 7',
  'major7': 'Maj 7',
  'minor7': 'Min 7',
  'diminished': 'Dim',
  'augmented': 'Aug',
  'sus2': 'Sus2',
  'sus4': 'Sus4',
};

/// Chord library screen with search, root/type filters, and chord card grid.
///
/// This widget does not include a [Scaffold] — the shell route provides one.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.moduleChords),
        backgroundColor: AppColors.chords,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onChanged: vm.search,
          ),
          _RootFilterRow(
            selected: state.selectedRoot,
            onSelected: vm.filterByRoot,
          ),
          _TypeFilterRow(
            selected: state.selectedType,
            onSelected: vm.filterByType,
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
                                const Icon(Icons.search_off,
                                    size: 48, color: AppColors.textSecondary),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
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
    );
  }
}

class _RootFilterRow extends StatelessWidget {
  const _RootFilterRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: chromaticNotes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final root = chromaticNotes[i];
          final isSelected = selected == root;
          return FilterChip(
            label: Text(root),
            selected: isSelected,
            selectedColor: AppColors.chords,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontSize: 12,
            ),
            onSelected: (_) => onSelected(isSelected ? null : root),
          );
        },
      ),
    );
  }
}

class _TypeFilterRow extends StatelessWidget {
  const _TypeFilterRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _chordTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final type = _chordTypes[i];
          final label = _typeLabels[type] ?? type;
          final isSelected = selected == type;
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            selectedColor: AppColors.chords.withAlpha(200),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontSize: 12,
            ),
            onSelected: (_) => onSelected(isSelected ? null : type),
          );
        },
      ),
    );
  }
}

class _ChordGrid extends StatelessWidget {
  const _ChordGrid({required this.chords});

  final List<Chord> chords;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
}

class _ChordCard extends StatelessWidget {
  const _ChordCard({required this.chord});

  final Chord chord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                ),
              ),
              const SizedBox(height: 6),
              Text(
                chord.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < difficulty ? Icons.star : Icons.star_border,
          size: 12,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
