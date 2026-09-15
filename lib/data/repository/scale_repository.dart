import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_coordinate.dart';
import '../models/scale_definition.dart';

final scaleRepositoryProvider = Provider<ScaleRepository>((ref) => ScaleRepository());

final allScalesProvider = FutureProvider<List<ScaleDefinition>>(
  (ref) => ref.read(scaleRepositoryProvider).getAllScales(),
);

final allModesProvider = FutureProvider<List<ScaleDefinition>>(
  (ref) => ref.read(scaleRepositoryProvider).getAllModes(),
);

class ResolvedPattern {
  const ResolvedPattern({
    required this.scaleId,
    required this.scaleName,
    required this.systemId,
    required this.systemName,
    required this.positionId,
    required this.positionName,
    required this.startingFret,
    required this.endFret,
    required this.coordinates,
  });

  final String scaleId;
  final String scaleName;
  final String systemId;
  final String systemName;
  final String positionId;
  final String positionName;
  final int startingFret;
  final int endFret;
  final List<NoteCoordinate> coordinates;

  int get fretSpan => (endFret - startingFret) + 1;
}

class ScaleRepository {
  ScaleRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/scales_master.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  List<ScaleDefinition>? _scales;
  List<ScaleDefinition>? _modes;

  Future<List<ScaleDefinition>> getAllScales() async {
    await _ensureLoaded();
    return _scales!;
  }

  Future<List<ScaleDefinition>> getAllModes() async {
    await _ensureLoaded();
    return _modes!;
  }

  Future<List<ResolvedPattern>> getVisiblePatterns({
    required String scaleId,
    required int rootSemitone,
    required int startFret,
    required int endFret,
    required int stringCount,
    String? systemFilter,
  }) async {
    await _ensureLoaded();
    final all = [..._scales!, ..._modes!];
    ScaleDefinition? scale;
    for (final candidate in all) {
      if (candidate.id == scaleId) {
        scale = candidate;
        break;
      }
    }
    if (scale == null) return const [];

    final systemsById = {for (final s in scale.systems) s.id: s};
    final result = <ResolvedPattern>[];

    for (final p in scale.positions) {
      if (systemFilter != null && p.systemId != systemFilter) continue;
      final coords = p
          .resolveCoordinates(rootSemitone)
          .where((c) => c.string >= 1 && c.string <= stringCount)
          .where((c) => c.fret >= startFret && c.fret <= endFret)
          .toList(growable: false);
      if (coords.isEmpty) continue;

      final minFret = coords.map((c) => c.fret).reduce((a, b) => a < b ? a : b);
      final maxFret = coords.map((c) => c.fret).reduce((a, b) => a > b ? a : b);

      final resolvedStart = minFret < startFret ? startFret : minFret;
      final resolvedEnd = maxFret > endFret ? endFret : maxFret;
      result.add(
        ResolvedPattern(
          scaleId: scale.id,
          scaleName: scale.name,
          systemId: p.systemId,
          systemName: systemsById[p.systemId]?.name ?? p.systemId,
          positionId: p.id,
          positionName: p.name,
          startingFret: resolvedStart,
          endFret: resolvedEnd,
          coordinates: coords,
        ),
      );
    }

    result.sort((a, b) => a.startingFret.compareTo(b.startingFret));
    return result;
  }

  Future<void> _ensureLoaded() async {
    if (_scales != null && _modes != null) return;
    final raw = await _bundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;

    _scales = (decoded['scales'] as List<dynamic>? ?? const [])
        .map((e) => ScaleDefinition.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _modes = (decoded['modes'] as List<dynamic>? ?? const [])
        .map((e) => ScaleDefinition.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
