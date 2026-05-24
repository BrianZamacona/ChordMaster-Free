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
    final chordMask = _maskFromIntervals(chordIntervals);
    if (chordMask == 0) return const ReverseHarmonizationResult();

    final allScales = <String, List<int>>{
      ...TheoryCatalog.scaleFormulas,
      ...TheoryCatalog.modeFormulas,
      ...TheoryCatalog.exoticScales,
    };

    final strict = <String>[];
    final tolerant = <({String name, int sharedCount})>[];
    final chordToneCount = _bitCount(chordMask);

    for (final entry in allScales.entries) {
      final scaleMask = _maskFromIntervals(entry.value);
      final intersection = scaleMask & chordMask;
      if (intersection == 0) continue;

      final sharedCount = _bitCount(intersection);
      final isStrict = intersection == chordMask;
      if (isStrict) {
        strict.add(entry.key);
        continue;
      }

      final minimumShared = chordToneCount <= 3 ? 2 : chordToneCount - 1;
      if (sharedCount >= minimumShared) {
        tolerant.add((name: entry.key, sharedCount: sharedCount));
      }
    }

    strict.sort();
    tolerant.sort((a, b) {
      final byShared = b.sharedCount.compareTo(a.sharedCount);
      if (byShared != 0) return byShared;
      return a.name.compareTo(b.name);
    });

    return ReverseHarmonizationResult(
      strictMatches: strict,
      tolerantMatches: tolerant.map((e) => e.name).toList(growable: false),
    );
  }

  static int _maskFromIntervals(Iterable<int> intervals) {
    var mask = 0;
    for (final interval in intervals) {
      final normalized = ((interval % 12) + 12) % 12;
      mask |= (1 << normalized);
    }
    return mask;
  }

  static int _bitCount(int value) {
    var n = value;
    var count = 0;
    while (n != 0) {
      n &= (n - 1);
      count++;
    }
    return count;
  }
}
