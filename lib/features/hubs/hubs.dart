import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/donation_button.dart';
import 'section_hub_screen.dart';

class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionHubScreen(
        title: AppStrings.tabLearn,
        intro: AppStrings.learnIntro,
        entries: [
          HubEntry(
            icon: Icons.school_outlined,
            title: AppStrings.hubLessons,
            subtitle: AppStrings.hubLessonsSub,
            route: '/learn/lessons',
          ),
          HubEntry(
            icon: Icons.auto_stories_outlined,
            title: AppStrings.hubGuides,
            subtitle: AppStrings.hubGuidesSub,
            route: '/learn/guides',
          ),
          HubEntry(
            icon: Icons.grid_view_rounded,
            title: AppStrings.hubOpenChords,
            subtitle: AppStrings.hubOpenChordsSub,
            route: '/learn/open-chords',
          ),
          HubEntry(
            icon: Icons.queue_music,
            title: AppStrings.hubMelodies,
            subtitle: AppStrings.hubMelodiesSub,
            route: '/learn/melodies',
          ),
          HubEntry(
            icon: Icons.library_music_outlined,
            title: AppStrings.hubChords,
            subtitle: AppStrings.hubChordsSub,
            route: '/learn/chords',
          ),
          HubEntry(
            icon: Icons.linear_scale,
            title: AppStrings.hubScales,
            subtitle: AppStrings.hubScalesSub,
            route: '/learn/scales',
          ),
          HubEntry(
            icon: Icons.queue_music,
            title: AppStrings.hubProgressions,
            subtitle: AppStrings.hubProgressionsSub,
            route: '/learn/progressions',
          ),
          HubEntry(
            icon: Icons.donut_large,
            title: AppStrings.circleTitle,
            subtitle: AppStrings.hubCircleSub,
            route: '/learn/circle',
          ),
          HubEntry(
            icon: Icons.vertical_align_top,
            title: AppStrings.hubCapo,
            subtitle: AppStrings.hubCapoSub,
            route: '/learn/capo',
          ),
        ],
      );
}

class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionHubScreen(
        title: AppStrings.tabPractice,
        intro: AppStrings.practiceIntro,
        entries: [
          HubEntry(
            icon: Icons.hearing,
            title: AppStrings.hubEar,
            subtitle: AppStrings.hubEarSub,
            route: '/practice/ear-training',
          ),
          HubEntry(
            icon: Icons.fitness_center,
            title: AppStrings.hubWorkouts,
            subtitle: AppStrings.hubWorkoutsSub,
            route: '/practice/workouts',
          ),
          HubEntry(
            icon: Icons.back_hand_outlined,
            title: AppStrings.hubTechnique,
            subtitle: AppStrings.hubTechniqueSub,
            route: '/practice/technique',
          ),
          HubEntry(
            icon: Icons.event_available,
            title: AppStrings.hubMultiDay,
            subtitle: AppStrings.hubMultiDaySub,
            route: '/practice/challenges',
          ),
          HubEntry(
            icon: Icons.av_timer,
            title: AppStrings.hubRhythm,
            subtitle: AppStrings.hubRhythmSub,
            route: '/practice/rhythm',
          ),
          HubEntry(
            icon: Icons.music_note,
            title: AppStrings.hubSongs,
            subtitle: AppStrings.hubSongsSub,
            route: '/practice/songs',
          ),
        ],
      );
}

class ProgressHubScreen extends StatelessWidget {
  const ProgressHubScreen({super.key});

  @override
  Widget build(BuildContext context) => SectionHubScreen(
        title: AppStrings.tabProgress,
        intro: AppStrings.progressIntro,
        entries: [
          HubEntry(
            icon: Icons.emoji_events_outlined,
            title: AppStrings.hubAchievements,
            subtitle: AppStrings.hubAchievementsSub,
            route: '/progress/achievements',
          ),
          HubEntry(
            icon: Icons.self_improvement,
            title: AppStrings.hubHealth,
            subtitle: AppStrings.hubHealthSub,
            route: '/progress/health',
          ),
        ],
        footer: [
          const SizedBox(height: 12),
          Text(
            AppStrings.settingsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const SettingsPanel(),
          const SizedBox(height: 24),
          const Center(child: DonationButton()),
        ],
      );
}
