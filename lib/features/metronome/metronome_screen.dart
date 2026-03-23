import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Metronome screen.
///
/// This widget does not include a [Scaffold] — the shell route provides one.
class MetronomeScreen extends StatelessWidget {
  /// Creates the [MetronomeScreen].
  const MetronomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.moduleMetronome,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
