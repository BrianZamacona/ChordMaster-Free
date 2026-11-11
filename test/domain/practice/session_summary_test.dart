import 'package:chordmaster_free/domain/practice/session_summary.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:flutter_test/flutter_test.dart';

PracticeRun run(
  RunTarget t, {
  int mistakes = 0,
  int? bpm = 80,
  int? line,
  int tempo = 80,
  int? record,
}) => PracticeRun(
  target: t,
  mistakes: mistakes,
  bpm: bpm,
  clean: mistakes == 0 && line == null,
  lineToPractice: line,
  tempo: tempo,
  newRecord: record,
);

void main() {
  const ode = CourseStepTarget('melodies', 'mo_ode');
  const mary = CourseStepTarget('melodies', 'mm_mary');
  const spider = TechniqueTarget(TechniqueExercise.spider, 5);

  test('las claves se leen de vuelta', () {
    for (final t in [ode, spider, const LickTarget('folk_lick')]) {
      final back = RunTarget.fromKey(t.key)!;
      expect(back.key, t.key);
    }
    expect(RunTarget.fromKey('technique:nada:5'), isNull);
    expect(RunTarget.fromKey('otra cosa'), isNull);
  });

  test('una pasada se guarda y se lee igual; datos dañados se ignoran', () {
    final r = run(ode, mistakes: 2, line: 1, tempo: 70);
    final back = PracticeRun.fromJson(r.toJson())!;
    expect(back.toJson(), r.toJson());
    expect(PracticeRun.fromJson({'target': 'x'}), isNull);
    expect(PracticeRun.fromJson('basura'), isNull);
  });

  test('sin pasadas, vacío', () {
    expect(summarizeSession(const []).isEmpty, isTrue);
  });

  test('manda la última pasada: si salió limpia, deja de estar para repetir', () {
    final s = summarizeSession([
      run(ode, mistakes: 3, line: 1),
      run(ode, bpm: 74, tempo: 70),
      run(mary, mistakes: 1, line: 2, tempo: 60),
    ]);
    expect(s.runs, 3);
    expect(s.cleanRuns, 1);
    expect([for (final r in s.toRepeat) r.target.key], [mary.key]);
    expect(s.toRepeat.single.line, 2);
    expect(s.toRepeat.single.slowerBpm, 50);
    expect(s.cleanToday.single.target.key, ode.key);
    expect(s.cleanToday.single.bestBpm, 74);
  });

  test('si la última pasada falla, va a repetir aunque antes saliera limpia', () {
    final s = summarizeSession([
      run(spider, bpm: 100, tempo: 100),
      run(spider, mistakes: 1, line: 0, tempo: 110),
    ]);
    expect(s.cleanToday, isEmpty);
    expect(s.toRepeat.single.slowerBpm, 100);
  });

  test('limpio hoy da el mejor tempo; récords, el mayor de cada cosa', () {
    final s = summarizeSession([
      run(ode, bpm: 70, record: 70),
      run(ode, bpm: 86, record: 85),
      run(ode, bpm: 81),
    ]);
    expect(s.cleanToday.single.bestBpm, 86);
    expect(s.records, {ode.key: 85});
  });

  test('para repetir va en el orden en que se tocó por última vez', () {
    final s = summarizeSession([
      run(ode, mistakes: 1, line: 0),
      run(mary, mistakes: 1, line: 0),
      run(ode, mistakes: 2, line: 1),
    ]);
    expect([for (final r in s.toRepeat) r.target.key], [mary.key, ode.key]);
    expect(s.toRepeat.last.mistakes, 2);
  });
}
