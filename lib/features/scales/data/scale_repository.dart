import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/scale_pattern.dart';

/// Provider for loading strict-coordinate scale patterns from local assets.
final scaleRepositoryProvider = Provider<ScaleRepository>((ref) {
  ref.keepAlive();
  return ScaleRepository();
});

/// Reads scale diagram patterns from static JSON assets.
class ScaleRepository {
  /// Creates repository with [AssetBundle] and JSON [assetPath].
  ScaleRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/scale_patterns_coordinates.json',
  }) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;
  final String assetPath;

  /// Loads and parses all strict-coordinate [ScalePattern] entries.
  Future<List<ScalePattern>> loadScalePatterns() async {
    final rawJson = await bundle.loadString(assetPath);
    final decoded = json.decode(rawJson);

    final List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['patterns'] is List) {
      rawList = decoded['patterns'] as List<dynamic>;
    } else {
      throw const FormatException(
        'Expected a JSON array or object with "patterns" array',
      );
    }

    return rawList.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Pattern entry must be a JSON object');
      }
      return ScalePattern.fromJson(Map<String, dynamic>.from(entry));
    }).toList(growable: false);
  }
}
