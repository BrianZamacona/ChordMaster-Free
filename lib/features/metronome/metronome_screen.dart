import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/donation_button.dart';
import 'metronome_viewmodel.dart';

/// Full-featured metronome screen.
class MetronomeScreen extends ConsumerStatefulWidget {
  /// Creates [MetronomeScreen].
  const MetronomeScreen({super.key});

  @override
  ConsumerState<MetronomeScreen> createState() => _MetronomeScreenState();
}

class _MetronomeScreenState extends ConsumerState<MetronomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _beatController;

  @override
  void initState() {
    super.initState();
    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _beatController.dispose();
    ref.read(metronomeViewModelProvider.notifier).stopMetronome();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeViewModelProvider);
    final vm = ref.read(metronomeViewModelProvider.notifier);

    // Trigger beat flash animation
    ref.listen<MetronomeState>(metronomeViewModelProvider, (prev, next) {
      if (prev?.currentBeat != next.currentBeat && next.isPlaying) {
        _beatController.forward(from: 0);
      }
    });

    final timeSigs = ['2/4', '3/4', '4/4', '5/4', '6/8', '7/8', '9/8', '11/8', '12/8'];
    final subdivisions = ['quarter', 'eighth', 'sixteenth', 'triplet'];
    final subdivisionLabels = ['♩ Quarter', '♪ Eighth', '♬ Sixteenth', '♪♪♪ Triplet'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.moduleMetronome),
        backgroundColor: AppColors.metronome,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isPlaying ? vm.stopMetronome : vm.startMetronome,
        backgroundColor: AppColors.metronome,
        icon: Icon(state.isPlaying ? Icons.stop : Icons.play_arrow),
        label: Text(state.isPlaying ? AppStrings.stop : AppStrings.play),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Beat indicators
            _BeatIndicator(
              totalBeats: state.totalBeats,
              currentBeat: state.currentBeat,
              isPlaying: state.isPlaying,
              beatController: _beatController,
            ),
            const SizedBox(height: 24),

            // BPM display
            Center(
              child: Text(
                '${state.bpm}',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 80, fontWeight: FontWeight.bold, color: AppColors.metronome),
              ),
            ),
            Center(
              child: Text(AppStrings.bpm,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),

            // BPM slider
            Slider(
              value: state.bpm.toDouble(),
              min: 20,
              max: 300,
              divisions: 280,
              activeColor: AppColors.metronome,
              label: '${state.bpm}',
              onChanged: (v) => vm.setBpm(v.round()),
            ),

            // +/- buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () => vm.setBpm(state.bpm - 1),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(backgroundColor: AppColors.metronome),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => vm.tapTempo(DateTime.now()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(AppStrings.tap),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  onPressed: () => vm.setBpm(state.bpm + 1),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: AppColors.metronome),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time signature
            Text(AppStrings.timeSignature,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: timeSigs.map((ts) => ChoiceChip(
                  label: Text(ts),
                  selected: state.timeSignature == ts,
                  selectedColor: AppColors.metronome,
                  onSelected: (_) => vm.setTimeSignature(ts),
                )).toList(),
            ),
            const SizedBox(height: 16),

            // Subdivision
            Text(AppStrings.subdivision,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(subdivisions.length, (i) => ChoiceChip(
                  label: Text(subdivisionLabels[i]),
                  selected: state.subdivision == subdivisions[i],
                  selectedColor: AppColors.metronome,
                  onSelected: (_) => vm.setSubdivision(subdivisions[i]),
                )),
            ),
            const SizedBox(height: 24),
            const DonationButton(),
            const SizedBox(height: 80), // FAB clearance
          ],
        ),
      ),
    );
  }
}

class _BeatIndicator extends StatelessWidget {
  const _BeatIndicator({
    required this.totalBeats,
    required this.currentBeat,
    required this.isPlaying,
    required this.beatController,
  });

  final int totalBeats;
  final int currentBeat;
  final bool isPlaying;
  final AnimationController beatController;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalBeats, (i) {
          final isActive = isPlaying && i == currentBeat;
          final isAccent = i == 0;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isAccent ? 44 : 36,
            height: isAccent ? 44 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.metronome
                  : AppColors.metronome.withOpacity(0.2),
              border: Border.all(
                color: AppColors.metronome,
                width: isAccent ? 3 : 1.5,
              ),
            ),
            child: isActive
                ? const Icon(Icons.music_note, color: Colors.white, size: 18)
                : null,
          );
        }),
      ),
    );
}
