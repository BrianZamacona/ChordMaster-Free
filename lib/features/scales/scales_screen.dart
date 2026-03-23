import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Scales reference screen.
class ScalesScreen extends StatelessWidget {
  /// Creates the [ScalesScreen].
  const ScalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleScales)),
      body: Center(
        child: Text(
          AppStrings.moduleScales,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
