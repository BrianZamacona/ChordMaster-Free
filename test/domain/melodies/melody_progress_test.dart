import 'package:chordmaster_free/domain/melodies/melody_course.dart';
import 'package:chordmaster_free/domain/melodies/melody_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final playable = [
    for (final s in melodyStepsById.values)
      if (s.kind != MelodyStepKind.theory) s,
  ];
  final songs = [
    for (final s in playable)
      if (s.kind == MelodyStepKind.song) s,
  ];

  test('sin nada hecho: 0 estrellas y 0 canciones', () {
    const p = MelodyProgress();
    expect(p.starTotals, (0, playable.length * 3));
    expect(p.songTotals, (0, songs.length));
  });

  test('una canción a 85 BPM da dos estrellas y cuenta como hecha', () {
    final p = MelodyProgress(best: {songs.first.id: 85});
    expect(p.stars(songs.first), 2);
    expect(p.isDone(songs.first), isTrue);
    expect(p.starTotals.$1, 2);
    expect(p.songTotals.$1, 1);
  });

  test('la teoría se hace leyéndola, no con tempo', () {
    final theory = melodyStepsById.values.firstWhere((s) => s.kind == MelodyStepKind.theory);
    expect(MelodyProgress(best: {theory.id: 100}).isDone(theory), isFalse);
    expect(MelodyProgress(read: {theory.id}).isDone(theory), isTrue);
  });

  test('todas las estrellas se pueden ganar', () {
    final p = MelodyProgress(best: {for (final s in playable) s.id: 100});
    expect(p.starTotals.$1, p.starTotals.$2);
  });
}
