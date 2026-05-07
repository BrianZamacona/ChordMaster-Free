import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/chord_metadata.dart';
import '../../core/constants/music_theory.dart';
import '../../models/chord.dart';

/// Immutable state for [ChordViewModel].
class ChordState {
  const ChordState({
    this.allChords = const [],
    this.filteredChords = const [],
    this.searchQuery = '',
    this.selectedRoot,
    this.selectedType,
    this.selectedTag,
    this.isLoading = true,
    this.errorMessage,
  });

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

  /// Selected musical category filter, or `null` for all categories.
  final String? selectedTag;

  /// Whether the initial load is in progress.
  final bool isLoading;

  /// Non-null error message if the last operation failed.
  final String? errorMessage;

  ChordState copyWith({
    List<Chord>? allChords,
    List<Chord>? filteredChords,
    String? searchQuery,
    Object? selectedRoot = _unset,
    Object? selectedType = _unset,
    Object? selectedTag = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) =>
      ChordState(
        allChords: allChords ?? this.allChords,
        filteredChords: filteredChords ?? this.filteredChords,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedRoot: identical(selectedRoot, _unset)
            ? this.selectedRoot
            : selectedRoot as String?,
        selectedType: identical(selectedType, _unset)
            ? this.selectedType
            : selectedType as String?,
        selectedTag: identical(selectedTag, _unset)
            ? this.selectedTag
            : selectedTag as String?,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _unset)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const Object _unset = Object();
}

/// Provider for [ChordViewModel].
final chordViewModelProvider =
    NotifierProvider<ChordViewModel, ChordState>(ChordViewModel.new);

/// Applies the current chord filters and search query to [chords].
List<Chord> filterChords({
  required List<Chord> chords,
  String searchQuery = '',
  String? selectedRoot,
  String? selectedType,
  String? selectedTag,
}) {
  final query = searchQuery.toLowerCase().trim();
  final results = chords.where((chord) {
    final resolvedTags = chordTags(chord.type, chord.tags);
    if (selectedRoot != null && chord.root != selectedRoot) return false;
    if (selectedType != null && chord.type != selectedType) return false;
    if (selectedTag != null && !resolvedTags.contains(selectedTag)) {
      return false;
    }
    if (query.isEmpty) return true;

    return _matchesChordSearch(
      chord: chord,
      query: query,
      resolvedTags: resolvedTags,
    );
  }).toList(growable: false)
    ..sort(_compareChords);

  return results;
}

bool _matchesChordSearch({
  required Chord chord,
  required String query,
  required List<String> resolvedTags,
}) {
  final searchableFields = <String>[
    chord.name,
    chordDisplayName(
      root: chord.root,
      type: chord.type,
      explicitDisplayName: chord.displayName,
    ),
    chord.root,
    chord.type,
    chordTypeLabel(chord.type),
    ...chordAliases(chord.type, chord.aliases),
    ...resolvedTags,
    ...resolvedTags.map(chordTagLabel),
  ];
  return searchableFields.any(
    (field) => field.toLowerCase().contains(query),
  );
}

int _compareChords(Chord a, Chord b) {
  final rootCompare = chromaticNotes.indexOf(a.root).compareTo(chromaticNotes.indexOf(b.root));
  if (rootCompare != 0) return rootCompare;
  final typeCompare =
      (chordTypeMetadata[a.type]?.order ?? 999).compareTo(chordTypeMetadata[b.type]?.order ?? 999);
  if (typeCompare != 0) return typeCompare;
  return a.name.compareTo(b.name);
}

/// Manages chord library state: loading, filtering by root/type/tag, and search.
class ChordViewModel extends Notifier<ChordState> {
  final Map<String, Chord> _nameIndex = {};

  @override
  ChordState build() {
    _load();
    return const ChordState();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/chords.json');
      final list = json.decode(jsonStr) as List<dynamic>;
      final chords = list
          .map((entry) => Chord.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false)
        ..sort(_compareChords);

      _nameIndex
        ..clear()
        ..addEntries(
          chords.expand((chord) {
            final displayName = chordDisplayName(
              root: chord.root,
              type: chord.type,
              explicitDisplayName: chord.displayName,
            );
            return [
              MapEntry(chord.name.toLowerCase(), chord),
              MapEntry(displayName.toLowerCase(), chord),
            ];
          }),
        );

      state = state.copyWith(
        allChords: chords,
        filteredChords: chords,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e, st) {
      debugPrint('ChordViewModel._load error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load chords.',
      );
    }
  }

  /// Filters chords by [query] text, keeping active root/type/tag filters.
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

  /// Filters chords by [tag]. Pass `null` to clear.
  void filterByTag(String? tag) {
    state = state.copyWith(selectedTag: tag);
    _applyFilters();
  }

  /// Clears all active filters.
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedRoot: null,
      selectedType: null,
      selectedTag: null,
      filteredChords: state.allChords,
    );
  }

  void _applyFilters() {
    state = state.copyWith(
      filteredChords: filterChords(
        chords: state.allChords,
        searchQuery: state.searchQuery,
        selectedRoot: state.selectedRoot,
        selectedType: state.selectedType,
        selectedTag: state.selectedTag,
      ),
    );
  }

  /// Returns a [Chord] whose name matches [name], or `null` if not found.
  Chord? findByName(String name) {
    return _nameIndex[name.toLowerCase()];
  }

  /// Returns all chords sharing the same root as [chord].
  List<Chord> relatedByRoot(Chord chord) => state.allChords
      .where((candidate) => candidate.root == chord.root && candidate.name != chord.name)
      .toList(growable: false)
    ..sort(_compareChords);

  /// Returns chords that share at least one musical category with [chord].
  List<Chord> relatedByTags(Chord chord, {int limit = 8}) {
    final tags = chordTags(chord.type, chord.tags).toSet();
    return state.allChords
        .where((candidate) => candidate.name != chord.name)
        .where(
          (candidate) => chordTags(candidate.type, candidate.tags)
              .any(tags.contains),
        )
        .take(limit)
        .toList(growable: false);
  }
}
