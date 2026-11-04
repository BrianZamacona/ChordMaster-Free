import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/lessons/lesson_path.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';

/// Nombre visible de cada camino.
String trackName(LessonTrack track) => switch (track) {
      LessonTrack.foundations => AppStrings.trackFoundations,
      LessonTrack.rhythm => AppStrings.trackRhythm,
      LessonTrack.lead => AppStrings.trackLead,
    };

/// Fila de una lección: número (o ✓), título y duración.
class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.lesson,
    required this.done,
    required this.isNext,
  });

  final Lesson lesson;
  final bool done;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final (badgeColor, badgeText) = done
        ? (p.success, p.onAccent)
        : isNext
            ? (p.accent, p.onAccent)
            : (p.surfaceHigh, p.textSecondary);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNext ? BorderSide(color: p.accent) : BorderSide.none,
      ),
      child: InkWell(
        key: Key('lesson-${lesson.id}'),
        // push: atrás vuelve a la unidad desde donde se abrió.
        onTap: () => context.push('/learn/lessons/${lesson.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: badgeColor,
                child: done
                    ? Icon(Icons.check, color: badgeText, size: 20)
                    : Text(
                        LessonPath.labelOf(lesson),
                        style: musicMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title.text, style: text.titleSmall),
                    Text(
                      AppStrings.lessonMinutes(lesson.minutes),
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              if (done)
                Text(
                  AppStrings.lessonDone,
                  style: text.labelMedium?.copyWith(color: p.success),
                )
              else if (isNext)
                Text(
                  AppStrings.lessonNext,
                  style: text.labelMedium?.copyWith(color: p.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
