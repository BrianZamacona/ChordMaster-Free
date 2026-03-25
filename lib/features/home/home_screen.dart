import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/donation_button.dart';
import '../../ui/animations.dart';
import 'home_viewmodel.dart';

/// Home screen showing the daily challenge, streak, and 12 module cards.
///
/// This widget does not include a [Scaffold] — the shell route provides one.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the [HomeScreen].
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _streakController;

  @override
  void initState() {
    super.initState();
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 110,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              AppStrings.appName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withAlpha(180),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            if (state.streak > 0)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _StreakBadge(
                  streak: state.streak,
                  controller: _streakController,
                ),
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: state.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.dailyChallenge.isNotEmpty)
                      slideUpFade(
                        _DailyChallengeCard(challenge: state.dailyChallenge),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Modules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (!state.isLoading)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final module = _modules[index];
                  return scaleIn(
                    _ModuleCard(
                      module: module,
                      onTap: () {
                        ref
                            .read(homeViewModelProvider.notifier)
                            .updateLastModule(module.route);
                        context.go(module.route);
                      },
                    ),
                    duration: Duration(milliseconds: 300 + index * 40),
                  );
                },
                childCount: _modules.length,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Center(child: slideUpFade(const DonationButton())),
          ),
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({
    required this.streak,
    required this.controller,
  });

  final int streak;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) => ScaleTransition(
      scale: pulseAnimation(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({required this.challenge});

  final String challenge;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.secondary.withAlpha(200),
                AppColors.secondary.withAlpha(100),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('⚡', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenge',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

class _ModuleInfo {
  const _ModuleInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

const List<_ModuleInfo> _modules = [
  _ModuleInfo(
      label: AppStrings.moduleChords,
      icon: Icons.piano,
      color: AppColors.chords,
      route: '/chords'),
  _ModuleInfo(
      label: AppStrings.moduleScales,
      icon: Icons.music_note,
      color: AppColors.scales,
      route: '/scales'),
  _ModuleInfo(
      label: AppStrings.moduleTuner,
      icon: Icons.graphic_eq,
      color: AppColors.tuner,
      route: '/tuner'),
  _ModuleInfo(
      label: AppStrings.moduleMetronome,
      icon: Icons.timer,
      color: AppColors.metronome,
      route: '/metronome'),
  _ModuleInfo(
      label: AppStrings.moduleProgressions,
      icon: Icons.queue_music,
      color: AppColors.progressions,
      route: '/progressions'),
  _ModuleInfo(
      label: AppStrings.moduleEarTraining,
      icon: Icons.hearing,
      color: AppColors.earTraining,
      route: '/ear-training'),
  _ModuleInfo(
      label: AppStrings.moduleRhythmGame,
      icon: Icons.sports_esports,
      color: AppColors.rhythmGame,
      route: '/rhythm-game'),
  _ModuleInfo(
      label: AppStrings.moduleImprovisation,
      icon: Icons.auto_awesome,
      color: AppColors.improvisation,
      route: '/improvisation'),
  _ModuleInfo(
      label: AppStrings.moduleSongs,
      icon: Icons.library_music,
      color: AppColors.songs,
      route: '/songs'),
  _ModuleInfo(
      label: AppStrings.moduleComposition,
      icon: Icons.edit_note,
      color: AppColors.composition,
      route: '/composition'),
  _ModuleInfo(
      label: AppStrings.moduleHealth,
      icon: Icons.favorite,
      color: AppColors.health,
      route: '/health'),
  _ModuleInfo(
      label: AppStrings.moduleCommunity,
      icon: Icons.people,
      color: AppColors.community,
      route: '/community'),
];

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final _ModuleInfo module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                module.color,
                module.color.withAlpha(180),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  module.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
