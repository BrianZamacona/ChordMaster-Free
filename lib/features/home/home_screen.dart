import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/donation_button.dart';
import '../../ui/animations.dart';
import '../../ui/palette.dart';
import 'home_viewmodel.dart';

/// Inicio: reto del día, racha de días y tarjetas de acceso a los módulos.
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
                    context.palette.accent,
                    context.palette.accent.withAlpha(180),
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
                        AppStrings.homeModules,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.palette.textPrimary,
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
          color: context.palette.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: TextStyle(
                color: context.palette.onAccent,
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
                context.palette.accent.withAlpha(200),
                context.palette.accent.withAlpha(100),
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
                      AppStrings.dailyChallenge,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.palette.onAccent.withValues(alpha: 0.75),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.palette.onAccent,
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
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

List<_ModuleInfo> get _modules => [
  _ModuleInfo(
      label: AppStrings.moduleChords,
      icon: Icons.piano,
      route: '/learn/chords'),
  _ModuleInfo(
      label: AppStrings.moduleScales,
      icon: Icons.music_note,
      route: '/learn/scales'),
  _ModuleInfo(
      label: AppStrings.moduleTuner,
      icon: Icons.graphic_eq,
      route: '/tools/tuner'),
  _ModuleInfo(
      label: AppStrings.moduleMetronome,
      icon: Icons.timer,
      route: '/tools/metronome'),
  _ModuleInfo(
      label: AppStrings.moduleProgressions,
      icon: Icons.queue_music,
      route: '/learn/progressions'),
  _ModuleInfo(
      label: AppStrings.moduleEarTraining,
      icon: Icons.hearing,
      route: '/practice/ear-training'),
  _ModuleInfo(
      label: AppStrings.moduleRhythmGame,
      icon: Icons.sports_esports,
      route: '/practice/rhythm'),
  _ModuleInfo(
      label: AppStrings.moduleSongs,
      icon: Icons.library_music,
      route: '/practice/songs'),
  _ModuleInfo(
      label: AppStrings.moduleHealth,
      icon: Icons.favorite,
      route: '/progress/health'),
];

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.onTap});

  final _ModuleInfo module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
          color: context.palette.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.palette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  module.icon,
                  color: context.palette.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ModuleLabel(label: module.label),
              ),
            ],
          ),
        ),
      ),
    );
}

/// Nombre de un módulo. Puede ocupar varias líneas, pero nunca parte una
/// palabra: si la más larga no cabe, reduce la letra lo justo.
class _ModuleLabel extends StatelessWidget {
  const _ModuleLabel({required this.label});

  final String label;

  double _widestWord(BuildContext context, TextStyle style) {
    var widest = 0.0;
    for (final word in label.split(' ')) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final style = Theme.of(context).textTheme.titleSmall!.copyWith(
                color: context.palette.textPrimary,
                height: 1.2,
              );
          final widest = _widestWord(context, style);
          // Margen del 2 %: el ancho de un texto no escala de forma exacta.
          final fit = widest > constraints.maxWidth
              ? constraints.maxWidth / widest * 0.98
              : 1.0;
          return Text(
            label,
            textAlign: TextAlign.center,
            style: style.copyWith(fontSize: style.fontSize! * fit),
          );
        },
      );
}
