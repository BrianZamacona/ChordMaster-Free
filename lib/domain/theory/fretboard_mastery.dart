/// Lo que se domina del mástil (inspirado en el repaso y el mapa de
/// FretMaster, por reglas): por cada lugar, cuántas veces se respondió y
/// cuántos aciertos seguidos lleva. De ahí salen los lugares que cuestan
/// (para el repaso) y el mapa.
library;

import 'fretboard_quiz.dart';

/// Cómo va un lugar del mástil.
enum SpotMastery {
  /// Nunca se respondió.
  unexplored,

  /// La última respuesta fue un error: vuelve en el repaso.
  weak,

  /// Acertado, pero menos de [masteredStreak] veces seguidas.
  learning,

  /// [masteredStreak] aciertos seguidos o más.
  mastered,
}

/// Aciertos seguidos para dar un lugar por dominado.
const masteredStreak = 3;

/// Lo respondido en un lugar.
typedef SpotRecord = ({int answered, int streak});

/// El registro de todo el mástil. Inmutable: [record] da uno nuevo.
class FretMastery {
  const FretMastery([this.spots = const {}]);

  /// Lo leído del disco (`{"cuerda:traste": [respondidas, racha]}`); lo que
  /// no se entiende se descarta.
  factory FretMastery.fromJson(Object? json) {
    if (json is! Map) return const FretMastery();
    final spots = <FretSpot, SpotRecord>{};
    for (final MapEntry(:key, :value) in json.entries) {
      final spot = _parse(key);
      if (spot == null || value is! List || value.length != 2) continue;
      final [answered, streak] = value;
      if (answered is! int || streak is! int || answered < 1 || streak < 0 || streak > answered) continue;
      spots[spot] = (answered: answered, streak: streak);
    }
    return FretMastery(spots);
  }

  final Map<FretSpot, SpotRecord> spots;

  static FretSpot? _parse(Object? key) {
    if (key is! String) return null;
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final string = int.tryParse(parts[0]);
    final fret = int.tryParse(parts[1]);
    if (string == null || fret == null || string < 1 || string > 6 || fret < 0 || fret > fretQuizMaxFret) {
      return null;
    }
    return (string: string, fret: fret);
  }

  /// Con la respuesta a [spot]: un acierto suma a la racha, un error la
  /// vuelve a 0.
  FretMastery record(FretSpot spot, {required bool right}) {
    final old = spots[spot];
    return FretMastery({
      ...spots,
      spot: (answered: (old?.answered ?? 0) + 1, streak: right ? (old?.streak ?? 0) + 1 : 0),
    });
  }

  SpotMastery of(FretSpot spot) {
    final r = spots[spot];
    if (r == null) return SpotMastery.unexplored;
    if (r.streak == 0) return SpotMastery.weak;
    return r.streak >= masteredStreak ? SpotMastery.mastered : SpotMastery.learning;
  }

  /// Los lugares con la última respuesta equivocada.
  Set<FretSpot> get weak => {
    for (final MapEntry(:key, :value) in spots.entries)
      if (value.streak == 0) key,
  };

  /// Los lugares de [level], de los trastes 0 a 12.
  Set<FretSpot> spotsAt(SpotMastery level) => {
    for (var string = 1; string <= 6; string++)
      for (var fret = 0; fret <= fretQuizMaxFret; fret++)
        if (of((string: string, fret: fret)) == level) (string: string, fret: fret),
  };

  Map<String, List<int>> toJson() => {
    for (final MapEntry(:key, :value) in spots.entries) '${key.string}:${key.fret}': [value.answered, value.streak],
  };
}
