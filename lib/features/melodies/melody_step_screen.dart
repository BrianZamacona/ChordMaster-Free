import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/melodies/basics_course.dart';
import '../../domain/melodies/melody_course.dart';
import '../courses/course_registry.dart';
import '../courses/course_widgets.dart';
import '../lessons/tab_player.dart';

/// Un paso de un curso de melodía (Primeros pasos o Melodías): la teoría se
/// lee y se marca; un ejercicio o una canción se escucha en tablatura al
/// tempo elegido.
class MelodyStepScreen extends StatelessWidget {
  const MelodyStepScreen({super.key, required this.course, required this.stepId});

  final LessonCourse course;
  final String stepId;

  List<MelodyLevel> get _levels =>
      course == LessonCourse.basics ? basicsCourse : melodyCourse;

  @override
  Widget build(BuildContext context) {
    final levels = _levels;
    final step = courseSteps(levels).where((s) => s.id == stepId).firstOrNull;
    final title = unitOfCourse(course).title.text;
    return Scaffold(
      appBar: AppBar(title: Text(step?.title.text ?? title)),
      body: step == null
          ? Center(child: Text(AppStrings.guideNotFound))
          : CourseStepView(
              course: course.progressId,
              levels: levels,
              step: step,
              body: Text(step.body.text, style: Theme.of(context).textTheme.bodyLarge),
              player: (bpm, onPlayed, onBpm) => TabPlayer(
                notes: step.tab,
                bpm: bpm,
                onPlayed: onPlayed,
                onBpmChanged: onBpm,
              ),
              playerNote: AppStrings.melodiesEvenRhythm,
              routeOf: course.stepRoute,
            ),
    );
  }
}
