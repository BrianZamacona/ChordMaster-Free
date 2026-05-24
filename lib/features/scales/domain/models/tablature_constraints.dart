/// Algorithmic constraints for scale/arpeggio/chord tab generation.
class TablatureConstraints {
  const TablatureConstraints({
    this.minNotesPerString = 1,
    this.maxNotesPerString = 3,
    this.maxSpanPerString = 4,
    this.allowedStringSets = const [],
    this.minFret = 0,
    this.maxFret = 22,
    this.includeOpenStrings = true,
    this.allowOctaveWrap = true,
    this.maxSemitoneJump = 7,
  });

  final int minNotesPerString;
  final int maxNotesPerString;
  final int maxSpanPerString;
  final List<List<int>> allowedStringSets;
  final int minFret;
  final int maxFret;
  final bool includeOpenStrings;
  final bool allowOctaveWrap;
  final int maxSemitoneJump;

  TablatureConstraints copyWith({
    int? minNotesPerString,
    int? maxNotesPerString,
    int? maxSpanPerString,
    List<List<int>>? allowedStringSets,
    int? minFret,
    int? maxFret,
    bool? includeOpenStrings,
    bool? allowOctaveWrap,
    int? maxSemitoneJump,
  }) =>
      TablatureConstraints(
        minNotesPerString: minNotesPerString ?? this.minNotesPerString,
        maxNotesPerString: maxNotesPerString ?? this.maxNotesPerString,
        maxSpanPerString: maxSpanPerString ?? this.maxSpanPerString,
        allowedStringSets: allowedStringSets ?? this.allowedStringSets,
        minFret: minFret ?? this.minFret,
        maxFret: maxFret ?? this.maxFret,
        includeOpenStrings: includeOpenStrings ?? this.includeOpenStrings,
        allowOctaveWrap: allowOctaveWrap ?? this.allowOctaveWrap,
        maxSemitoneJump: maxSemitoneJump ?? this.maxSemitoneJump,
      );
}
