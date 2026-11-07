import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/melodies/melody_course.dart';
import '../courses/course_progress.dart';
import '../courses/course_registry.dart';
import '../courses/course_widgets.dart';
import '../lessons/tab_player.dart';

/// Un paso del curso de melodías: la teoría se lee y se marca; un ejercicio o
/// una canción se escucha en tablatura al tempo elegido.
class MelodyStepScreen extends StatelessWidget {
  const MelodyStepScreen({super.key, required this.stepId});

  final String stepId;

  @override
  Widget build(BuildContext context) {
    final step = melodyStepsById[stepId];
    return Scaffold(
      appBar: AppBar(title: Text(step?.title.text ?? AppStrings.hubMelodies)),
      body: step == null
          ? Center(child: Text(AppStrings.guideNotFound))
          : CourseStepView(
              course: CourseId.melodies,
              levels: melodyCourse,
              step: step,
              body: Text(step.body.text, style: Theme.of(context).textTheme.bodyLarge),
              player: (bpm) => TabPlayer(notes: step.tab, bpm: bpm),
              playerNote: AppStrings.melodiesEvenRhythm,
              routeOf: LessonCourse.melodies.stepRoute,
            ),
    );
  }
}
