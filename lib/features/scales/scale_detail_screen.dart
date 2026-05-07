import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/music_theory.dart';
import '../../core/widgets/donation_button.dart';
import '../../services/audio_service.dart';
import '../../ui/animations.dart';
import 'scales_viewmodel.dart';

/// Detail screen for a single scale identified by [scaleId] (URL-encoded name).
class ScaleDetailScreen extends ConsumerWidget {
  /// Creates a [ScaleDetailScreen] for the scale with [scaleId].
  const ScaleDetailScreen({super.key, required this.scaleId});

  /// URL-encoded scale name from path parameter `:id`.
  final String scaleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scalesViewModelProvider);
    final vm = ref.read(scalesViewModelProvider.notifier);
    final decodedName = Uri.decodeComponent(scaleId);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(decodedName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final scale = vm.findByName(decodedName);

    if (scale == null) {
      return Scaffold(
        appBar: AppBar(title: Text(decodedName)),
        body: Center(
          child: Text(
            AppStrings.errorGeneric,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final notes = _computeNotes(scale.root, scale.intervals);
    final intervalLabels = scale.intervals
        .map((i) => intervalNames[i] ?? '$i semitones')
        .toList();
    final typeName = scaleDisplayNames[scale.type] ?? scale.type;

    return Scaffold(
      appBar: AppBar(
        title: Text(scale.name),
        backgroundColor: AppColors.scales,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            slideUpFade(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scale.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          typeName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.scales),
                        ),
                      ],
                    ),
                  ),
                  _PlayScaleButton(notes: notes),
                ],
              ),
            ),
            const SizedBox(height: 20),
            fadeIn(
              _SectionCard(
                title: AppStrings.scaleNotes,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: notes
                      .map(
                        (n) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.scales.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: AppColors.scales.withAlpha(90)),
                          ),
                          child: Text(
                            n,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.scales,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            fadeIn(
              _SectionCard(
                title: AppStrings.scaleIntervals,
                child: Wrap(
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
              ),
            ),
            const SizedBox(height: 12),
            fadeIn(
              _SectionCard(
                title: AppStrings.scaleDescription,
                child: Text(
                  scale.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            fadeIn(
              _SectionCard(
                title: AppStrings.commonUsage,
                child: Text(
                  scale.commonUsage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            if (scale.relatedChords.isNotEmpty) ...[
              const SizedBox(height: 12),
              fadeIn(
                _SectionCard(
                  title: AppStrings.relatedChords,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: scale.relatedChords
                        .map(
                          (chord) => Chip(
                            label: Text(
                              chord,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.scales.withAlpha(25),
                            side: BorderSide(
                                color: AppColors.scales.withAlpha(70)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Center(child: DonationButton()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<String> _computeNotes(String root, List<int> intervals) {
    final rootIdx = chromaticNotes.indexOf(root);
    if (rootIdx == -1) return [];
    return intervals.map((i) => chromaticNotes[(rootIdx + i) % 12]).toList();
  }
}

class _PlayScaleButton extends StatefulWidget {
  const _PlayScaleButton({required this.notes});

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
      debugPrint('ScaleDetailScreen._play error: $e');
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _play,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _isPlaying
                ? AppColors.scales.withAlpha(150)
                : AppColors.scales,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.scales.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _isPlaying ? Icons.volume_up : Icons.play_arrow,
            color: Colors.white,
            size: 28,
          ),
        ),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.scales,
                    ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}
