/// Afinaciones de la guitarra (decisión del usuario, 2026-11-16: para Licks y
/// riffs). Cada una es la altura MIDI de cada cuerda al aire, de la 1ª (mi
/// aguda en la estándar) a la 6ª; la estándar es [standardOpenStringMidi], la
/// única tabla de la afinación de siempre.
library;

import '../../core/i18n/tr.dart';
import 'notes.dart';

enum GuitarTuning {
  /// E A D G B E.
  standard(standardOpenStringMidi),

  /// D A D G B E: la 6ª un tono abajo; un power chord se toca con un dedo.
  dropD([64, 59, 55, 50, 45, 38]),

  /// D# G# C# F# A# D# (Eb Ab Db Gb Bb Eb): todas medio tono abajo.
  halfStepDown([63, 58, 54, 49, 44, 39]),

  /// D G D G B D: un acorde de G mayor al aire.
  openG([62, 59, 55, 50, 43, 38]),

  /// D A D G A D: Dsus4 al aire, el del folk celta.
  dadgad([62, 57, 55, 50, 45, 38]);

  const GuitarTuning(this.openMidi);

  /// MIDI de cada cuerda al aire, de la 1ª a la 6ª.
  final List<int> openMidi;

  /// Las cuerdas al aire de la 6ª a la 1ª, como se dicen: «D A D G B E».
  String get notes => [for (final m in openMidi.reversed) pitchClassName(m)].join(' ');

  LocalizedText get name => switch (this) {
    GuitarTuning.standard => const LocalizedText(es: 'Estándar', en: 'Standard'),
    GuitarTuning.dropD => const LocalizedText(es: 'Drop D', en: 'Drop D'),
    GuitarTuning.halfStepDown => const LocalizedText(es: 'Medio tono abajo', en: 'Half step down'),
    GuitarTuning.openG => const LocalizedText(es: 'Open G', en: 'Open G'),
    GuitarTuning.dadgad => const LocalizedText(es: 'DADGAD', en: 'DADGAD'),
  };

  /// Cómo se llega desde la estándar (un test lo compara con [openMidi]).
  LocalizedText get howTo => switch (this) {
    GuitarTuning.standard => const LocalizedText(es: '', en: ''),
    GuitarTuning.dropD => const LocalizedText(
      es: 'Baja la 6ª un tono, a D.',
      en: 'Lower the 6th string a whole step, to D.',
    ),
    GuitarTuning.halfStepDown => const LocalizedText(
      es: 'Baja todas las cuerdas medio tono.',
      en: 'Lower every string a half step.',
    ),
    GuitarTuning.openG => const LocalizedText(
      es: 'Baja la 6ª, la 5ª y la 1ª un tono: a D, G y D.',
      en: 'Lower the 6th, 5th and 1st strings a whole step: to D, G and D.',
    ),
    GuitarTuning.dadgad => const LocalizedText(
      es: 'Baja la 6ª, la 2ª y la 1ª un tono: a D, A y D.',
      en: 'Lower the 6th, 2nd and 1st strings a whole step: to D, A and D.',
    ),
  };
}
