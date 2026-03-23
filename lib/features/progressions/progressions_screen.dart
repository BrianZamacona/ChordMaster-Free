import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Chord progressions screen.
class ProgressionsScreen extends StatelessWidget {
  /// Creates the [ProgressionsScreen].
  const ProgressionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleProgressions)),
      body: Center(
        child: Text(
          AppStrings.moduleProgressions,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
