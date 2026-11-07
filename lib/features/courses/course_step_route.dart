import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/lessons/lesson.dart';
import '../melodies/melody_step_screen.dart';
import '../open_chords/open_chord_step_screen.dart';
import '../strumming/strum_step_screen.dart';
import 'course_registry.dart';

/// Un paso de cualquier curso del mapa: `/learn/lessons/course/<slug>/<paso>`.
class CourseStepRouteScreen extends StatelessWidget {
  const CourseStepRouteScreen({super.key, required this.slug, required this.stepId});

  final String slug;
  final String stepId;

  @override
  Widget build(BuildContext context) => switch (LessonCourseInfo.fromSlug(slug)) {
    LessonCourse.basics => MelodyStepScreen(course: LessonCourse.basics, stepId: stepId),
    LessonCourse.melodies => MelodyStepScreen(course: LessonCourse.melodies, stepId: stepId),
    LessonCourse.openChords => OpenChordStepScreen(stepId: stepId),
    LessonCourse.strumming => StrumStepScreen(stepId: stepId),
    null => Scaffold(
      appBar: AppBar(title: Text(AppStrings.lessonsTitle)),
      body: Center(child: Text(AppStrings.unitNotFound)),
    ),
  };
}
