import 'ergonomics.dart';
import 'voicing_adapter.dart';

class VoiceLeadingVoicing extends ErgonomicVoicing {
  const VoiceLeadingVoicing({
    required super.fretPositions,
    required this.anchorFret,
    this.individualCost,
    super.fingerPositions,
    super.barre,
  });

  final int anchorFret;
  final double? individualCost;
}

class VoicePitch {
  const VoicePitch(this.stringIndex, this.fret, this.midi);

  final int stringIndex;
  final int fret;
  final int midi;
}

class VoiceExtremes {
  const VoiceExtremes({this.bass, this.soprano});

  final VoicePitch? bass;
  final VoicePitch? soprano;
}

class VoiceLeadingCostOptions {
  const VoiceLeadingCostOptions({
    this.fretShiftWeight,
    this.retainedNoteBonus,
  });

  final double? fretShiftWeight;
  final double? retainedNoteBonus;
}

class ProgressionPathOptions extends VoiceLeadingCostOptions {
  const ProgressionPathOptions({
    super.fretShiftWeight,
    super.retainedNoteBonus,
    this.voicingCost,
  });

  final double? Function(VoiceLeadingVoicing voicing)? voicingCost;
}

List<VoicePitch> voicingPitches(EngineFrets fretPositions) {
  if (fretPositions.length != standardOpenStringMidi.length) return [];
  return [
    for (var s = 0; s < fretPositions.length; s++)
      if (fretPositions[s] != null)
        VoicePitch(s, fretPositions[s]!, standardOpenStringMidi[s] + fretPositions[s]!),
  ];
}

VoiceExtremes identifySopranoAndBass(EngineFrets fretPositions) {
  final pitches = voicingPitches(fretPositions);
  if (pitches.isEmpty) return const VoiceExtremes();
  var bass = pitches.first;
  var soprano = pitches.first;
  for (final p in pitches) {
    if (p.midi < bass.midi) bass = p;
    if (p.midi > soprano.midi) soprano = p;
  }
  return VoiceExtremes(bass: bass, soprano: soprano);
}

int retainedPositionCount(VoiceLeadingVoicing previous, VoiceLeadingVoicing next) {
  var count = 0;
  for (var s = 0; s < previous.fretPositions.length; s++) {
    final fret = previous.fretPositions[s];
    if (fret == null) continue;
    if (s < next.fretPositions.length && fret == next.fretPositions[s]) count++;
  }
  return count;
}

double calculateVoiceLeadingCost(
  VoiceLeadingVoicing previous,
  VoiceLeadingVoicing next, [
  VoiceLeadingCostOptions options = const VoiceLeadingCostOptions(),
]) {
  final previousSoprano = identifySopranoAndBass(previous.fretPositions).soprano;
  final nextSoprano = identifySopranoAndBass(next.fretPositions).soprano;
  if (previousSoprano == null || nextSoprano == null) return double.infinity;
  final leap = nextSoprano.midi - previousSoprano.midi;
  final shiftWeight = options.fretShiftWeight ?? 2;
  final retainedBonus = options.retainedNoteBonus ?? 1.5;
  final sopranoCost = (leap * leap).toDouble();
  final fretShiftCost = (next.anchorFret - previous.anchorFret).abs() * shiftWeight;
  final retainedCost = retainedPositionCount(previous, next) * retainedBonus;
  final total = sopranoCost + fretShiftCost - retainedCost;
  return total > 0 ? total : 0;
}

double _localCost(VoiceLeadingVoicing voicing, ProgressionPathOptions options) =>
    options.voicingCost?.call(voicing) ??
    voicing.individualCost ??
    calculateErgonomicCost(voicing);

/// Camino de costo mínimo por capas; vacío si alguna capa no tiene candidatos
/// o no hay camino finito. Desempata por el primer índice con costo estrictamente menor.
List<T> findOptimalProgressionPath<T extends VoiceLeadingVoicing>(
  List<List<T>> candidateLayers, [
  ProgressionPathOptions options = const ProgressionPathOptions(),
]) {
  if (candidateLayers.isEmpty || candidateLayers.any((l) => l.isEmpty)) {
    return [];
  }

  final costLayers = <List<double>>[
    [for (final v in candidateLayers.first) _localCost(v, options)],
  ];
  final predecessorLayers = <List<int>>[
    [for (final _ in candidateLayers.first) -1],
  ];

  for (var layer = 1; layer < candidateLayers.length; layer++) {
    final previousCandidates = candidateLayers[layer - 1];
    final currentCandidates = candidateLayers[layer];
    final previousCosts = costLayers[layer - 1];
    final currentCosts = List<double>.filled(currentCandidates.length, double.infinity);
    final predecessors = List<int>.filled(currentCandidates.length, -1);

    for (var c = 0; c < currentCandidates.length; c++) {
      final noteCost = _localCost(currentCandidates[c], options);
      if (!noteCost.isFinite) continue;
      for (var p = 0; p < previousCandidates.length; p++) {
        if (!previousCosts[p].isFinite) continue;
        final transition = calculateVoiceLeadingCost(
          previousCandidates[p],
          currentCandidates[c],
          options,
        );
        final total = previousCosts[p] + transition + noteCost;
        if (total < currentCosts[c]) {
          currentCosts[c] = total;
          predecessors[c] = p;
        }
      }
    }
    costLayers.add(currentCosts);
    predecessorLayers.add(predecessors);
  }

  final finalCosts = costLayers.last;
  var best = -1;
  for (var i = 0; i < finalCosts.length; i++) {
    if (finalCosts[i].isFinite && (best < 0 || finalCosts[i] < finalCosts[best])) {
      best = i;
    }
  }
  if (best < 0) return [];

  final path = <T>[];
  for (var layer = candidateLayers.length - 1; layer >= 0; layer--) {
    path.add(candidateLayers[layer][best]);
    best = predecessorLayers[layer][best];
  }
  return path.reversed.toList();
}
