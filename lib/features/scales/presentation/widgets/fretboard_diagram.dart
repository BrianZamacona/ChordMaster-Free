import 'package:flutter/material.dart';

import '../../../../core/constants/music_theory.dart';
import '../../../../core/utils/audio_utils.dart';
import '../../data/models/note_coordinate.dart';
import '../../data/models/scale_pattern.dart';

enum FretboardLabelMode { note, interval, finger }

class FretboardCellPayload {
  const FretboardCellPayload({
    required this.stringNumber,
    required this.fret,
    required this.note,
    required this.interval,
    required this.isRoot,
    required this.finger,
    this.noteWithOctave,
    this.frequencyHz,
  });

  final int stringNumber;
  final int fret;
  final String note;
  final String interval;
  final bool isRoot;
  final int? finger;
  final String? noteWithOctave;
  final double? frequencyHz;
}

class FretboardDiagram extends StatelessWidget {
  const FretboardDiagram({
    super.key,
    required this.pattern,
    this.rootColor = Colors.red,
    this.noteColor,
    this.height = 180,
    this.viewportStartFret,
    this.viewportEndFret,
    this.labelMode = FretboardLabelMode.note,
    this.tuningOpenNotes = const ['E', 'A', 'D', 'G', 'B', 'E'],
    this.tuningOpenMidi,
    this.onActiveCellTriggered,
  }) : assert(
          viewportStartFret == null ||
              viewportEndFret == null ||
              viewportStartFret <= viewportEndFret,
          'viewportStartFret must be <= viewportEndFret',
        );

  final ScalePattern pattern;
  final Color rootColor;
  final Color? noteColor;
  final double height;
  final int? viewportStartFret;
  final int? viewportEndFret;
  final FretboardLabelMode labelMode;
  final List<String> tuningOpenNotes;
  final List<int>? tuningOpenMidi;
  final ValueChanged<FretboardCellPayload>? onActiveCellTriggered;

  @override
  Widget build(BuildContext context) {
    final maxPatternString = pattern.coordinates.isEmpty
        ? tuningOpenNotes.length
        : pattern.coordinates
            .map((c) => c.string)
            .reduce((a, b) => a > b ? a : b);
    final stringCount = maxPatternString > tuningOpenNotes.length
        ? maxPatternString
        : tuningOpenNotes.length;
    final defaultStart = pattern.startingFret;
    final defaultEnd = pattern.startingFret + pattern.fretsSpan - 1;
    final startFret = viewportStartFret ?? defaultStart;
    final requestedEndFret = viewportEndFret ?? defaultEnd;
    final displayedFretCount = ((requestedEndFret - startFret) + 1).clamp(1, 24);
    final endFret = startFret + displayedFretCount - 1;
    final coordinatesByKey = <String, NoteCoordinate>{
      for (final c in pattern.coordinates) '${c.string}:${c.fret}': c,
    };
    final rootIndex = chromaticNotes.indexOf(pattern.root);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) => _InteractiveFretboardGrid(
          stringCount: stringCount,
          startFret: startFret,
          endFret: endFret,
          displayedFretCount: displayedFretCount,
          coordinatesByKey: coordinatesByKey,
          rootIndex: rootIndex,
          rootColor: rootColor,
          noteColor: noteColor ?? Theme.of(context).colorScheme.primary,
          colorScheme: Theme.of(context).colorScheme,
          labelMode: labelMode,
          tuningOpenNotes: tuningOpenNotes,
          tuningOpenMidi: tuningOpenMidi,
          onActiveCellTriggered: onActiveCellTriggered,
          width: constraints.maxWidth,
        ),
      ),
    );
  }
}

class _InteractiveFretboardGrid extends StatefulWidget {
  const _InteractiveFretboardGrid({
    required this.stringCount,
    required this.startFret,
    required this.endFret,
    required this.displayedFretCount,
    required this.coordinatesByKey,
    required this.rootIndex,
    required this.rootColor,
    required this.noteColor,
    required this.colorScheme,
    required this.labelMode,
    required this.tuningOpenNotes,
    required this.tuningOpenMidi,
    required this.onActiveCellTriggered,
    required this.width,
  });

