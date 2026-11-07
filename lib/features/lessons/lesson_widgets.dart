import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';

/// Conteo de la corchea [index] de [pattern]: un compás de 6 corcheas es 6/8 y
/// se cuenta de 1 a 6; uno de 8 es 4/4 y se cuenta "1 [and] 2 [and]…".
String strumCountAt(String pattern, int index, String and) {
  if (pattern.length == 6) return '${index + 1}';
  return index.isEven ? '${index ~/ 2 + 1}' : and;
}

/// Nombre visible de cada camino.
String trackName(LessonTrack track) => switch (track) {
      LessonTrack.foundations => AppStrings.trackFoundations,
      LessonTrack.rhythm => AppStrings.trackRhythm,
      LessonTrack.lead => AppStrings.trackLead,
    };

/// El dibujo de una unidad, generado desde los datos de la app.
class UnitArtView extends ConsumerWidget {
  const UnitArtView({super.key, required this.art, this.size = 64});

  final UnitArt art;

  /// Alto aproximado del dibujo.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return SizedBox(
      height: size,
      child: Center(
        child: switch (art) {
          ChordArt(:final chord) => _ChordArt(name: chord, size: size),
          ScaleArt(:final scale) => _NoteRow(
              notes: _scaleNotes(ref, scale),
              root: pitchClassName(scale.root),
            ),
          // Un compás se lee en una línea: se reduce antes que partirse.
          StrumArt(:final pattern) => FittedBox(
              key: const Key('unit-art-strum'),
              fit: BoxFit.scaleDown,
              child: Text(
                [
                  for (final s in pattern.split(''))
                    switch (s) {
                      'D' => '↓',
                      'U' => '↑',
                      _ => '·',
                    },
                ].join(' '),
                maxLines: 1,
                style: musicMono(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w600,
                  color: p.accent,
                ),
              ),
            ),
          NotesArt(:final notes) => _NoteRow(notes: notes),
        },
      ),
    );
  }

  /// Notas de la escala en su tónica; vacío mientras carga el JSON.
  static List<String> _scaleNotes(WidgetRef ref, LessonScale scale) {
    final definition = ref
        .watch(allScalesProvider)
        .value
        ?.where((s) => s.id == scale.scaleId)
        .firstOrNull;
    return [
      for (final i in definition?.intervals ?? const <int>[])
        pitchClassName(scale.root + i),
    ];
  }
}

class _ChordArt extends ConsumerWidget {
  const _ChordArt({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reconstruye al terminar de cargar la biblioteca.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final chord = ref.read(chordViewModelProvider.notifier).findByName(name);
    if (chord == null) {
      return Text(name, style: Theme.of(context).textTheme.titleLarge);
    }
    return ChordDiagramWidget(
      chordName: chord.name,
      fretPositions: chord.fretPositions,
      fingerPositions: chord.fingerPositions,
      root: chord.root,
      baseFret: chord.baseFret,
      size: size,
      showChordName: false,
    );
  }
}

/// Nombres de nota en fila; la tónica, si se indica, va en un cuadrado
/// (la raíz se marca con forma, no solo con color).
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.notes, this.root});

  final List<String> notes;
  final String? root;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final n in notes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: n == root ? p.intervalRoot : null,
              border: Border.all(color: n == root ? p.intervalRoot : p.outline),
              borderRadius: BorderRadius.circular(n == root ? 2 : 10),
            ),
            child: Text(
              n,
              style: musicMono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: n == root ? p.onInterval : p.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Columna de la izquierda de cada paso: la línea que une los pasos y el
/// círculo del paso. Mide lo mismo que el contenido de la derecha.
class StepRail extends StatelessWidget {
  const StepRail({
    super.key,
    required this.circle,
    required this.isFirst,
    required this.isLast,
    required this.topDone,
    required this.bottomDone,
  });

  final Widget circle;
  final bool isFirst;
  final bool isLast;
  final bool topDone;
  final bool bottomDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget line({required bool visible, required bool done}) => Expanded(
          child: visible
              ? Container(width: 3, color: done ? p.accent : p.outline)
              : const SizedBox.shrink(),
        );
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          SizedBox(
            height: 14,
            child: isFirst
                ? null
                : Container(width: 3, color: topDone ? p.accent : p.outline),
          ),
          circle,
          line(visible: !isLast, done: bottomDone),
        ],
      ),
    );
  }
}
