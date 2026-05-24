import '../../../../core/constants/theory_catalog.dart';

/// Reverse harmonization result for a chord -> candidate scales lookup.
class ReverseHarmonizationResult {
  const ReverseHarmonizationResult({
    this.strictMatches = const [],
    this.tolerantMatches = const [],
  });

  final List<String> strictMatches;
  final List<String> tolerantMatches;
}

/// Reverse harmonization: chord intervals -> matching scale families.
class ReverseHarmonizationService {
  const ReverseHarmonizationService();

  ReverseHarmonizationResult matchScalesForChord(List<int> chordIntervals) {
    if (chordIntervals.isEmpty) return const ReverseHarmonizationResult();
    final normalizedChord = chordIntervals.map((i) => i % 12).toSet();

    final allScales = <String, List<int>>{
      ...TheoryCatalog.scaleFormulas,
      ...TheoryCatalog.modeFormulas,
      ...TheoryCatalog.exoticScales,
    };

    final strict = <String>[];
    final tolerant = <String>[];

    for (final entry in allScales.entries) {
      final scaleSet = entry.value.map((i) => i % 12).toSet();
      if (scaleSet.containsAll(normalizedChord)) {
        tolerant.add(entry.key);
        if (normalizedChord.every(scaleSet.contains)) {
          strict.add(entry.key);
        }
      }
    }

    return ReverseHarmonizationResult(
      strictMatches: strict..sort(),
      tolerantMatches: tolerant..sort(),
    );
  }
}
