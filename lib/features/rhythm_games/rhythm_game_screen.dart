import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Rhythm game screen.
class RhythmGameScreen extends StatelessWidget {
  /// Creates the [RhythmGameScreen].
  const RhythmGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleRhythmGame)),
      body: Center(
        child: Text(
          AppStrings.moduleRhythmGame,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
