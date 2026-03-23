import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Achievements screen.
class AchievementsScreen extends StatelessWidget {
  /// Creates the [AchievementsScreen].
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleAchievements)),
      body: Center(
        child: Text(
          AppStrings.moduleAchievements,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
