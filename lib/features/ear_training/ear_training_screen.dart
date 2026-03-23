import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Ear training screen.
class EarTrainingScreen extends StatelessWidget {
  /// Creates the [EarTrainingScreen].
  const EarTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleEarTraining)),
      body: Center(
        child: Text(
          AppStrings.moduleEarTraining,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
