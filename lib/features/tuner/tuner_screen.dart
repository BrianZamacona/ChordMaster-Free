import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Chromatic tuner screen.
///
/// This widget does not include a [Scaffold] — the shell route provides one.
class TunerScreen extends StatelessWidget {
  /// Creates the [TunerScreen].
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.moduleTuner,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
