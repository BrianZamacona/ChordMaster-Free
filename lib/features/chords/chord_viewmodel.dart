import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chord.dart';

/// Immutable state for [ChordViewModel].
class ChordState {
  /// All chords loaded from the asset bundle.
  final List<Chord> allChords;

  /// Chords that match the current search and filter criteria.
  final List<Chord> filteredChords;

  /// Current text-based search query.
  final String searchQuery;

  /// Selected root note filter, or `null` for all roots.
  final String? selectedRoot;

  /// Selected chord type filter, or `null` for all types.
  final String? selectedType;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Non-null error message if the last operation failed.
  final String? errorMessage;

  const ChordState({
    this.allChords = const [],
    this.filteredChords = const [],
    this.searchQuery = '',
    this.selectedRoot,
    this.selectedType,
    this.isLoading = true,
    this.errorMessage,
  });

  ChordState copyWith({
    List<Chord>? allChords,
    List<Chord>? filteredChords,
    String? searchQuery,
    Object? selectedRoot = _unset,
    Object? selectedType = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return ChordState(
      allChords: allChords ?? this.allChords,
      filteredChords: filteredChords ?? this.filteredChords,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoot:
          identical(selectedRoot, _unset) ? this.selectedRoot : selectedRoot as String?,
      selectedType:
          identical(selectedType, _unset) ? this.selectedType : selectedType as String?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
    );
  }

  static const Object _unset = Object();
}

/// Provider for [ChordViewModel].
final chordViewModelProvider =
    StateNotifierProvider<ChordViewModel, ChordState>(
  (ref) => ChordViewModel(),
);

/// Manages chord library state: loading, filtering by root/type, and search.
///
/// Uses a precomputed index [Map<String, List<Chord>>] keyed by
/// `"$root|$type"` for O(1) lookup before applying text-query filtering.
class ChordViewModel extends StateNotifier<ChordState> {
  ChordViewModel() : super(const ChordState()) {
    _load();
  }

  /// Index: "root|type" → list of matching chords for O(1) filtering.
  final Map<String, List<Chord>> _index = {};

  Future<void> _load() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/chords.json');
      final list = json.decode(jsonStr) as List<dynamic>;
      final chords =
          list.map((e) => Chord.fromJson(e as Map<String, dynamic>)).toList();

      // Build precomputed index
      for (final chord in chords) {
        final key = '${chord.root}|${chord.type}';
        _index.putIfAbsent(key, () => []).add(chord);
      }

      state = state.copyWith(
        allChords: chords,
        filteredChords: chords,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('ChordViewModel._load error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load chords.',
      );
    }
  }

  /// Filters chords by [query] text, keeping active root/type filters.
  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  /// Filters chords by [root] note. Pass `null` to clear.
  void filterByRoot(String? root) {
    state = state.copyWith(selectedRoot: root);
    _applyFilters();
  }

  /// Filters chords by [type]. Pass `null` to clear.
  void filterByType(String? type) {
    state = state.copyWith(selectedType: type);
    _applyFilters();
  }

  /// Clears all active filters.
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedRoot: null,
      selectedType: null,
      filteredChords: state.allChords,
    );
  }

  void _applyFilters() {
    final root = state.selectedRoot;
    final type = state.selectedType;
    final query = state.searchQuery.toLowerCase().trim();

    List<Chord> results;

    if (root != null && type != null) {
      results = _index['$root|$type'] ?? [];
    } else if (root != null) {
      // Collect all types for this root
      results = state.allChords.where((c) => c.root == root).toList();
    } else if (type != null) {
      results = state.allChords.where((c) => c.type == type).toList();
    } else {
      results = state.allChords;
    }

    if (query.isNotEmpty) {
      results = results
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.root.toLowerCase().contains(query) ||
              c.type.toLowerCase().contains(query))
          .toList();
    }

    state = state.copyWith(filteredChords: results);
  }

  /// Returns a [Chord] whose name matches [name], or `null` if not found.
  Chord? findByName(String name) {
    try {
      return state.allChords.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns all chords sharing the same root as [chord].
  List<Chord> relatedByRoot(Chord chord) {
    return state.allChords
        .where((c) => c.root == chord.root && c.name != chord.name)
        .toList();
  }
}
