import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';
import '../../core/widgets/donation_button.dart';
import '../../models/scale.dart';
import '../../services/audio_service.dart';
import '../../ui/animations.dart';
import 'modes_screen.dart';
import 'scales_viewmodel.dart';

/// Scales reference screen with Scales / Modes / Exotic tabs.
class ScalesScreen extends ConsumerStatefulWidget {
  /// Creates the [ScalesScreen].
  const ScalesScreen({super.key});

  @override
  ConsumerState<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends ConsumerState<ScalesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final cat = ScaleCategory.all[_tabController.index];
        ref.read(scalesViewModelProvider.notifier).filterByCategory(cat);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scalesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.moduleScales),
        backgroundColor: AppColors.scales,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: ScaleCategory.all
              .map((cat) => Tab(text: cat))
              .toList(),
        ),
      ),
      body: Column(
        children: [
          _RootNoteSelector(
            selectedRoot: state.selectedRoot,
            onSelected:
                ref.read(scalesViewModelProvider.notifier).filterByRoot,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ScalesTabContent(category: ScaleCategory.scales),
                const ModesScreen(),
                _ScalesTabContent(category: ScaleCategory.exotic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RootNoteSelector extends StatelessWidget {
  const _RootNoteSelector({
    required this.selectedRoot,
    required this.onSelected,
  });

  final String selectedRoot;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scales.withAlpha(20),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chromaticNotes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final root = chromaticNotes[i];
          final isSelected = selectedRoot == root;
          return ChoiceChip(
            label: Text(root),
            selected: isSelected,
            selectedColor: AppColors.scales,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : null,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) => onSelected(root),
          );
        },
      ),
    );
  }
}

/// Renders the list of scales for a given category tab.
class _ScalesTabContent extends ConsumerWidget {
  const _ScalesTabContent({required this.category});

  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scalesViewModelProvider);
    final vm = ref.read(scalesViewModelProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Text(
          AppStrings.errorGeneric,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final scales = state.filteredScales;

    if (scales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_off,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              AppStrings.emptyScalesSearch,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: scales.length + 1,
      itemBuilder: (context, index) {
        if (index == scales.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: DonationButton()),
          );
        }
        final scale = scales[index];
        return slideUpFade(
          _ScaleCard(
            scale: scale,
            isSelected: state.selectedScale == scale,
            onTap: () => vm.selectScale(scale),
          ),
          duration: Duration(milliseconds: 150 + index * 30),
        );
      },
    );
  }
}

class _ScaleCard extends ConsumerWidget {
  const _ScaleCard({
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  final Scale scale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = _computeNotes(scale);
    final intervalLabels = scale.intervals
        .map((i) => intervalNames[i] ?? '$i')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? const BorderSide(color: AppColors.scales, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scale.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scale.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PlayScaleButton(scale: scale, notes: notes),
                ],
              ),
              const SizedBox(height: 10),
              // Notes chips
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: notes
                    .map(
                      (n) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.scales.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          n,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.scales,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (isSelected) ...[
                const SizedBox(height: 10),
                const Divider(),
                // Interval chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: intervalLabels
                      .map(
                        (l) => Chip(
                          label: Text(l, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.commonUsage,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  scale.commonUsage,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<String> _computeNotes(Scale scale) {
    final rootIdx = chromaticNotes.indexOf(scale.root);
    if (rootIdx == -1) return [];
    return scale.intervals
        .map((i) => chromaticNotes[(rootIdx + i) % 12])
        .toList();
  }
}

class _PlayScaleButton extends StatefulWidget {
  const _PlayScaleButton({required this.scale, required this.notes});

  final Scale scale;
  final List<String> notes;

  @override
  State<_PlayScaleButton> createState() => _PlayScaleButtonState();
}

class _PlayScaleButtonState extends State<_PlayScaleButton> {
  bool _isPlaying = false;

  Future<void> _play() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      for (final note in widget.notes) {
        final file =
            'assets/audio/notes/${note.replaceAll('#', 's')}4.mp3';
        await AudioService.instance.playNote(file);
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    } catch (e) {
      debugPrint('_PlayScaleButton._play error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isPlaying ? Icons.volume_up : Icons.play_circle_outline,
        color: AppColors.scales,
        size: 28,
      ),
      tooltip: AppStrings.play,
      onPressed: _play,
    );
  }
}
