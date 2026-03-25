import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Composition tools screen.
class CompositionScreen extends StatelessWidget {
  /// Creates the [CompositionScreen].
  const CompositionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleComposition)),
      body: Center(
        child: Text(
          AppStrings.moduleComposition,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
}
