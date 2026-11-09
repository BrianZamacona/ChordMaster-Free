import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/permission_utils.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/play_along.dart';
import '../../services/audio_service.dart';
import '../../services/pitch_service.dart';
import '../tuner/tuner_viewmodel.dart';
import 'tab_player.dart';

enum PlayAlongStatus { idle, listening, finished, denied }

/// Tocar una tablatura con el micrófono: de quién es (la tarjeta que lo
/// empezó), por qué nota va, los errores y, al terminar, el resultado.
@immutable
class PlayAlongState {
  const PlayAlongState({
    this.owner,
    this.status = PlayAlongStatus.idle,
    this.position = 0,
    this.mistakes = 0,
    this.wrongMidi,
    this.result,
    this.permanentlyDenied = false,
  });

  /// La tablatura que se está tocando (cada reproductor compara con la suya).
  final Object? owner;
  final PlayAlongStatus status;

  /// Nota que se espera (= cuántas van bien).
  final int position;
  final int mistakes;

  /// La última nota equivocada que se oyó (MIDI), hasta la siguiente correcta.
  final int? wrongMidi;
  final PlayAlongResult? result;

  /// El micrófono se negó para siempre: hay que ir a los ajustes.
  final bool permanentlyDenied;

  bool get listening => status == PlayAlongStatus.listening;
}

/// Uno a la vez para toda la app: al empezar en otra tablatura, o al sonar un
/// reproductor, el micrófono se suelta.
class PlayAlongViewModel extends Notifier<PlayAlongState> {
  late PitchService _pitch;
  late ValueNotifier<Object?> _playback;
  StreamSubscription<MicWindow>? _sub;
  PlayAlongSession? _session;

  /// Lo que se pidió por última vez (si se suelta mientras el micrófono
  /// arranca, al terminar de arrancar se apaga).
  Object? _wanted;

  @override
  PlayAlongState build() {
    _pitch = ref.read(pitchServiceProvider);
    _playback = ref.read(tabPlaybackProvider)..addListener(_onPlayback);
    ref.onDispose(() {
      _playback.removeListener(_onPlayback);
      _release();
    });
    return const PlayAlongState();
  }

  /// Empieza a escuchar [tab] para [owner].
  Future<void> start(Object owner, List<TabNote> tab, {TabSwing swing = TabSwing.none}) async {
    await _release();
    _wanted = owner;
    // Que no suene ningún reproductor: el micrófono lo oiría.
    _playback.value = null;
    unawaited(ref.read(audioServiceProvider).stopAll());
    state = PlayAlongState(owner: owner, status: PlayAlongStatus.listening);
    try {
      await _pitch.startListening();
    } catch (e) {
      debugPrint('PlayAlongViewModel.start error: $e');
      if (_wanted != owner) return;
      _wanted = null;
      final forever = await PermissionUtils.isMicrophonePermanentlyDenied();
      if (!ref.mounted) return;
      state = PlayAlongState(
        owner: owner,
        status: PlayAlongStatus.denied,
        permanentlyDenied: forever,
      );
      return;
    }
    if (_wanted != owner || !ref.mounted) {
      await _pitch.stopListening();
      return;
    }
    _session = PlayAlongSession(tab, a4: _pitch.referenceA4, swing: swing);
    _sub = _pitch.windowStream.listen(_onWindow, onError: (Object e) => stop());
  }

  /// Deja de escuchar (vuelve al inicio, sin resultado).
  Future<void> stop() async {
    final released = _release();
    if (ref.mounted) state = const PlayAlongState();
    await released;
  }

  /// Suelta el micrófono si lo tiene [owner] (su tarjeta se va o se oculta).
  Future<void> stopFor(Object owner) async {
    // Al cerrar la app el proveedor ya se fue (y soltó el micrófono).
    if (ref.mounted && state.owner == owner) await stop();
  }

  Future<void> openSettings() => PermissionUtils.openAppSettings();

  void _onWindow(MicWindow w) {
    final session = _session;
    if (session == null) return;
    final kind = session.listen(
      w.samples,
      PitchService.sampleRate,
      at: w.at,
      hop: PitchService.hop,
    );
    if (kind == null) return;
    final f = session.follower;
    if (f.done) {
      final owner = state.owner;
      unawaited(_release());
      state = PlayAlongState(
        owner: owner,
        status: PlayAlongStatus.finished,
        position: f.position,
        mistakes: f.mistakes,
        result: f.result,
      );
      return;
    }
    state = PlayAlongState(
      owner: state.owner,
      status: PlayAlongStatus.listening,
      position: f.position,
      mistakes: f.mistakes,
      wrongMidi: switch (kind) {
        HeardKind.wrong => session.lastHeard,
        HeardKind.right => null,
        _ => state.wrongMidi,
      },
    );
  }

  void _onPlayback() {
    if (_playback.value != null && state.listening) unawaited(stop());
  }

  Future<void> _release() async {
    _wanted = null;
    _session = null;
    // Primero el micrófono; la suscripción se cancela después (cancelar un
    // stream de difusión puede tardar una vuelta del bucle de eventos).
    final hadMic = _sub != null;
    final cancelled = _sub?.cancel();
    _sub = null;
    if (hadMic) await _pitch.stopListening();
    await cancelled;
  }
}

/// Vive con la app (como el reproductor): cada tarjeta suelta el micrófono al
/// irse u ocultarse ([PlayAlongViewModel.stopFor]).
final playAlongProvider = NotifierProvider<PlayAlongViewModel, PlayAlongState>(
  PlayAlongViewModel.new,
);
