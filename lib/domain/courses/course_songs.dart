/// Canciones de dominio público para los cursos: solo sus acordes, un acorde
/// por compás (tradicionales, Foster, Newton), con su origen. Ningún curso
/// copia esta lista: la importa.
library;

import '../../core/i18n/tr.dart';

/// Una canción de dominio público: solo sus acordes, un acorde por compás.
class CourseSong {
  const CourseSong({
    required this.id,
    required this.title,
    required this.origin,
    required this.bars,
    this.beatsPerBar = 4,
  });

  final String id;
  final LocalizedText title;
  final LocalizedText origin;

  /// Un acorde por compás (`displayName` de `chords.json`).
  final List<String> bars;
  final int beatsPerBar;
}

const skipToMyLou = CourseSong(
  id: 'skip_to_my_lou',
  title: LocalizedText(es: 'Skip to My Lou', en: 'Skip to My Lou'),
  origin: LocalizedText(es: 'Tradicional (EE. UU., s. XIX)', en: 'Traditional (USA, 19th c.)'),
  bars: ['G', 'G', 'D', 'D', 'G', 'G', 'D', 'G'],
);

const tomDooley = CourseSong(
  id: 'tom_dooley',
  title: LocalizedText(es: 'Tom Dooley', en: 'Tom Dooley'),
  origin: LocalizedText(es: 'Tradicional (EE. UU., s. XIX)', en: 'Traditional (USA, 19th c.)'),
  bars: ['G', 'G', 'G', 'D', 'D', 'D', 'D', 'G'],
);

const drunkenSailor = CourseSong(
  id: 'drunken_sailor',
  title: LocalizedText(es: 'El marinero borracho', en: 'Drunken Sailor'),
  origin: LocalizedText(
    es: 'Tradicional (canción marinera, s. XIX)',
    en: 'Traditional (sea shanty, 19th c.)',
  ),
  bars: ['Em', 'Em', 'D', 'D', 'Em', 'Em', 'D', 'Em'],
);

const maryLamb = CourseSong(
  id: 'mary_lamb',
  title: LocalizedText(es: 'María tenía un corderito', en: 'Mary Had a Little Lamb'),
  origin: LocalizedText(es: 'Tradicional (EE. UU., 1830)', en: 'Traditional (USA, 1830)'),
  bars: ['C', 'C', 'G', 'C', 'C', 'C', 'G', 'C'],
);

const rowYourBoat = CourseSong(
  id: 'row_your_boat',
  title: LocalizedText(es: 'Rema, rema tu bote', en: 'Row, Row, Row Your Boat'),
  origin: LocalizedText(es: 'Tradicional (EE. UU., 1852)', en: 'Traditional (USA, 1852)'),
  bars: ['C', 'C', 'C', 'C', 'C', 'C', 'G', 'C'],
);

const ohSusanna = CourseSong(
  id: 'oh_susanna',
  title: LocalizedText(es: 'Oh! Susanna', en: 'Oh! Susanna'),
  origin: LocalizedText(es: 'Stephen Foster, 1848', en: 'Stephen Foster, 1848'),
  bars: [
    'G', 'G', 'G', 'D', 'G', 'G', 'D', 'G', //
    'C', 'C', 'G', 'D', 'G', 'G', 'D', 'G',
  ],
);

const saints = CourseSong(
  id: 'saints',
  title: LocalizedText(es: 'When the Saints Go Marching In', en: 'When the Saints Go Marching In'),
  origin: LocalizedText(es: 'Tradicional (EE. UU.)', en: 'Traditional (USA)'),
  bars: [
    'G', 'G', 'G', 'G', 'G', 'G', 'D', 'D', //
    'G', 'G', 'C', 'C', 'G', 'D', 'G', 'G',
  ],
);

const amazingGrace = CourseSong(
  id: 'amazing_grace',
  title: LocalizedText(es: 'Amazing Grace', en: 'Amazing Grace'),
  origin: LocalizedText(
    es: 'John Newton, 1779 (melodía tradicional)',
    en: 'John Newton, 1779 (traditional tune)',
  ),
  bars: [
    'G', 'G', 'C', 'G', 'G', 'G', 'D', 'D', //
    'G', 'G', 'C', 'G', 'G', 'D', 'G', 'G',
  ],
  beatsPerBar: 3,
);
