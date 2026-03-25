import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Riverpod provider that exposes the [AudioService] singleton.
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

/// Singleton service responsible for all audio playback in ChordMaster Free.
///
/// Wraps [AudioPlayer] from `just_audio` to play individual notes, chords
/// (with a 30 ms inter-note stagger), and metronome ticks.  All public
/// methods swallow exceptions internally and log them with [debugPrint] so
/// that audio errors never crash the UI.
class AudioService {

  /// Factory constructor always returns [instance].
  factory AudioService() => instance;

  AudioService._internal();
  /// The singleton instance.
  static final AudioService instance = AudioService._internal();

  AudioPlayer? _player;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialises the underlying [AudioPlayer].
  ///
  /// Must be called once before any playback method is used, typically from
  /// `main.dart` during app start-up.
  Future<void> initialize() async {
    try {
      _player ??= AudioPlayer();
    } catch (e, st) {
      debugPrint('AudioService.initialize error: $e\n$st');
    }
  }

  /// Disposes the underlying [AudioPlayer] and releases system resources.
  void dispose() {
    try {
      _player?.dispose();
      _player = null;
    } catch (e, st) {
      debugPrint('AudioService.dispose error: $e\n$st');
    }
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  /// Plays a single note audio asset identified by [noteFile].
  ///
  /// [noteFile] must be a valid Flutter asset path, e.g.
  /// `'assets/audio/notes/A4.mp3'`.
  Future<void> playNote(String noteFile) async {
    try {
      final player = await _ensurePlayer();
      await player.setAsset(noteFile);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e, st) {
      debugPrint('AudioService.playNote error (file: $noteFile): $e\n$st');
    }
  }

  /// Plays a chord by sounding each note in [noteFiles] with a 30 ms stagger.
  ///
  /// A separate [AudioPlayer] instance is created for each note so they can
  /// overlap naturally.  Players are disposed once playback completes.
  Future<void> playChord(List<String> noteFiles) async {
    if (noteFiles.isEmpty) return;
    try {
      final players = <AudioPlayer>[];
      for (int i = 0; i < noteFiles.length; i++) {
        if (i > 0) {
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
        try {
          final p = AudioPlayer();
          players.add(p);
          await p.setAsset(noteFiles[i]);
          unawaited(p.play());
        } catch (e, st) {
          debugPrint(
            'AudioService.playChord error for note ${noteFiles[i]}: $e\n$st',
          );
        }
      }
      // Clean up after the longest realistic note duration (3 s).
      unawaited(Future<void>.delayed(const Duration(seconds: 3), () {
        for (final p in players) {
          p.dispose();
        }
      }));
    } catch (e, st) {
      debugPrint('AudioService.playChord error: $e\n$st');
    }
  }

  /// Plays a metronome tick sound.
  ///
  /// When [isAccent] is `true`, the accented (downbeat) tick asset is used;
  /// otherwise the regular tick asset is played.
  Future<void> playMetronomeTick({bool isAccent = false}) async {
    const accentAsset = 'assets/audio/metronome_accent.mp3';
    const tickAsset = 'assets/audio/metronome_tick.mp3';
    try {
      final player = await _ensurePlayer();
      await player.setAsset(isAccent ? accentAsset : tickAsset);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e, st) {
      debugPrint('AudioService.playMetronomeTick error: $e\n$st');
    }
  }

  /// Stops all current playback immediately.
  Future<void> stopAll() async {
    try {
      await _player?.stop();
    } catch (e, st) {
      debugPrint('AudioService.stopAll error: $e\n$st');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the existing [AudioPlayer], creating it lazily if necessary.
  Future<AudioPlayer> _ensurePlayer() async {
    if (_player == null) {
      await initialize();
    }
    return _player!;
  }
}
