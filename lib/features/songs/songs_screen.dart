import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Song library screen.
class SongsScreen extends StatelessWidget {
  /// Creates the [SongsScreen].
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleSongs)),
      body: Center(
        child: Text(
          AppStrings.moduleSongs,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