  final int stringCount;
  final int startFret;
  final int endFret;
  final int displayedFretCount;
  final Map<String, NoteCoordinate> coordinatesByKey;
  final int rootIndex;
  final Color rootColor;
  final Color noteColor;
  final ColorScheme colorScheme;
  final FretboardLabelMode labelMode;
  final List<String> tuningOpenNotes;
  final List<int>? tuningOpenMidi;
  final ValueChanged<FretboardCellPayload>? onActiveCellTriggered;
  final double width;

  @override
  State<_InteractiveFretboardGrid> createState() =>
      _InteractiveFretboardGridState();
}

class _InteractiveFretboardGridState extends State<_InteractiveFretboardGrid> {
  String? _lastDraggedKey;

  static const _dotFrets = [3, 5, 7, 9, 12, 15, 17, 19, 21];
  static const _doubleDotFrets = [12, 24];

  String _cellKey(int stringNumber, int fret) => '$stringNumber:$fret';

  int _stringFromDisplayRow(int row) => widget.stringCount - row;

  void _triggerCellFromLocalPosition(Offset localPosition, double boardHeight) {
    if (widget.displayedFretCount <= 0 || widget.stringCount <= 0) return;
    final cellWidth = widget.width / widget.displayedFretCount;
    final cellHeight = boardHeight / widget.stringCount;
    if (cellWidth <= 0 || cellHeight <= 0) return;
    final col = (localPosition.dx / cellWidth).floor();
    final row = (localPosition.dy / cellHeight).floor();
    if (col < 0 ||
        col >= widget.displayedFretCount ||
        row < 0 ||
        row >= widget.stringCount) {
      return;
    }
    final fret = widget.startFret + col;
    final stringNumber = _stringFromDisplayRow(row);
    _triggerIfActive(stringNumber, fret, isDrag: true);
  }

  void _triggerIfActive(int stringNumber, int fret, {bool isDrag = false}) {
    final key = _cellKey(stringNumber, fret);
    final coordinate = widget.coordinatesByKey[key];
    if (coordinate == null) return;
    if (isDrag && key == _lastDraggedKey) return;
    _lastDraggedKey = key;
    final payload = _buildPayload(stringNumber, fret, coordinate);
    widget.onActiveCellTriggered?.call(payload);
  }

