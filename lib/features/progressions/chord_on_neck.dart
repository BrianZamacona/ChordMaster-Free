import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/theory/harmony.dart';
import '../../domain/theory/neck_notes.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../../ui/widgets/fretboard_diagram.dart';

/// Cada acorde de la progresión dentro de la escala, en todo el mástil (idea de
/// Pocket Composer): se elige un acorde y sus notas se resaltan entre las de la
/// escala ([chordInScaleOnNeck]). Sin escala que quepa en toda la progresión,
/// solo las notas del acorde.
class ChordOnNeck extends StatefulWidget {
  const ChordOnNeck({
    super.key,
    required this.degrees,
    required this.tonic,
    required this.scale,
    this.scaleName,
  });

  /// Los acordes de la progresión, cada uno una vez.
  final List<ProgressionDegree> degrees;
  final int tonic;

  /// Semitonos de la escala sobre la tónica; vacía si ninguna cabe.
  final List<int> scale;

  /// Cómo se llama la escala («C Natural Minor»), si hay.
  final String? scaleName;

  @override
  State<ChordOnNeck> createState() => _ChordOnNeckState();
}

class _ChordOnNeckState extends State<ChordOnNeck> {
  int _selected = 0;

  String _chord(ProgressionDegree d) =>
      chordDisplayName(root: pitchClassName(widget.tonic + d.semitones), type: d.type);

  @override
  Widget build(BuildContext context) {
    if (widget.degrees.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final index = _selected < widget.degrees.length ? _selected : 0;
    final degree = widget.degrees[index];
    final notes = chordInScaleOnNeck(
      rootSemitone: widget.tonic,
      scale: widget.scale,
      chordTones: degreeChordTones(degree),
    );
    final chordNotes = [for (final t in degreeChordIntervals(degree.type)) pitchClassName(widget.tonic + degree.semitones + t)];
    final name = widget.scaleName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.chordOnNeckTitle, style: text.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final (i, d) in widget.degrees.indexed)
              ChoiceChip(
                key: Key('chord-on-neck-$i'),
                label: Text(_chord(d)),
                selected: i == index,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name == null
              ? AppStrings.chordOnNeckAlone(_chord(degree), chordNotes.join(' '))
              : AppStrings.chordOnNeckInScale(_chord(degree), chordNotes.join(' '), name),
          key: const Key('chord-on-neck-hint'),
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 230,
          child: FretboardNeck(
            key: ValueKey('chord-on-neck-${degree.numeral}'),
            coordinates: notes.neck,
            highlighted: notes.chord,
            label: FretboardLabel.note,
            semanticLabel: name == null
                ? AppStrings.chordOnNeckAlone(_chord(degree), chordNotes.join(' '))
                : AppStrings.chordOnNeckInScale(_chord(degree), chordNotes.join(' '), name),
          ),
        ),
      ],
    );
  }
}
