import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/play_along.dart';
import '../../domain/practice/tab_playback.dart';
import '../../domain/practice/technique_exercises.dart';
import '../../domain/theory/notes.dart';
import '../../services/audio_service.dart';
import '../../ui/theme.dart';
import 'lesson_tab.dart';
import 'play_along_viewmodel.dart';

/// Qué tablatura está sonando: al empezar otra, la anterior se detiene.
final tabPlaybackProvider = Provider<ValueNotifier<Object?>>((ref) {
  final notifier = ValueNotifier<Object?>(null);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Una tablatura que se puede escuchar: ▶ la toca con el sintetizador al tempo
/// [bpm] y resalta la nota que suena, con los mismos instantes del audio
/// ([tabEvents]). Con [onPlayed], además se puede tocar con el micrófono
/// ("Tocar yo"): resalta la nota que toca, marca las que salieron y, al
/// terminar, entrega el resultado.
class TabPlayer extends ConsumerStatefulWidget {
  const TabPlayer({
    super.key,
    required this.notes,
    required this.bpm,
    this.onPlay,
    this.onPlayed,
  });

  final List<TabNote> notes;
  final int bpm;

  /// Se llama al empezar a sonar (las rutinas lo anotan como día de práctica).
  final VoidCallback? onPlay;

  /// Se llama al terminar de tocarla con el micrófono.
  final ValueChanged<PlayAlongResult>? onPlayed;

  @override
  ConsumerState<TabPlayer> createState() => _TabPlayerState();
}

class _TabPlayerState extends ConsumerState<TabPlayer> {
  /// Cada 30 ms basta para que la marca no se atrase a la vista.
  static const _frame = Duration(milliseconds: 30);

  final _token = Object();
  final _clock = Stopwatch();
  Timer? _timer;
  int? _index;
  late final ValueNotifier<Object?> _active;
  PlayAlongViewModel? _mic;

  bool get _playing => _timer != null;

  @override
  void initState() {
    super.initState();
    _active = ref.read(tabPlaybackProvider)..addListener(_onActiveChanged);
    if (widget.onPlayed != null) _mic = ref.read(playAlongProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pestaña oculta: el micrófono no sigue escuchando por detrás.
    if (!TickerMode.valuesOf(context).enabled) _releaseMic();
  }

  @override
  void didUpdateWidget(TabPlayer old) {
    super.didUpdateWidget(old);
    // Por contenido: hay pantallas que arman la lista en cada build.
    final same = listEquals(old.notes, widget.notes);
    if (!same || old.bpm != widget.bpm) _stop();
    if (!same) _releaseMic();
  }

  @override
  void dispose() {
    _active.removeListener(_onActiveChanged);
    if (_playing && _active.value == _token) {
      ref.read(audioServiceProvider).stopAll();
      _active.value = null;
    }
    _timer?.cancel();
    _releaseMic();
    super.dispose();
  }

  /// Suelta el micrófono si lo tiene esta tablatura. Se llama desde el ciclo
  /// de vida del widget, donde no se puede cambiar un proveedor: va en una
  /// microtarea, justo después del cuadro.
  void _releaseMic() {
    final mic = _mic;
    if (mic != null) scheduleMicrotask(() => mic.stopFor(_token));
  }

  void _onActiveChanged() {
    if (_active.value != _token && _playing) _stop(silence: false);
  }

  void _play() {
    _active.value = _token;
    widget.onPlay?.call();
    ref.read(audioServiceProvider).playNotes(
          tabEvents(widget.notes, bpm: widget.bpm),
          seconds: tabDurationSeconds(widget.notes.length, bpm: widget.bpm),
          ring: tabNoteRingSeconds,
        );
    _clock
      ..reset()
      ..start();
    _timer = Timer.periodic(_frame, (_) => _tick());
    setState(() => _index = 0);
  }

  void _tick() {
    final elapsed = _clock.elapsedMicroseconds / 1e6;
    final index = tabIndexAt(elapsed, widget.notes.length, bpm: widget.bpm);
    if (index == null) {
      _stop(silence: false);
    } else if (index != _index) {
      setState(() => _index = index);
    }
  }

  void _stop({bool silence = true}) {
    if (!_playing) return;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    if (silence) ref.read(audioServiceProvider).stopAll();
    if (_active.value == _token) _active.value = null;
    if (mounted) setState(() => _index = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final onPlayed = widget.onPlayed;
    // Solo los reproductores con micrófono miran su estado.
    final mic = onPlayed == null ? null : ref.watch(playAlongProvider);
    final mine = mic != null && mic.owner == _token ? mic : null;
    final listening = mine?.listening ?? false;
    if (onPlayed != null) {
      ref.listen(playAlongProvider, (prev, next) {
        if (next.owner == _token &&
            next.status == PlayAlongStatus.finished &&
            prev?.status != PlayAlongStatus.finished) {
          onPlayed(next.result!);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonTabView(
          notes: widget.notes,
          highlight: listening ? mine!.position : _index,
          played: listening || mine?.status == PlayAlongStatus.finished
              ? mine!.position
              : 0,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.tonalIcon(
              key: const Key('tab-play'),
              onPressed: listening ? null : (_playing ? _stop : _play),
              icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
              label: Text(_playing ? AppStrings.tabStop : AppStrings.tabListen),
            ),
            if (onPlayed != null)
              OutlinedButton.icon(
                key: const Key('tab-mic'),
                onPressed: listening
                    ? _mic!.stop
                    : () {
                        _stop();
                        _mic!.start(_token, widget.notes);
                      },
                icon: Icon(listening ? Icons.stop : Icons.mic),
                label: Text(listening ? AppStrings.tabStop : AppStrings.tabPlayMic),
              ),
            Text(
              AppStrings.tabAtBpm(widget.bpm),
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
          ],
        ),
        if (onPlayed != null) ...[
          const SizedBox(height: 6),
          _MicStatus(
            state: mine,
            notes: widget.notes,
            onOpenSettings: _mic!.openSettings,
          ),
        ],
      ],
    );
  }
}

/// Qué pasa con el micrófono: cómo se usa, por qué nota va, la nota
/// equivocada que sonó o cómo salió.
class _MicStatus extends StatelessWidget {
  const _MicStatus({
    required this.state,
    required this.notes,
    required this.onOpenSettings,
  });

  final PlayAlongState? state;
  final List<TabNote> notes;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final s = state;
    final secondary = text.bodySmall?.copyWith(color: p.textSecondary);

    Widget line(String message, {Color? color, IconData? icon}) => Row(
      key: const Key('tab-mic-status'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color ?? p.textSecondary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            message,
            style: text.bodySmall?.copyWith(color: color ?? p.textSecondary),
          ),
        ),
      ],
    );

    switch (s?.status) {
      case null || PlayAlongStatus.idle:
        return Text(AppStrings.tabMicHint, key: const Key('tab-mic-status'), style: secondary);
      case PlayAlongStatus.denied:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            line(
              s!.permanentlyDenied ? AppStrings.tabMicDeniedForever : AppStrings.tabMicDenied,
              color: p.error,
              icon: Icons.mic_off,
            ),
            if (s.permanentlyDenied)
              TextButton(onPressed: onOpenSettings, child: Text(AppStrings.openSettings)),
          ],
        );
      case PlayAlongStatus.listening:
        final progress = AppStrings.tabMicProgress(s!.position + 1, notes.length);
        final mistakes = s.mistakes == 0 ? '' : ' · ${AppStrings.tabMicMistakes(s.mistakes)}';
        final wrong = s.wrongMidi;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line('$progress$mistakes', icon: Icons.hearing, color: p.textPrimary),
            if (wrong != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  AppStrings.tabMicWrong(
                    pitchName(wrong),
                    pitchName(tabMidi(notes[s.position])),
                  ),
                  key: const Key('tab-mic-wrong'),
                  style: musicMono(fontSize: 13, color: p.warning),
                ),
              ),
          ],
        );
      case PlayAlongStatus.finished:
        final r = s!.result!;
        if (r.cleanBpm != null) {
          return line(
            AppStrings.tabMicClean(r.bpm!.round()),
            color: p.success,
            icon: Icons.check_circle,
          );
        }
        if (r.mistakes > 0) {
          return line(AppStrings.tabMicWithMistakes(r.mistakes), icon: Icons.replay);
        }
        if (r.paused) return line(AppStrings.tabMicPaused, icon: Icons.replay);
        return line(AppStrings.tabMicTooSlow(techniqueMinBpm), icon: Icons.replay);
    }
  }
}
