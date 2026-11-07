import 'package:chordmaster_free/domain/courses/course.dart';
import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final steps = courseSteps(melodyCourse);
  final playable = [
    for (final s in steps)
      if (s.kind != CourseStepKind.theory) s,
  ];
  final songs = [
    for (final s in playable)
      if (s.kind == CourseStepKind.song) s,
  ];

  test('estrellas: 60, 80 y 100 BPM; se abre en la próxima', () {
    expect(starsFor(null), 0);
    expect(starsFor(55), 0);
    expect(starsFor(60), 1);
    expect(starsFor(95), 2);
    expect(starsFor(120), 3);
    expect(startTempoFor(null), 60);
    expect(startTempoFor(60), 80);
    expect(startTempoFor(85), 100);
    expect(startTempoFor(100), 100);
  });

  test('sin nada hecho: 0 estrellas y 0 canciones', () {
    const p = CourseProgress();
    expect(p.starTotals(steps), (0, playable.length * 3));
    expect(p.songTotals(steps), (0, songs.length));
  });

  test('una canción a 85 BPM da dos estrellas y cuenta como hecha', () {
    final p = CourseProgress(best: {songs.first.id: 85});
    expect(p.stars(songs.first), 2);
    expect(p.isDone(songs.first), isTrue);
    expect(p.starTotals(steps).$1, 2);
    expect(p.songTotals(steps).$1, 1);
  });

  test('la teoría se hace leyéndola, no con tempo', () {
    final theory = steps.firstWhere((s) => s.kind == CourseStepKind.theory);
    expect(CourseProgress(best: {theory.id: 100}).isDone(theory), isFalse);
    expect(CourseProgress(read: {theory.id}).isDone(theory), isTrue);
  });

  test('todas las estrellas se pueden ganar', () {
    final p = CourseProgress(best: {for (final s in playable) s.id: 100});
    expect(p.starTotals(steps).$1, p.starTotals(steps).$2);
  });

  test('siguiente paso, nivel y numeración', () {
    expect(nextCourseStep(melodyCourse, steps.first)!.id, steps[1].id);
    expect(nextCourseStep(melodyCourse, steps.last), isNull);
    expect(courseLevelOf(melodyCourse, melodyCourse[1].steps.first), 2);
    final level = melodyCourse.first;
    expect(courseExerciseNumber(level, level.steps.first), isNull); // teoría
    expect(courseExerciseNumber(level, level.steps[1]), 1);
  });
}
