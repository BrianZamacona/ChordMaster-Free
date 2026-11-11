import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/play_along.dart';
import '../../domain/practice/tab_notation.dart';
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
/// ([tabEvents]). Se puede practicar un renglón suelto y repetirlo en bucle.
///
/// Con [onPlayed], además se puede tocar con el micrófono ("Tocar yo"):
/// resalta la nota que toca, marca las que salieron y, al terminar la
/// tablatura entera, entrega el resultado. Si hubo errores o una pausa,
/// propone repetir ese renglón en bucle y, con [onBpmChanged], más lento.
class TabPlayer extends ConsumerStatefulWidget {
  const TabPlayer({
    super.key,
    required this.notes,
    required this.bpm,
    this.chordLabels = const {},
    this.swing = TabSwing.none,
    this.onPlay,
    this.onPlayed,
    this.onBpmChanged,
  });

  final List<TabNote> notes;
  final int bpm;

  /// El acorde que entra en cada nota, escrito encima de la tablatura.
  final Map<int, String> chordLabels;

  /// Swing de la tablatura: corre el contratiempo al sonar y al marcarlo.
  final TabSwing swing;

  /// Se llama al empezar a sonar (las rutinas lo anotan como día de práctica).
  final VoidCallback? onPlay;

  /// Se llama al terminar de tocar la tablatura entera con el micrófono.
  final ValueChanged<PlayAlongResult>? onPlayed;

  /// Cambia el tempo (lo guarda la pantalla): "más lento" lo usa.
  final ValueChanged<int>? onBpmChanged;

  @override
  ConsumerState<TabPlayer> createState() => _TabPlayerState();
}

class _TabPlayerState extends ConsumerState<TabPlayer> {
  /// Cada 30 ms basta para que la marca no se atrase a la vista.
  static const _frame = Duration(milliseconds: 30);

  /// Cuánto se ve el resultado antes de volver a escuchar en bucle.
  static const _loopPause = Duration(milliseconds: 1500);

  final _token = Object();
  final _clock = Stopwatch();
  Timer? _timer;
  Timer? _again;
  int? _index;
  late final ValueNotifier<Object?> _active;
  late final AudioService _audio;
  PlayAlongViewModel? _mic;

  /// "Repite el renglón": empezar a sonar cuando llegue este tempo.
  int? _playAtBpm;

  /// El renglón que se practica (`null` = toda la tablatura) y si se repite.
  int? _line;
  bool _loop = false;

  /// Pasadas limpias seguidas con el micrófono en bucle.
  int _streak = 0;

  bool get _playing => _timer != null;

  ({int start, int end}) get _range => _line == null
      ? (start: 0, end: widget.notes.length)
      : tabLineRange(widget.notes.length, _line!);

  List<TabNote> get _part => widget.notes.sublist(_range.start, _range.end);

