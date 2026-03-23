import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/scale.dart';

/// Category constants for scale grouping.
class ScaleCategory {
  ScaleCategory._();
  static const String scales = 'Scales';
  static const String modes = 'Modes';
  static const String exotic = 'Exotic';
  static const List<String> all = [scales, modes, exotic];

  /// Scale types that belong to the Modes category.
  static const _modeTypes = {
    'ionian', 'dorian', 'phrygian', 'lydian',
    'mixolydian', 'aeolian', 'locrian',
  };

  /// Scale types that belong to the Exotic category.
  static const _exoticTypes = {
    'hungarianMinor', 'phrygianDominant', 'doubleHarmonic', 'neapolitan',
  };

  /// Returns the display category for a given scale [type] key.
  static String fromType(String type) {
    if (_modeTypes.contains(type)) return modes;
    if (_exoticTypes.contains(type)) return exotic;
    return scales;
  }
}

/// Immutable state for [ScalesViewModel].
class ScalesState {
  /// All scales loaded from the asset bundle.
  final List<Scale> allScales;

  /// Scales filtered by root and category.
  final List<Scale> filteredScales;

  /// Currently selected root note (defaults to 'C').
  final String selectedRoot;

  /// Currently selected category tab.
  final String selectedCategory;

  /// Currently selected (highlighted) scale.
  final Scale? selectedScale;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Non-null error message if the last operation failed.
  final String? errorMessage;

  const ScalesState({
    this.allScales = const [],
    this.filteredScales = const [],
    this.selectedRoot = 'C',
    this.selectedCategory = ScaleCategory.scales,
    this.selectedScale,
    this.isLoading = true,
    this.errorMessage,
  });

  ScalesState copyWith({
    List<Scale>? allScales,
    List<Scale>? filteredScales,
    String? selectedRoot,
    String? selectedCategory,
    Object? selectedScale = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return ScalesState(
      allScales: allScales ?? this.allScales,
      filteredScales: filteredScales ?? this.filteredScales,
      selectedRoot: selectedRoot ?? this.selectedRoot,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedScale: identical(selectedScale, _unset)
          ? this.selectedScale
          : selectedScale as Scale?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _unset = Object();
}

/// Provider for [ScalesViewModel].
final scalesViewModelProvider =
    StateNotifierProvider<ScalesViewModel, ScalesState>(
  (ref) => ScalesViewModel(),
);

/// Manages scales screen state: loading, root/category filtering, selection.
class ScalesViewModel extends StateNotifier<ScalesState> {
  ScalesViewModel() : super(const ScalesState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/scales.json');
      final list = json.decode(jsonStr) as List<dynamic>;
      final scales =
          list.map((e) => Scale.fromJson(e as Map<String, dynamic>)).toList();

      state = state.copyWith(
        allScales: scales,
        filteredScales: _filter(scales, state.selectedRoot, state.selectedCategory),
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('ScalesViewModel._load error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load scales.',
      );
    }
  }

  /// Filters scales by [root] note.
  void filterByRoot(String root) {
    state = state.copyWith(
      selectedRoot: root,
      filteredScales: _filter(state.allScales, root, state.selectedCategory),
      selectedScale: null,
    );
  }

  /// Filters scales by [category] ('Scales', 'Modes', 'Exotic').
  void filterByCategory(String cat) {
    state = state.copyWith(
      selectedCategory: cat,
      filteredScales: _filter(state.allScales, state.selectedRoot, cat),
      selectedScale: null,
    );
  }

  /// Sets the currently highlighted scale.
  void selectScale(Scale scale) {
    state = state.copyWith(selectedScale: scale);
  }

  /// Clears the selected scale.
  void clearSelection() {
    state = state.copyWith(selectedScale: null);
  }

  List<Scale> _filter(List<Scale> all, String root, String category) {
    return all
        .where((s) =>
            s.root == root &&
            ScaleCategory.fromType(s.type) == category)
        .toList();
  }
}
