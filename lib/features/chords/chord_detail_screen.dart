import 'package:flutter/material.dart';

/// Detail screen for a single chord.
///
/// Displays the chord identified by [chordId] with a back-navigation
/// [AppBar] provided by the enclosing [Scaffold].
class ChordDetailScreen extends StatelessWidget {
  /// Creates a [ChordDetailScreen] for [chordId].
  const ChordDetailScreen({super.key, required this.chordId});

  /// The identifier of the chord to display.
  final String chordId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chordId)),
      body: Center(
        child: Text(
          chordId,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
