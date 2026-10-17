import 'dart:convert';
import 'dart:io';

import 'package:chordmaster_free/domain/voicing/ergonomics.dart';
import 'package:chordmaster_free/domain/voicing/voice_leading.dart';

Object? loadGolden(String name) =>
    jsonDecode(File('test/fixtures/golden/$name.json').readAsStringSync());

/// En el golden la cuerda muteada es "x"; en Dart es null.
List<int?> decodeFrets(List<dynamic> raw) => [
  for (final f in raw)
    if (f == 'x') null else f as int,
];

List<int>? _ints(Object? raw) =>
    raw == null ? null : (raw as List<dynamic>).cast<int>();

ErgonomicVoicing decodeVoicing(Map<String, dynamic> json) {
  final barre = json['barre'] as Map<String, dynamic>?;
  return ErgonomicVoicing(
    fretPositions: decodeFrets(json['fretPositions'] as List<dynamic>),
    fingerPositions: _ints(json['fingerPositions']),
    barre: barre == null
        ? null
        : Barre(
            fret: barre['fret'] as int,
            fromString: barre['fromString'] as int,
            endString: barre['toString'] as int,
          ),
  );
}

VoiceLeadingVoicing decodeVoiceLeadingVoicing(Map<String, dynamic> json) {
  final base = decodeVoicing(json);
  return VoiceLeadingVoicing(
    fretPositions: base.fretPositions,
    fingerPositions: base.fingerPositions,
    barre: base.barre,
    anchorFret: json['anchorFret'] as int,
    individualCost: (json['individualCost'] as num?)?.toDouble(),
  );
}

ErgonomicOptions decodeErgonomicOptions(Map<String, dynamic> json) =>
    ErgonomicOptions(
      rootPitchClass: json['rootPitchClass'] as int?,
      requiredIntervals: _ints(json['requiredIntervals']),
      optionalIntervals: _ints(json['optionalIntervals']),
      allowRootless: json['allowRootless'] as bool? ?? false,
      allowAdjacentUnisons: json['allowAdjacentUnisons'] as bool? ?? false,
      maxFingerCount: json['maxFingerCount'] as int?,
    );

VoiceLeadingCostOptions decodeVoiceLeadingOptions(Map<String, dynamic> json) =>
    VoiceLeadingCostOptions(
      fretShiftWeight: (json['fretShiftWeight'] as num?)?.toDouble(),
      retainedNoteBonus: (json['retainedNoteBonus'] as num?)?.toDouble(),
    );

/// `null` en el golden significa Infinity.
double decodeCost(Object? raw) =>
    raw == null ? double.infinity : (raw as num).toDouble();
