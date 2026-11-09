import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/open_chords/chord_shape.dart';
import '../../services/audio_service.dart';
import '../../ui/theme.dart';
import '../lessons/lesson_widgets.dart';
import '../lessons/tab_player.dart';

/// Los acordes de un ejercicio o canción en compases, que se pueden escuchar:
/// ▶ rasguea al tempo [bpm] (un golpe hacia abajo por pulso o, con
/// [patterns], el patrón de cada compás) y resalta la forma y la corchea que
/// suenan, con los mismos instantes del audio ([strumEvents]). Comparte con
/// las tablaturas el "uno a la vez" ([tabPlaybackProvider]).
class StrumPlayer extends ConsumerStatefulWidget {
  const StrumPlayer({
    super.key,
    required this.slots,
    required this.bpm,
    required this.beatsPerSlot,
    required this.beatsPerBar,
    this.patterns,
  });

  final List<ChordShape> slots;

  /// El patrón de rasgueo de cada forma (una letra por corchea).
  final List<String>? patterns;
  final int bpm;
  final int beatsPerSlot;
  final int beatsPerBar;

  @override
  ConsumerState<StrumPlayer> createState() => _StrumPlayerState();
}

class _StrumPlayerState extends ConsumerState<StrumPlayer> {
  static const _frame = Duration(milliseconds: 30);

  final _token = Object();
  final _clock = Stopwatch();
  Timer? _timer;
  int? _index;

  /// Corchea que suena, contando desde el principio.
  int? _eighth;
  late final ValueNotifier<Object?> _active;

  bool get _playing => _timer != null;

  @override
  void initState() {
    super.initState();
    _active = ref.read(tabPlaybackProvider)..addListener(_onActiveChanged);
  }

  @override
  void didUpdateWidget(StrumPlayer old) {
    super.didUpdateWidget(old);
    if (!identical(old.slots, widget.slots) || old.bpm != widget.bpm) _stop();
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
    final w = widget;
    ref
        .read(audioServiceProvider)
        .playTab(
          strumEvents(
            w.slots,
            bpm: w.bpm,
            beatsPerSlot: w.beatsPerSlot,
            patterns: w.patterns,
          ),
          seconds: strumDurationSeconds(
            w.slots.length,
            bpm: w.bpm,
            beatsPerSlot: w.beatsPerSlot,
          ),
        );
    _clock
      ..reset()
      ..start();
    _timer = Timer.periodic(_frame, (_) => _tick());
    setState(() {
      _index = 0;
      _eighth = 0;
    });
  }

  void _tick() {
    final w = widget;
    final eighth = strumEighthAt(
      _clock.elapsedMicroseconds / 1e6,
      w.slots.length,
      bpm: w.bpm,
      beatsPerSlot: w.beatsPerSlot,
    );
    if (eighth == null) {
      _stop(silence: false);
    } else if (eighth != _eighth) {
      setState(() {
        _eighth = eighth;
        _index = eighth ~/ (w.beatsPerSlot * 2);
      });
    }
  }

  void _stop({bool silence = true}) {
    if (!_playing) return;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    if (silence) ref.read(audioServiceProvider).stopAll();
    if (_active.value == _token) _active.value = null;
    if (mounted) {
      setState(() {
        _index = null;
        _eighth = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = widget;
    final perBar = w.beatsPerBar ~/ w.beatsPerSlot;
    final bars = [
      for (var i = 0; i < w.slots.length; i += perBar)
        [for (var j = i; j < i + perBar && j < w.slots.length; j++) j],
    ];
    final patterns = w.patterns;
    final current = _index ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (patterns != null && patterns.isNotEmpty) ...[
          StrumPatternView(
            key: const Key('strum-pattern'),
            pattern: patterns[current],
            highlight: _eighth == null ? null : _eighth! % (w.beatsPerSlot * 2),
          ),
          const SizedBox(height: 10),
        ],
        // Cuatro compases por renglón, como en una partitura (dos si cada
        // compás lleva dos acordes).
        LayoutBuilder(
          builder: (context, box) {
            final perRow = perBar == 1 ? 4 : 2;
            final width = (box.maxWidth - 6 * (perRow - 1)) / perRow;
            return Wrap(
              key: const Key('strum-chart'),
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final bar in bars)
                  Container(
                    width: width,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: p.outline, width: 2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final i in bar)
                          Container(
                            key: Key('strum-slot-$i'),
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: i == _index ? p.accent : null,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              w.slots[i].name,
                              style: musicMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: i == _index ? p.onAccent : p.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
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
                AppStrings.openChordsTimeSignature(w.beatsPerBar, w.bpm),
                style: musicMono(fontSize: 12, color: p.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