  @override
  void initState() {
    super.initState();
    _active = ref.read(tabPlaybackProvider)..addListener(_onActiveChanged);
    _audio = ref.read(audioServiceProvider);
    if (widget.onPlayed != null) _mic = ref.read(playAlongProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pestaña oculta: el micrófono no sigue escuchando por detrás.
    if (!TickerMode.valuesOf(context).enabled) {
      _again?.cancel();
      _releaseMic();
    }
  }

  @override
  void didUpdateWidget(TabPlayer old) {
    super.didUpdateWidget(old);
    // Por contenido: hay pantallas que arman la lista en cada build.
    final same = listEquals(old.notes, widget.notes);
    if (!same || old.bpm != widget.bpm || old.swing != widget.swing) _stop();
    if (!same) {
      _again?.cancel();
      _line = null;
      _playAtBpm = null;
      _releaseMic();
    }
    if (_playAtBpm != null && _playAtBpm == widget.bpm) {
      _playAtBpm = null;
      _playAfterFrame();
    }
  }

  @override
  void dispose() {
    _active.removeListener(_onActiveChanged);
    if (_playing && _active.value == _token) {
      _audio.stopAll();
      _active.value = null;
    }
    _timer?.cancel();
    _again?.cancel();
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
    _start();
  }

  /// Suena el tramo elegido desde el principio (también al volver en bucle).
  void _start() {
    final part = _part;
    _audio.playTab(
      tabSounds(part, bpm: widget.bpm, swing: widget.swing),
      seconds: tabDurationSeconds(part, bpm: widget.bpm, swing: widget.swing),
    );
    _clock
      ..reset()
      ..start();
    _timer?.cancel();
    _timer = Timer.periodic(_frame, (_) => _tick());
    setState(() => _index = 0);
  }

  void _tick() {
    final elapsed = _clock.elapsedMicroseconds / 1e6;
    final part = _part;
    final index = tabIndexAt(elapsed, part, bpm: widget.bpm, swing: widget.swing);
    if (index != null) {
      if (index != _index) setState(() => _index = index);
      return;
    }
    // Terminó la última nota: en bucle, otra vez apenas deja de sonar.
    if (_loop && elapsed >= tabEndSeconds(part, bpm: widget.bpm, swing: widget.swing)) {
      _start();
    } else if (!_loop) {
      _stop(silence: false);
    }
  }

  void _stop({bool silence = true}) {
    if (!_playing) return;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    if (silence) _audio.stopAll();
    if (_active.value == _token) _active.value = null;
    if (mounted) setState(() => _index = null);
  }

  void _listenMic() {
    _again?.cancel();
    _stop();
    _mic!.start(_token, _part, swing: widget.swing);
  }

  void _stopMic() {
    _again?.cancel();
    _streak = 0;
    _mic!.stop();
  }

  /// Otro tramo: se corta lo que sonaba o escuchaba.
  void _selectLine(int? line) {
    if (line == _line) return;
    _again?.cancel();
    _stop();
    if (_mic != null && ref.read(playAlongProvider).owner == _token) _mic!.stop();
    setState(() {
      _line = line;
      _streak = 0;
    });
  }

  void _toggleLoop(bool loop) {
    if (!loop) _again?.cancel();
    setState(() {
      _loop = loop;
      _streak = 0;
    });
  }

  /// "Repite el renglón N (más lento)": queda ese renglón en bucle, baja el
  /// tempo si la pantalla lo permite y empieza a sonar para escucharlo.
  void _practice(int line) {
    _again?.cancel();
    _mic?.stop();
    final slower = slowerBpm(widget.bpm);
    final changes = widget.onBpmChanged != null && slower != widget.bpm;
    setState(() {
      _line = line;
      _loop = true;
      _streak = 0;
    });
    if (changes) {
      // El cambio de tempo detiene lo que suena: se escucha cuando llegue.
      _playAtBpm = slower;
      widget.onBpmChanged!(slower);
    } else {
      _playAfterFrame();
    }
  }

  void _playAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_playing) _play();
    });
  }

  void _onFinished(PlayAlongResult result) {
    final whole = _line == null;
    if (whole) widget.onPlayed?.call(result);
    if (!_loop) return;
    setState(() => _streak = result.clean ? _streak + 1 : 0);
    _again = Timer(_loopPause, () {
      if (mounted) _listenMic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final onPlayed = widget.onPlayed;
    // Solo los reproductores con micrófono miran su estado.
    final mic = onPlayed == null ? null : ref.watch(playAlongProvider);
    final mine = mic != null && mic.owner == _token ? mic : null;
    final listening = mine?.listening ?? false;
    final finished = mine?.status == PlayAlongStatus.finished;
    if (onPlayed != null) {
      ref.listen(playAlongProvider, (prev, next) {
        if (next.owner == _token &&
            next.status == PlayAlongStatus.finished &&
            prev?.status != PlayAlongStatus.finished) {
          _onFinished(next.result!);
        }
      });
    }
    final range = _range;
    final lines = tabLineCount(widget.notes.length);
    final practice = finished && _line == null ? mine!.result!.lineToPractice : null;
    final slower = widget.onBpmChanged == null ? null : slowerBpm(widget.bpm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonTabView(
          notes: widget.notes,
          swing: widget.swing,
          showFingers: true,
          chordLabels: widget.chordLabels,
          focusLine: _line,
          highlight: listening
              ? range.start + mine!.position
              : (_index == null ? null : range.start + _index!),
          playedFrom: range.start,
          played: listening || finished ? range.start + mine!.position : 0,
        ),
        const SizedBox(height: 6),
        Wrap(
          key: const Key('tab-sections'),
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (lines > 1) ...[
              Text(AppStrings.tabSection, style: text.labelLarge),
              ChoiceChip(
                key: const Key('tab-line-all'),
                label: Text(AppStrings.tabAll),
                selected: _line == null,
                onSelected: (_) => _selectLine(null),
              ),
              for (var i = 0; i < lines; i++)
                ChoiceChip(
                  key: Key('tab-line-$i'),
                  label: Text('${i + 1}', semanticsLabel: AppStrings.tabLine(i + 1)),
                  selected: _line == i,
                  onSelected: (_) => _selectLine(i),
                ),
            ],
            FilterChip(
              key: const Key('tab-loop'),
              // Encendido, el fondo del chip es claro: el ícono va en el texto.
              avatar: Icon(Icons.repeat, size: 18, color: _loop ? p.textPrimary : p.textSecondary),
              label: Text(AppStrings.tabLoop),
              selected: _loop,
              showCheckmark: false,
              onSelected: _toggleLoop,
            ),
          ],
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
                onPressed: listening ? _stopMic : _listenMic,
                icon: Icon(listening ? Icons.stop : Icons.mic),
                label: Text(listening ? AppStrings.tabStop : AppStrings.tabPlayMic),
              ),
            Text(
              tabHasRhythm(widget.notes, swing: widget.swing)
                  ? AppStrings.tabAtBpmRhythm(widget.bpm)
                  : AppStrings.tabAtBpm(widget.bpm),
              style: musicMono(fontSize: 12, color: p.textSecondary),
            ),
          ],
        ),
        if (onPlayed != null) ...[
          const SizedBox(height: 6),
          _MicStatus(
            state: mine,
            notes: _part,
            onOpenSettings: _mic!.openSettings,
          ),
          if (finished && _line != null && mine!.result!.clean) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.tabLineNoRecord,
              key: const Key('tab-line-no-record'),
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ],
          if (_loop && _streak > 0) ...[
            const SizedBox(height: 4),
            Text(
              AppStrings.tabCleanStreak(_streak),
              key: const Key('tab-streak'),
              style: musicMono(fontSize: 13, fontWeight: FontWeight.w600, color: p.success),
            ),
          ],
          if (practice != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('tab-practice-line'),
                icon: const Icon(Icons.slow_motion_video),
                label: Text(AppStrings.tabPracticeLine(practice + 1, slower)),
                onPressed: () => _practice(practice),
              ),
            ),
          ],
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

  /// Las notas que se están tocando (el tramo elegido).
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
        return Text(
          notes.any((n) => n.isChord) ? AppStrings.tabMicHintChords : AppStrings.tabMicHint,
          key: const Key('tab-mic-status'),
          style: secondary,
        );
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
        if (r.clean && r.cleanBpm != null) {
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
