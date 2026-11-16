import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/courses/course.dart';
import '../../domain/lessons/curriculum.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/melodies/basics_course.dart';
import '../../domain/melodies/melody_course.dart';
import '../../domain/tapping/tapping_course.dart';
import '../courses/course_registry.dart';
import '../courses/course_widgets.dart';
import '../lessons/tab_player.dart';

/// Un paso de un curso en tablatura (Primeros pasos, Melodías o Tapping): la
/// teoría se lee y se marca; un ejercicio o una canción se escucha en
/// tablatura al tempo elegido.
class MelodyStepScreen extends StatelessWidget {
  const MelodyStepScreen({super.key, required this.course, required this.stepId});

  final LessonCourse course;
  final String stepId;

  List<CourseLevel<TabCourseStep>> get _levels => switch (course) {
    LessonCourse.basics => basicsCourse,
    LessonCourse.tapping => tappingCourse,
    _ => melodyCourse,
  };

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
              // Las melodías suenan en corcheas iguales; el tapping, como
              // está escrito (tresillos y semicorcheas).
              playerNote: course == LessonCourse.tapping ? AppStrings.tappingPlayerNote : AppStrings.melodiesEvenRhythm,
              routeOf: course.stepRoute,
            ),
    );
  }
}