  FretboardCellPayload _buildPayload(
    int stringNumber,
    int fret,
    NoteCoordinate coordinate,
  ) {
    final openNote = (stringNumber - 1) >= 0 &&
            (stringNumber - 1) < widget.tuningOpenNotes.length
        ? widget.tuningOpenNotes[stringNumber - 1]
        : 'E';
    final openIndex = chromaticNotes.indexOf(openNote);
    final noteIndex = openIndex == -1 ? 0 : (openIndex + fret) % 12;
    final noteName = chromaticNotes[noteIndex];
    final semitoneFromRoot =
        widget.rootIndex == -1 ? -1 : (noteIndex - widget.rootIndex + 12) % 12;
    final fallbackInterval = semitoneFromRoot == -1
        ? ''
        : (intervalSymbols[semitoneFromRoot] ?? '$semitoneFromRoot');
    final interval =
        coordinate.interval.isNotEmpty ? coordinate.interval : fallbackInterval;

    String? noteWithOctave;
    double? frequency;
    if (widget.tuningOpenMidi != null &&
        widget.tuningOpenMidi!.length >= stringNumber) {
      final midi = widget.tuningOpenMidi![stringNumber - 1] + fret;
      noteWithOctave = AudioUtils.noteNameFromMidi(midi);
      frequency = AudioUtils.midiToFrequency(midi);
    }

    return FretboardCellPayload(
      stringNumber: stringNumber,
      fret: fret,
      note: coordinate.note.isNotEmpty ? coordinate.note : noteName,
      interval: interval,
      isRoot: coordinate.isRoot,
      finger: coordinate.finger,
      noteWithOctave: noteWithOctave,
      frequencyHz: frequency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardHeight = 146.0;
    final cellHeight = boardHeight / widget.stringCount;
    final cellWidth = widget.width / widget.displayedFretCount;

    return Column(
      children: [
        SizedBox(
          height: boardHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              _lastDraggedKey = null;
              _triggerCellFromLocalPosition(details.localPosition, boardHeight);
            },
            onPanUpdate: (details) =>
                _triggerCellFromLocalPosition(details.localPosition, boardHeight),
            onPanEnd: (_) => _lastDraggedKey = null,
            child: Stack(
              children: [
                Column(
                  children: List.generate(widget.stringCount, (row) {
                    final stringNumber = _stringFromDisplayRow(row);
                    final widthFactor = widget.stringCount <= 1
                        ? 0.0
                        : (stringNumber - 1) / (widget.stringCount - 1);
                    final lineThickness =
                        (2.0 - (1.2 * widthFactor)).clamp(0.8, 2.0);
                    return SizedBox(
                      height: cellHeight,
                      child: Row(
                        children: List.generate(widget.displayedFretCount, (col) {
                          final fret = widget.startFret + col;
                          final key = _cellKey(stringNumber, fret);
                          final coordinate = widget.coordinatesByKey[key];
                          final isActive = coordinate != null;
                          final payload = isActive
                              ? _buildPayload(stringNumber, fret, coordinate)
                              : null;
                          final label = payload == null
                              ? ''
                              : switch (widget.labelMode) {
                                  FretboardLabelMode.interval =>
                                    payload.interval,
                                  FretboardLabelMode.finger =>
                                    payload.finger?.toString() ?? '',
                                  FretboardLabelMode.note => payload.note,
                                };
                          return SizedBox(
                            width: cellWidth,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: isActive
                                  ? () => widget.onActiveCellTriggered
                                      ?.call(payload!)
                                  : null,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: widget.colorScheme.outline
                                          .withAlpha(180),
                                      width: (widget.startFret <= 0 && fret == 0)
                                          ? 3
                                          : 1,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          height: lineThickness,
                                          color: widget.colorScheme.onSurface
                                              .withAlpha(180),
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        width: (cellHeight * 0.6)
                                            .clamp(18.0, cellWidth * 0.8),
                                        height: (cellHeight * 0.6)
                                            .clamp(18.0, cellWidth * 0.8),
                                        decoration: BoxDecoration(
                                          color: payload!.isRoot
                                              ? widget.rootColor
                                              : widget.noteColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withAlpha(70),
                                            width: 0.8,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
                ..._dotFrets.where((fret) => fret >= widget.startFret && fret <= widget.endFret).expand((fret) {
                  final col = fret - widget.startFret;
                  final left = (col + 0.5) * cellWidth - 3.5;
                  if (_doubleDotFrets.contains(fret)) {
                    return [
                      Positioned(
                        left: left,
                        top: boardHeight * 0.25,
                        child: _FretMarkerDot(color: widget.colorScheme),
                      ),
                      Positioned(
                        left: left,
                        top: boardHeight * 0.7,
                        child: _FretMarkerDot(color: widget.colorScheme),
                      ),
                    ];
                  }
                  return [
                    Positioned(
                      left: left,
                      top: boardHeight * 0.47,
                      child: _FretMarkerDot(color: widget.colorScheme),
                    ),
                  ];
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(
            widget.displayedFretCount,
            (col) => SizedBox(
              width: cellWidth,
              child: Text(
                '${widget.startFret + col}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FretMarkerDot extends StatelessWidget {
  const _FretMarkerDot({required this.color});

  final ColorScheme color;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: color.onSurfaceVariant.withAlpha(65),
          shape: BoxShape.circle,
        ),
      );
}