import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/progressions/progression_builder.dart';
import '../../models/chord.dart';

final chordRepositoryProvider =
    Provider<ChordRepository>((ref) => ChordRepository());

/// Única puerta a `assets/data/chords.json` (824 KB): lo lee y decodifica una
/// sola vez, fuera del hilo de la UI, y da sus dos vistas: [Chord] para la
/// biblioteca y [ChordFingerings] para el motor de progresiones.
class ChordRepository {
  ChordRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/chords.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  Future<List<Map<String, dynamic>>>? _entries;
  Future<List<Chord>>? _chords;
  Future<List<ChordFingerings>>? _fingerings;

  /// Los 288 acordes en el orden del archivo.
  Future<List<Chord>> chords() => _chords ??= _load().then(
        (entries) => List.unmodifiable(entries.map(Chord.fromJson)),
      );

  /// Las digitaciones de cada acorde para [ProgressionBuilder].
  Future<List<ChordFingerings>> fingerings() => _fingerings ??= _load().then(
        (entries) => List.unmodifiable(entries.map(ChordFingerings.fromJson)),
      );

  Future<List<Map<String, dynamic>>> _load() => _entries ??= () async {
        final raw = await _bundle.loadString(assetPath, cache: false);
        return compute(_decode, raw);
      }();
}

List<Map<String, dynamic>> _decode(String raw) =>
    (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
