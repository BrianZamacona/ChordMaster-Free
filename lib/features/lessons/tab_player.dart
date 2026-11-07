import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/practice/tab_playback.dart';
import '../../services/audio_service.dart';
import '../../ui/theme.dart';
import 'lesson_tab.dart';

/// Qué tablatura está sonando: al empezar otra, la anterior se detiene.
final tabPlaybackProvider = Provider<ValueNotifier<Object?>>((ref) {
  final notifier = ValueNotifier<Object?>(null);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Una tablatura que se puede escuchar: ▶ la toca con el sintetizador al tempo
/// [bpm] y resalta la nota que suena, con los mismos instantes del audio
/// ([tabEvents]).
class TabPlayer extends ConsumerStatefulWidget {
  const TabPlayer({super.key, required this.notes, required this.bpm});

  final List<TabNote> notes;
  final int bpm;

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

  bool get _playing => _timer != null;

  @override
  void initState() {
    super.initState();
    _active = ref.read(tabPlaybackProvider)..addListener(_onActiveChanged);
  }

  @override
  void didUpdateWidget(TabPlayer old) {
    super.didUpdateWidget(old);
    if (!identical(old.notes, widget.notes) || old.bpm != widget.bpm) _stop();
  }

  @override
  void dispose() {
    _active.removeListener(_onActiveChanged);
    if (_playing && _active.value == _token) {
      ref.read(audioServiceProvider).stopAll();
      _active.value = null;
    }
    _timer?.cancel();
    super.dispose();
  }

  void _onActiveChanged() {
    if (_active.value != _token && _playing) _stop(silence: false);
  }

  void _play() {
    _active.value = _token;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonTabView(notes: widget.notes, highlight: _index),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonalIcon(
              key: const Key('tab-play'),
              onPressed: _playing ? _stop : _play,
              icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
              label: Text(_playing ? AppStrings.tabStop : AppStrings.tabListen),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                AppStrings.tabAtBpm(widget.bpm),
                style: musicMono(fontSize: 12, color: p.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
