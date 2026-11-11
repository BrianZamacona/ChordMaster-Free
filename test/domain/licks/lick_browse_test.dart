import 'package:chordmaster_free/domain/guides/guides.dart';
import 'package:chordmaster_free/domain/lessons/lesson.dart';
import 'package:chordmaster_free/domain/licks/lick.dart';
import 'package:chordmaster_free/domain/licks/lick_browse.dart';
import 'package:chordmaster_free/domain/licks/licks.dart';
import 'package:chordmaster_free/domain/practice/technique_exercises.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('▶ al 50 / 75 / 100 %: el tempo de la frase a esa fracción, de 5 en 5 y sin bajar de 40', () {
    for (final l in licks) {
      expect(lickTempoAt(l, 100), l.bpm, reason: l.id);
      for (final s in lickSpeeds) {
        final bpm = lickTempoAt(l, s);
        expect(bpm % techniqueBpmStep, 0, reason: '${l.id} $s');
        expect(bpm, greaterThanOrEqualTo(techniqueMinBpm), reason: '${l.id} $s');
        final raw = l.bpm * s / 100;
        if (raw < techniqueMinBpm) {
          expect(bpm, techniqueMinBpm, reason: '${l.id} $s');
        } else {
          expect((bpm - raw).abs(), lessThanOrEqualTo(techniqueBpmStep / 2), reason: '${l.id} $s');
        }
      }
      expect(lickSpeedOf(l, l.bpm), 100, reason: l.id);
    }
    final punk = licksById['punk_riff']!; // 120 BPM
    expect([for (final s in lickSpeeds) lickTempoAt(punk, s)], [60, 90, 120]);
    expect(lickSpeedOf(punk, 95), isNull);
  });

  test('anterior y siguiente: las del mismo estilo, en orden, sin salirse', () {
    for (final style in LickStyle.values) {
      final mine = [for (final l in licks) if (l.style == style) l];
      for (final (i, l) in mine.indexed) {
        final (:previous, :next) = lickNeighbors(l);
        expect(previous, i == 0 ? isNull : mine[i - 1], reason: l.id);
        expect(next, i == mine.length - 1 ? isNull : mine[i + 1], reason: l.id);
      }
    }
  });

  test('los filtros se combinan; sin ninguno, salen todas', () {
    expect(licks.where(const LickFilter().matches), hasLength(licks.length));
    const filter = LickFilter(
      level: GuideLevel.beginner,
      kind: LickKind.riff,
      scaleId: 'major',
      root: 4,
      technique: TabTechnique.palmMute,
    );
    final found = licks.where(filter.matches).toList();
    expect(found.map((l) => l.id), containsAll(['punk_riff', 'punk_power_riff']));
    for (final l in found) {
      expect((l.level, l.kind, l.scale.scaleId, l.scale.root), (GuideLevel.beginner, LickKind.riff, 'major', 4));
      expect(l.techniques, contains(TabTechnique.palmMute));
    }
    // Quitar un filtro con copyWith deja los demás.
    final wider = filter.copyWith(technique: () => null);
    expect(wider.technique, isNull);
    expect(wider.root, 4);
  });

  test('solo favoritas: deja las marcadas y se combina con los demás filtros', () {
    const favorites = {'punk_riff', 'stadium_lick'};
    const only = LickFilter(favoritesOnly: true);
    expect(licks.where((l) => only.matches(l, favorites: favorites)).map((l) => l.id).toSet(), favorites);
    expect(licks.where(only.matches), isEmpty);
    const riffs = LickFilter(favoritesOnly: true, kind: LickKind.riff);
    expect(licks.where((l) => riffs.matches(l, favorites: favorites)).map((l) => l.id), ['punk_riff']);
    expect(only.copyWith(favoritesOnly: false).favoritesOnly, isFalse);
  });

  test('los menús ofrecen solo lo que usa la biblioteca, sin repetir', () {
    expect(lickScaleIds.toSet(), {for (final l in licks) l.scale.scaleId});
    expect(lickScaleIds, hasLength(lickScaleIds.toSet().length));
    expect(lickRoots, [...{for (final l in licks) l.scale.root}]..sort());
    expect(lickTechniques.toSet(), {for (final l in licks) ...l.techniques});
    expect(lickTechniques, isNot(contains(TabTechnique.none)));
    // Cada opción deja al menos una frase.
    for (final id in lickScaleIds) {
      expect(licks.where(LickFilter(scaleId: id).matches), isNotEmpty, reason: id);
    }
    for (final r in lickRoots) {
      expect(licks.where(LickFilter(root: r).matches), isNotEmpty, reason: '$r');
    }
    for (final t in lickTechniques) {
      expect(licks.where(LickFilter(technique: t).matches), isNotEmpty, reason: '$t');
    }
  });
}
