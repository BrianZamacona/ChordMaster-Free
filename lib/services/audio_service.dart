import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/audio/pluck_synth.dart';
import '../domain/voicing/ergonomics.dart' show standardOpenStringMidi;
import '../domain/voicing/voicing_adapter.dart';

/// Riverpod provider that exposes the [AudioService] singleton.
final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

/// El sonido de la app, sintetizado (`domain/audio/pluck_synth.dart`):
/// no hay archivos de audio. Cada sonido se genera una vez como WAV en la
/// carpeta temporal y se reproduce como archivo con `just_audio`.
///
/// Los errores se registran con [debugPrint] y nunca llegan a la UI.
class AudioService {
  factory AudioService() => instance;

  AudioService._internal();

  static final AudioService instance = AudioService._internal();

  /// Acordes, notas e intervalos (uno a la vez: el nuevo corta al anterior).
  AudioPlayer? _voice;

  /// Clics del metrónomo, cargados una sola vez para que suenen sin demora.
  AudioPlayer? _tick;
  AudioPlayer? _accent;

  Directory? _dir;
  final _files = <String, String>{};

  Future<void> initialize() async {
    try {
      _voice ??= AudioPlayer();
    } catch (e, st) {
      debugPrint('AudioService.initialize error: $e\n$st');
    }
  }

  void dispose() {
    for (final p in [_voice, _tick, _accent]) {
      try {
        p?.dispose();
      } catch (e, st) {
        debugPrint('AudioService.dispose error: $e\n$st');
      }
    }
    _voice = _tick = _accent = null;
  }

  // ── Reproducción ──────────────────────────────────────────────────────────

  /// Rasguea una digitación de chords.json (6ª → 1ª, `-1` = muteada).
  Future<void> playFingering(List<int> jsonFrets) {
    final frets = VoicingAdapter.fromChordJson(jsonFrets);
    final midi = [
      for (var s = 0; s < frets.length; s++)
        if (frets[s] != null) standardOpenStringMidi[s] + frets[s]!,
    ];
    return playStrum(midi);
  }

  /// Rasgueo de grave a aguda de las notas MIDI [midi].
  Future<void> playStrum(List<int> midi) {
    if (midi.isEmpty) return Future.value();
    final sorted = [...midi]..sort();
    return _playVoice('strum-${sorted.join('-')}', () => renderStrum(sorted));
  }

  /// Notas que empiezan en instantes distintos (p. ej. un intervalo
  /// melódico: una nota y luego la otra).
  Future<void> playNotes(List<NoteEvent> events, {double seconds = 2.5}) {
    if (events.isEmpty) return Future.value();
    final key = 'notes-${[for (final e in events) '${e.midi}@${e.at}'].join('-')}-$seconds';
    return _playVoice(key, () => renderNotes(events, seconds: seconds));
  }

  /// Clic del metrónomo; [isAccent] para el primer tiempo del compás.
  Future<void> playMetronomeTick({bool isAccent = false}) async {
    try {
      final player = isAccent
          ? _accent ??= await _loaded('click-accent', () => renderClick(accent: true))
          : _tick ??= await _loaded('click', renderClick);
      await player.seek(Duration.zero);
      unawaited(player.play());
    } catch (e, st) {
      debugPrint('AudioService.playMetronomeTick error: $e\n$st');
    }
  }

  Future<void> stopAll() async {
    try {
      await _voice?.stop();
    } catch (e, st) {
      debugPrint('AudioService.stopAll error: $e\n$st');
    }
  }

  // ── Interno ───────────────────────────────────────────────────────────────

  Future<void> _playVoice(String key, Float64List Function() render) async {
    try {
      await initialize();
      final player = _voice!;
      await player.stop();
      await player.setFilePath(await _file(key, render));
      unawaited(player.play());
    } catch (e, st) {
      debugPrint('AudioService._playVoice error ($key): $e\n$st');
    }
  }

  Future<AudioPlayer> _loaded(String key, Float64List Function() render) async {
    final player = AudioPlayer();
    await player.setFilePath(await _file(key, render));
    return player;
  }

  /// Ruta del WAV de [key]; lo genera la primera vez.
  Future<String> _file(String key, Float64List Function() render) async {
    final cached = _files[key];
    if (cached != null) return cached;
    _dir ??= await getTemporaryDirectory();
    final safe = key.replaceAll(RegExp('[^A-Za-z0-9@._-]'), '_');
    final file = File('${_dir!.path}/synth_$safe.wav');
    if (!file.existsSync()) {
      await file.writeAsBytes(encodeWav(render()), flush: true);
    }
    return _files[key] = file.path;
  }
}
