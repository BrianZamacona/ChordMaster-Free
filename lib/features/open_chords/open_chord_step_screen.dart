import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/open_chords/open_chords_course.dart';
import '../courses/chord_shape_diagrams.dart';
import '../courses/course_progress.dart';
import '../courses/course_registry.dart';
import '../courses/course_widgets.dart';
import '../courses/strum_player.dart';
import 'open_chords_course_provider.dart';

/// Un paso del curso de acordes abiertos: su texto, los diagramas (enteros o
/// a medio armar) y, si se toca, los compases que suenan al tempo elegido.
class OpenChordStepScreen extends ConsumerWidget {
  const OpenChordStepScreen({super.key, required this.stepId});

  final String stepId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(openChordsCourseProvider);
    final step = levels == null
        ? null
        : courseSteps(levels).where((s) => s.id == stepId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(step?.title.text ?? AppStrings.hubOpenChords)),
      body: switch ((levels, step)) {
        (null, _) => const Center(child: CircularProgressIndicator()),
        (final levels?, final step?) => CourseStepView(
          course: CourseId.openChords,
          levels: levels,
          step: step,
          body: _StepBody(step: step),
          player: (bpm, _) => StrumPlayer(
            slots: step.slots,
            bpm: bpm,
            beatsPerSlot: step.beatsPerSlot,
            beatsPerBar: step.beatsPerBar,
          ),
          playerNote: AppStrings.openChordsStrumNote,
          routeOf: LessonCourse.openChords.stepRoute,
        ),
        _ => Center(child: Text(AppStrings.guideNotFound)),
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final OpenChordStep step;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(step.body.text, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 12),
      ChordShapeDiagrams(shapes: step.chords),
    ],
  );
}
