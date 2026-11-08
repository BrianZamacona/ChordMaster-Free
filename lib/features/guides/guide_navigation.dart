import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/guides/guides.dart';
import '../../domain/lessons/curriculum.dart';
import '../chords/chord_viewmodel.dart';
import '../courses/course_registry.dart';

/// Ruta de un módulo y si vive en otra pestaña (`go`) o se apila en Aprender
/// (`push`, para que atrás vuelva a la guía).
(String route, bool stacked) moduleRoute(GuideModule module) => switch (module) {
  GuideModule.tuner => ('/tools/tuner', false),
  GuideModule.metronome => ('/tools/metronome', false),
  GuideModule.earTraining => ('/practice/ear-training', false),
  GuideModule.rhythmGame => ('/practice/rhythm', false),
  GuideModule.songs => ('/practice/songs', false),
  GuideModule.health => ('/progress/health', false),
  GuideModule.technique => ('/practice/technique', false),
  GuideModule.progressions => ('/learn/progressions', true),
  GuideModule.doubleStops => ('/learn/scales/double-stops', true),
  GuideModule.circle => ('/learn/circle', true),
  GuideModule.capo => ('/learn/capo', true),
  GuideModule.scales => ('/learn/scales', true),
};

/// Texto del botón de un capítulo.
String guideTargetLabel(GuideTarget target) => switch (target) {
  LessonLink(:final lessonId) => AppStrings.guideOpenLesson(
    lessonsById[lessonId]?.title.text ?? lessonId,
  ),
  CourseLink(:final course) => AppStrings.guideOpenLesson(unitOfCourse(course).title.text),
  ScaleLink() => AppStrings.lessonOpenScale,
  ChordLink(:final chord) => AppStrings.guideOpenChord(chord),
  WorkoutLink() => AppStrings.hubWorkouts,
  // El nombre del capo es una pregunta: "Abrir ¿Qué capo uso?" no se lee.
  ModuleLink(module: GuideModule.capo) => AppStrings.guideOpenCapo,
  ModuleLink(:final module) => AppStrings.guideOpenModuleNamed(_moduleName(module)),
};

String _moduleName(GuideModule module) => switch (module) {
  GuideModule.tuner => AppStrings.moduleTuner,
  GuideModule.metronome => AppStrings.moduleMetronome,
  GuideModule.earTraining => AppStrings.hubEar,
  GuideModule.rhythmGame => AppStrings.hubRhythm,
  GuideModule.songs => AppStrings.hubSongs,
  GuideModule.health => AppStrings.hubHealth,
  GuideModule.technique => AppStrings.hubTechnique,
  GuideModule.progressions => AppStrings.hubProgressions,
  GuideModule.doubleStops => AppStrings.dsTitle,
  GuideModule.circle => AppStrings.circleTitle,
  GuideModule.capo => AppStrings.hubCapo,
  GuideModule.scales => AppStrings.hubScales,
};

/// Icono del botón de un capítulo.
IconData guideTargetIcon(GuideTarget target) => switch (target) {
  LessonLink() => Icons.school_outlined,
  CourseLink() => Icons.school_outlined,
  ScaleLink() => Icons.linear_scale,
  ChordLink() => Icons.library_music_outlined,
  WorkoutLink() => Icons.fitness_center,
  ModuleLink() => Icons.open_in_new,
};

/// Abre lo que enlaza un capítulo.
Future<void> openGuideTarget(
  BuildContext context,
  WidgetRef ref,
  GuideTarget target,
) async {
  switch (target) {
    case LessonLink(:final lessonId):
      await context.push('/learn/lessons/$lessonId');
    case CourseLink(:final course, :final stepId):
      await context.push(course.stepRoute(stepId));
    case ChordLink(:final chord):
      final found = ref.read(chordViewModelProvider.notifier).findByName(chord);
      if (found != null) {
        await context.push('/learn/chords/${Uri.encodeComponent(found.name)}');
      }
    case ScaleLink(:final scale, :final position):
      final all = await ref.read(allScalesProvider.future);
      final definition = all.where((s) => s.id == scale.scaleId).firstOrNull ??
          (await ref.read(allModesProvider.future))
              .where((s) => s.id == scale.scaleId)
              .firstOrNull;
      if (definition == null || !context.mounted) return;
      await context.push(
        '/learn/scales/${definition.id}?root=${scale.root}'
        '${position == null ? '' : '&position=$position'}',
        extra: definition,
      );
    case WorkoutLink(:final scale):
      context.go(
        '/practice/workouts?scale=${scale.scaleId}&root=${scale.root}',
      );
    case ModuleLink(:final module):
      final (route, stacked) = moduleRoute(module);
      if (stacked) {
        await context.push(route);
      } else {
        context.go(route);
      }
  }
}
