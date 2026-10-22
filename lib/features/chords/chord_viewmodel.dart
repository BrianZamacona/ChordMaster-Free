import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../data/repository/chord_repository.dart';
import '../../domain/theory/notes.dart';
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
  final aRootIndex = noteIndex(a.root);
  final bRootIndex = noteIndex(b.root);
  final normalizedARootIndex = aRootIndex == -1 ? noteNames.length : aRootIndex;
  final normalizedBRootIndex = bRootIndex == -1 ? noteNames.length : bRootIndex;
  final rootCompare = normalizedARootIndex.compareTo(normalizedBRootIndex);
  if (rootCompare != 0) return rootCompare;
  final typeCompare =
      (chordTypeMetadata[a.type]?.order ?? 999).compareTo(chordTypeMetadata[b.type]?.order ?? 999);
  if (typeCompare != 0) return typeCompare;
  return a.name.compareTo(b.name);
}

/// Manages chord library state: loading, filtering by root/type/tag, and search.
class ChordViewModel extends Notifier<ChordState> {
  /// Raíz con la que abre la biblioteca (288 acordes de golpe abruman).
  static const defaultRoot = 'C';

  final Map<String, Chord> _nameIndex = {};

  @override
  ChordState build() {
    _load();
    return const ChordState(selectedRoot: defaultRoot);
  }

  Future<void> _load() async {
    try {
      final chords = [...await ref.read(chordRepositoryProvider).chords()]
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
        isLoading: false,
        errorMessage: null,
      );
      _applyFilters();
    } catch (e, st) {
      debugPrint('ChordViewModel._load error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppStrings.errorLoadChords,
      );
    }
  }

  /// Filters chords by [query] text, keeping active root/type/tag filters.
  ///
  /// Al empezar a escribir se quita la raíz por defecto: buscar "Bm7" no
  /// debe quedar escondido tras el filtro de C que el usuario no eligió.
  void search(String query) {
    final dropDefault = query.isNotEmpty &&
        state.searchQuery.isEmpty &&
        state.selectedRoot == defaultRoot;
    state = state.copyWith(
      searchQuery: query,
      selectedRoot: dropDefault ? null : state.selectedRoot,
    );
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

  /// Vuelve a los filtros iniciales (raíz C, sin tipo ni estilo).
  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedRoot: defaultRoot,
      selectedType: null,
      selectedTag: null,
    );
    _applyFilters();
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
  Chord? findByName(String name) => _nameIndex[name.toLowerCase()];

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
