import 'package:flutter/material.dart';

/// Detail screen for a single song.
class SongDetailScreen extends StatelessWidget {
  /// Creates a [SongDetailScreen] for [songId].
  const SongDetailScreen({super.key, required this.songId});

  /// The identifier of the song to display.
  final String songId;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(songId)),
      body: Center(
        child: Text(
          songId,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
}
