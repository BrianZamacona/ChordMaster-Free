import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/strumming/strumming_course.dart';
import '../courses/chord_shape_diagrams.dart';
import '../courses/course_progress.dart';
import '../courses/course_registry.dart';
import '../courses/course_widgets.dart';
import '../courses/strum_player.dart';
import '../lessons/lesson_widgets.dart';
import 'strumming_course_provider.dart';

/// Un paso del curso de rasgueos: su texto, el patrón dibujado y, si se toca,
/// los compases con su patrón al tempo elegido.
class StrumStepScreen extends ConsumerWidget {
  const StrumStepScreen({super.key, required this.stepId});

  final String stepId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(strummingCourseProvider);
    final step = levels == null
        ? null
        : courseSteps(levels).where((s) => s.id == stepId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(step?.title.text ?? AppStrings.hubStrumming)),
      body: switch ((levels, step)) {
        (null, _) => const Center(child: CircularProgressIndicator()),
        (final levels?, final step?) => CourseStepView(
          course: CourseId.strumming,
          levels: levels,
          step: step,
          body: _StepBody(step: step),
          player: (bpm, _) => StrumPlayer(
            slots: step.slots,
            patterns: step.patterns,
            bpm: bpm,
            beatsPerSlot: 4,
            beatsPerBar: 4,
          ),
          playerNote: AppStrings.strummingPlayerNote,
          routeOf: LessonCourse.strumming.stepRoute,
        ),
        _ => Center(child: Text(AppStrings.guideNotFound)),
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.step});

  final StrumStep step;

  @override
  Widget build(BuildContext context) {
    final chords = {for (final s in step.slots) s.name: s}.values.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(step.body.text, style: Theme.of(context).textTheme.bodyLarge),
        if (step.kind == CourseStepKind.theory && step.patterns.isNotEmpty) ...[
          const SizedBox(height: 12),
          StrumPatternView(pattern: step.patterns.single),
        ],
        if (chords.isNotEmpty) ...[
          const SizedBox(height: 12),
          ChordShapeDiagrams(shapes: chords, size: chords.length > 2 ? 72 : 100),
        ],
      ],
    );
  }
}
