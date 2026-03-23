import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Practice health and wellness screen.
class HealthScreen extends StatelessWidget {
  /// Creates the [HealthScreen].
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleHealth)),
      body: Center(
        child: Text(
          AppStrings.moduleHealth,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
