/// Familias de tipos de acorde, para agrupar los filtros y explicar el
/// vocabulario: cuántas notas tiene el acorde y qué añade a la tríada.
enum ChordFamily {
  /// Tres sonidos (o dos, en el power chord): mayor, menor, dim, aum, sus.
  triads,

  /// Tríada + 6ª o 7ª.
  sixthsAndSevenths,

  /// Séptima o sexta + 9ª, 11ª o 13ª.
  extended,

  /// Dominantes y mayores con tensiones alteradas (♭9, ♯9, ♯11).
  altered,
}

/// Familia de cada `type` de chords.json. Cada tipo está en exactamente una.
const chordFamilyByType = <String, ChordFamily>{
  'major': ChordFamily.triads,
  'minor': ChordFamily.triads,
  'diminished': ChordFamily.triads,
  'augmented': ChordFamily.triads,
  'sus2': ChordFamily.triads,
  'sus4': ChordFamily.triads,
  'power5': ChordFamily.triads,
  'sixth': ChordFamily.sixthsAndSevenths,
  'minor6': ChordFamily.sixthsAndSevenths,
  'dominant7': ChordFamily.sixthsAndSevenths,
  'major7': ChordFamily.sixthsAndSevenths,
  'minor7': ChordFamily.sixthsAndSevenths,
  'halfDiminished': ChordFamily.sixthsAndSevenths,
  'diminished7': ChordFamily.sixthsAndSevenths,
  'add9': ChordFamily.extended,
  'sixth9': ChordFamily.extended,
  'dominant9': ChordFamily.extended,
  'major9': ChordFamily.extended,
  'minor9': ChordFamily.extended,
  'minor11': ChordFamily.extended,
  'thirteenth': ChordFamily.extended,
  'major7Sharp11': ChordFamily.altered,
  'dominant7Flat9': ChordFamily.altered,
  'dominant7Sharp9': ChordFamily.altered,
};
