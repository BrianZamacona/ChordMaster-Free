import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/scale_pattern.dart';
import 'scale_pattern_generator.dart';

@Deprecated(
  'Legacy pipeline kept for backward compatibility/tests. Prefer domain engines '
  'via scales_engine_providers.dart.',
)
final scaleRepositoryProvider = Provider<ScaleRepository>((ref) {
  ref.keepAlive();
  return ScaleRepository();
});

@Deprecated(
  'Legacy pipeline kept for backward compatibility/tests. Prefer domain engines '
  'via scales_engine_providers.dart.',
)
class ScaleRepository {
  ScaleRepository({
    AssetBundle? bundle,
    this.scalesAssetPath = 'assets/data/scales.json',
  }) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;
  final String scalesAssetPath;
  List<_ScaleTheory>? _cache;

  Future<List<ScalePattern>> loadPatterns({
    required String scaleName,
    required String root,
    required String system,
    int userStartFret = 0,
    int userEndFret = 12,
  }) async {
    final theory = await _find(scaleName, root);
    if (theory == null) return [];
    return _generate(theory: theory, system: system,
        userStartFret: userStartFret, userEndFret: userEndFret);
  }

  Future<Map<String, List<ScalePattern>>> loadAllSystems({
    required String scaleName,
    required String root,
    int userStartFret = 0,
    int userEndFret = 12,
  }) async {
    final theory = await _find(scaleName, root);
    if (theory == null) return {};
    return ScalePatternGenerator.allSystems(
      scaleName: theory.name, root: theory.root, intervals: theory.intervals,
      userStartFret: userStartFret, userEndFret: userEndFret,
    );
  }

  Future<ScalePattern?> loadPositional({
    required String scaleName,
    required String root,
    required int startFret,
    int fretsSpan = 4,
  }) async {
    final theory = await _find(scaleName, root);
    if (theory == null) return null;
    return ScalePatternGenerator.positional(
      scaleName: theory.name, root: theory.root,
      intervals: theory.intervals, startFret: startFret, fretsSpan: fretsSpan,
    );
  }

  Future<_ScaleTheory?> _find(String scaleName, String root) async {
    final scales = await _loadAll();
    try {
      return scales.firstWhere((s) =>
          s.root == root &&
          (s.name.toLowerCase().contains(scaleName.toLowerCase()) ||
           s.type.toLowerCase() == scaleName.toLowerCase()));
    } catch (_) { return null; }
  }

  Future<List<_ScaleTheory>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await bundle.loadString(scalesAssetPath);
    final list = json.decode(raw) as List<dynamic>;
    _cache = list.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _ScaleTheory(
        name: m['name'] as String,
        root: m['root'] as String,
        type: m['type'] as String,
        intervals: List<int>.from((m['intervals'] as List).map((x) => (x as num).toInt())),
      );
    }).toList();
    return _cache!;
  }

  List<ScalePattern> _generate({
    required _ScaleTheory theory,
    required String system,
    required int userStartFret,
    required int userEndFret,
  }) {
    switch (system) {
      case 'CAGED':
        return ScalePatternGenerator.caged(
            scaleName: theory.name, root: theory.root, intervals: theory.intervals);
      case '3NPS':
        return List.generate(theory.intervals.length.clamp(5, 7), (i) =>
            ScalePatternGenerator.threeNps(
                scaleName: theory.name, root: theory.root,
                intervals: theory.intervals, startFret: i * 2));
      case '4NPS':
        return List.generate(theory.intervals.length.clamp(4, 6), (i) =>
            ScalePatternGenerator.fourNps(
                scaleName: theory.name, root: theory.root,
                intervals: theory.intervals, startFret: i * 3));
      case '7 Patrones':
        return ScalePatternGenerator.sevenPatterns(
            scaleName: theory.name, root: theory.root, intervals: theory.intervals);
      case 'Pentatónica':
        return ScalePatternGenerator.pentatonicBoxes(
            scaleName: theory.name, root: theory.root, intervals: theory.intervals);
      case 'Berklee':
        return ScalePatternGenerator.berklee(
            scaleName: theory.name, root: theory.root, intervals: theory.intervals);
      case 'Mástil completo':
        return [ScalePatternGenerator.fullNeck(
            scaleName: theory.name, root: theory.root, intervals: theory.intervals,
            fromFret: userStartFret, toFret: userEndFret)];
      default:
        return [ScalePatternGenerator.positional(
            scaleName: theory.name, root: theory.root, intervals: theory.intervals,
            startFret: userStartFret, fretsSpan: userEndFret - userStartFret)];
    }
  }
}

class _ScaleTheory {
  const _ScaleTheory({required this.name, required this.root,
      required this.type, required this.intervals});
  final String name;
  final String root;
  final String type;
  final List<int> intervals;
}
