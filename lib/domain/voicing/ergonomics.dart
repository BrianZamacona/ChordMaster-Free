import 'dart:math' as math;

import 'voicing_adapter.dart';

const standardOpenStringMidi = [64, 59, 55, 50, 45, 40];
const _maxFret = 24;
const _mutedIntermediateStringCost = 1.5;
const _registerBiasCost = 2.0;
const _optionalFifthCost = 3.0;

class Barre {
  const Barre({
    required this.fret,
    required this.fromString,
    required this.endString,
  });

  final int fret;
  final int fromString;
  final int endString;
}

class ErgonomicVoicing {
  const ErgonomicVoicing({
    required this.fretPositions,
    this.fingerPositions,
    this.barre,
  });

  final EngineFrets fretPositions;
  final List<int>? fingerPositions;
  final Barre? barre;
}

class ErgonomicOptions {
  const ErgonomicOptions({
    this.rootPitchClass,
    this.requiredIntervals,
    this.optionalIntervals,
    this.allowRootless = false,
    this.allowAdjacentUnisons = false,
    this.maxFingerCount,
  });

  final int? rootPitchClass;
  final List<int>? requiredIntervals;
  final List<int>? optionalIntervals;
  final bool allowRootless;
  final bool allowAdjacentUnisons;
  final int? maxFingerCount;
}

class _Pitch {
  const _Pitch(this.string, this.fret, this.midi);

  final int string;
  final int fret;
  final int midi;
}

int maxFretSpanForPosition(int lowestFret) {
  if (lowestFret <= 4) return 3;
  if (lowestFret <= 11) return 4;
  return 5;
}

List<_Pitch>? _soundingPitches(ErgonomicVoicing voicing) {
  if (voicing.fretPositions.length != standardOpenStringMidi.length) {
    return null;
  }
  final pitches = <_Pitch>[];
  for (var s = 0; s < voicing.fretPositions.length; s++) {
    final fret = voicing.fretPositions[s];
    if (fret == null) continue;
    if (fret < 0 || fret > _maxFret) return null;
    pitches.add(_Pitch(s, fret, standardOpenStringMidi[s] + fret));
  }
  return pitches.isEmpty ? null : pitches;
}

int _countUsedFingers(ErgonomicVoicing voicing, List<_Pitch> pitches) {
  final fingers = voicing.fingerPositions;
  if (fingers != null) return fingers.where((f) => f > 0).toSet().length;
  return pitches.where((p) => p.fret > 0).map((p) => p.fret).toSet().length;
}

bool _hasForbiddenAdjacentUnison(List<_Pitch> pitches) {
  final byString = {for (final p in pitches) p.string: p.midi};
  for (var s = 0; s < standardOpenStringMidi.length - 1; s++) {
    if (byString.containsKey(s) && byString[s] == byString[s + 1]) return true;
  }
  return false;
}

bool _hasRequiredIntervals(List<_Pitch> pitches, ErgonomicOptions options) {
  final required = options.requiredIntervals;
  if (required == null || required.isEmpty) return true;
  final rootPc = options.rootPitchClass;
  if (rootPc == null) return false;
  final root = rootPc % 12;
  final present = {for (final p in pitches) (p.midi % 12 - root + 12) % 12};
  return required
      .where((i) => !(options.allowRootless && i % 12 == 0))
      .every((i) => present.contains(i % 12));
}

int _mutedIntermediateStrings(
  ErgonomicVoicing voicing,
  List<_Pitch> pitches,
) {
  final lowest = pitches.map((p) => p.string).reduce(math.min);
  final highest = pitches.map((p) => p.string).reduce(math.max);
  var count = 0;
  for (var s = 0; s < voicing.fretPositions.length; s++) {
    if (s > lowest && s < highest && voicing.fretPositions[s] == null) count++;
  }
  return count;
}

double _barreDifficulty(ErgonomicVoicing voicing) {
  final barre = voicing.barre;
  if (barre == null) return 0;
  if (barre.fret < 1 ||
      barre.fret > _maxFret ||
      barre.fromString < 0 ||
      barre.fromString > 5 ||
      barre.endString < 0 ||
      barre.endString > 5) {
    return double.infinity;
  }
  final width = (barre.fromString - barre.endString).abs() + 1;
  return math.max(0, width - 2) * 0.75 + (barre.fret <= 2 ? 1 : 0);
}

double? _fretStretchCost(List<_Pitch> pitches) {
  final fretted = [
    for (final p in pitches)
      if (p.fret > 0) p.fret,
  ];
  if (fretted.isEmpty) return 0;
  final lowest = fretted.reduce(math.min);
  final span = fretted.reduce(math.max) - lowest;
  return span <= maxFretSpanForPosition(lowest) ? (span * span).toDouble() : null;
}

double _registerPreferenceCost(List<_Pitch> pitches) {
  var soprano = pitches.first;
  var bass = pitches.first;
  for (final p in pitches) {
    if (p.midi > soprano.midi) soprano = p;
    if (p.midi < bass.midi) bass = p;
  }
  return (soprano.string >= 3 ? _registerBiasCost : 0) +
      (bass.string <= 2 ? _registerBiasCost : 0);
}

double _optionalFifthPenalty(
  List<_Pitch> pitches,
  int fingerCount,
  ErgonomicOptions options,
) {
  final all = [...?options.requiredIntervals, ...?options.optionalIntervals];
  final chordToneCount = {for (final i in all) i % 12}.length;
  final hasOptionalFifth =
      options.optionalIntervals?.any((i) => i % 12 == 7) ?? false;
  final rootPc = options.rootPitchClass;
  if (chordToneCount < 5 ||
      !hasOptionalFifth ||
      fingerCount < (options.maxFingerCount ?? 4) ||
      rootPc == null) {
    return 0;
  }
  final root = rootPc % 12;
  return pitches.any((p) => (p.midi % 12 - root + 12) % 12 == 7)
      ? _optionalFifthCost
      : 0;
}

/// Devuelve `double.infinity` si viola una restricción física o armónica dura.
double calculateErgonomicCost(
  ErgonomicVoicing voicing, [
  ErgonomicOptions options = const ErgonomicOptions(),
]) {
  final pitches = _soundingPitches(voicing);
  if (pitches == null || !_hasRequiredIntervals(pitches, options)) {
    return double.infinity;
  }
  if (!options.allowAdjacentUnisons && _hasForbiddenAdjacentUnison(pitches)) {
    return double.infinity;
  }
  final stretch = _fretStretchCost(pitches);
  if (stretch == null) return double.infinity;
  final fingerCount = _countUsedFingers(voicing, pitches);
  if (fingerCount > (options.maxFingerCount ?? 4)) return double.infinity;
  return stretch +
      _mutedIntermediateStrings(voicing, pitches) *
          _mutedIntermediateStringCost +
      _barreDifficulty(voicing) +
      _registerPreferenceCost(pitches) +
      _optionalFifthPenalty(pitches, fingerCount, options);
}
