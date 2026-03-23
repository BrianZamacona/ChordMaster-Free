import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Chord library screen listing available chords.
///
/// This widget does not include a [Scaffold] — the shell route provides one.
class ChordLibraryScreen extends StatelessWidget {
  /// Creates the [ChordLibraryScreen].
  const ChordLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppStrings.moduleChords,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
