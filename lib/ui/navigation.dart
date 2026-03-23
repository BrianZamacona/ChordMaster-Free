import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/achievements/achievements_screen.dart';
import '../features/chords/chord_detail_screen.dart';
import '../features/chords/chord_library_screen.dart';
import '../features/community/community_screen.dart';
import '../features/composition/composition_screen.dart';
import '../features/ear_training/ear_training_screen.dart';
import '../features/health/health_screen.dart';
import '../features/home/home_screen.dart';
import '../features/improvisation/improv_screen.dart';
import '../features/metronome/metronome_screen.dart';
import '../features/progressions/progressions_screen.dart';
import '../features/rhythm_games/rhythm_game_screen.dart';
import '../features/scales/scales_screen.dart';
import '../features/songs/song_detail_screen.dart';
import '../features/songs/songs_screen.dart';
import '../features/tuner/tuner_screen.dart';
import '../core/widgets/app_scaffold.dart';

/// The global [GoRouter] instance for ChordMaster Free.
///
/// Uses [StatefulShellRoute.indexedStack] for the four primary tabs so each
/// branch retains its navigation state independently.  The remaining feature
/// modules are top-level routes accessible from the end drawer.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(
          body: navigationShell,
          currentIndex: navigationShell.currentIndex,
          onIndexChange: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chords',
              builder: (_, __) => const ChordLibraryScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ChordDetailScreen(
                    chordId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tuner',
              builder: (_, __) => const TunerScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/metronome',
              builder: (_, __) => const MetronomeScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/scales',
      builder: (_, __) => const ScalesScreen(),
    ),
    GoRoute(
      path: '/progressions',
      builder: (_, __) => const ProgressionsScreen(),
    ),
    GoRoute(
      path: '/ear-training',
      builder: (_, __) => const EarTrainingScreen(),
    ),
    GoRoute(
      path: '/rhythm-game',
      builder: (_, __) => const RhythmGameScreen(),
    ),
    GoRoute(
      path: '/improvisation',
      builder: (_, __) => const ImprovScreen(),
    ),
    GoRoute(
      path: '/songs',
      builder: (_, __) => const SongsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => SongDetailScreen(
            songId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/composition',
      builder: (_, __) => const CompositionScreen(),
    ),
    GoRoute(
      path: '/health',
      builder: (_, __) => const HealthScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (_, __) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (_, __) => const AchievementsScreen(),
    ),
  ],
);
