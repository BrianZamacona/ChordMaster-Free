import '../../core/constants/app_strings.dart';
import '../../core/constants/scale_names.dart';
import '../../domain/lessons/lesson.dart';
import '../../domain/licks/lick.dart';
import '../../domain/theory/notes.dart';

/// Nombre corto de una técnica.
String techniqueLabel(TabTechnique t) => switch (t) {
  TabTechnique.none => '',
  TabTechnique.hammerOn => AppStrings.techniqueNameHammerOn,
  TabTechnique.pullOff => AppStrings.techniqueNamePullOff,
  TabTechnique.slide => AppStrings.techniqueNameSlide,
  TabTechnique.bend => AppStrings.techniqueNameBend,
  TabTechnique.release => AppStrings.techniqueNameRelease,
  TabTechnique.vibrato => AppStrings.techniqueNameVibrato,
  TabTechnique.palmMute => AppStrings.techniqueNamePalmMute,
  TabTechnique.dead => AppStrings.techniqueNameDead,
};

String lickKindLabel(LickKind kind) => switch (kind) {
  LickKind.riff => AppStrings.licksKindRiff,
  LickKind.lick => AppStrings.licksKindLick,
  LickKind.fill => AppStrings.licksKindFill,
  LickKind.solo => AppStrings.licksKindSolo,
};

/// "A Pentatónica menor": tónica y nombre de la escala.
String lickScaleLabel(LessonScale scale) =>
    '${pitchClassName(scale.root)} ${scaleDisplayName(scale.scaleId, const [])}';
