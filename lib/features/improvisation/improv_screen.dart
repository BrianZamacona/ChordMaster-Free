import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Improvisation guide screen.
class ImprovScreen extends StatelessWidget {
  /// Creates the [ImprovScreen].
  const ImprovScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleImprovisation)),
      body: Center(
        child: Text(
          AppStrings.moduleImprovisation,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
}
