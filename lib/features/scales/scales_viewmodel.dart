import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/scale.dart';
import 'data/mappers/generated_pattern_mapper.dart';
import 'data/models/scale_pattern.dart' as engine_pattern;
import 'domain/models/string_configuration.dart';
import 'scale_enrichment.dart';
import 'scale_pattern_validator.dart';
import 'scales_engine_providers.dart';

/// Category constants for scale grouping.
class ScaleCategory {
  ScaleCategory._();
  static const String scales = 'Scales';
  static const String modes = 'Modes';
  static const String exotic = 'Exotic';
  static const List<String> all = [scales, modes, exotic];

  /// Scale types that belong to the Modes category.
  static const _modeTypes = {
    'ionian',
    'dorian',
    'phrygian',
    'lydian',
    'mixolydian',
    'aeolian',
    'locrian',
  };

  /// Scale types that belong to the Exotic category.
  static const _exoticTypes = {
    'hungarianMinor',
    'phrygianDominant',
    'doubleHarmonic',
    'neapolitan',
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
  const ScalesState({
    this.allScales = const [],
    this.filteredScales = const [],
    this.selectedRoot = 'C',
    this.selectedCategory = ScaleCategory.scales,
    this.selectedScale,
    this.isLoading = true,
    this.errorMessage,
    // ── Engine state ──────────────────────────────────────────────────────────
    this.generatedPatterns = const [],
    this.selectedStrategyName =
        '3NPS', // ThreeNotesPerStringStrategy.strategyName
    this.engineStringCount = 6,
    this.engineStartingFret = 1,
    this.engineMaxFretSpan = 5,
  });

  // ── Legacy pipeline fields ─────────────────────────────────────────────────

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

  // ── Engine pipeline fields ─────────────────────────────────────────────────

  /// Algorithmically generated patterns for [selectedScale].
  ///
  /// These are strict-coordinate [engine_pattern.ScalePattern] instances
  /// produced by the new domain engine and are rendered via [FretboardDiagram].
  final List<engine_pattern.ScalePattern> generatedPatterns;

  /// Name of the active [FingeringStrategy].
  final String selectedStrategyName;

  /// Number of strings used for generation (6, 7 or 8).
  final int engineStringCount;

  /// First fret of the generation window.
  final int engineStartingFret;

  /// Fret span for the generation window.
  final int engineMaxFretSpan;

  // ── copyWith ───────────────────────────────────────────────────────────────

  ScalesState copyWith({
    List<Scale>? allScales,
    List<Scale>? filteredScales,
    String? selectedRoot,
    String? selectedCategory,
    Object? selectedScale = _unset,
    bool? isLoading,
    Object? errorMessage = _unset,
    List<engine_pattern.ScalePattern>? generatedPatterns,
    String? selectedStrategyName,
    int? engineStringCount,
    int? engineStartingFret,
    int? engineMaxFretSpan,
  }) =>
      ScalesState(
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
        generatedPatterns: generatedPatterns ?? this.generatedPatterns,
        selectedStrategyName: selectedStrategyName ?? this.selectedStrategyName,
        engineStringCount: engineStringCount ?? this.engineStringCount,
        engineStartingFret: engineStartingFret ?? this.engineStartingFret,
        engineMaxFretSpan: engineMaxFretSpan ?? this.engineMaxFretSpan,
      );

  static const Object _unset = Object();
}

/// Provider for [ScalesViewModel].
final scalesViewModelProvider =
    NotifierProvider<ScalesViewModel, ScalesState>(ScalesViewModel.new);

/// Manages scales screen state: loading, root/category filtering, selection.
class ScalesViewModel extends Notifier<ScalesState> {
  static const _validator = ScalePatternValidator();

  @override
  ScalesState build() {
    _load();
    return const ScalesState();
  }

  Future<void> _load() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/scales.json');
      final list = json.decode(jsonStr) as List<dynamic>;
      final scales = list
          .map((e) => Scale.fromJson(e as Map<String, dynamic>))
          .map(ScaleEnrichment.enrich)
          .map(_validatePatterns)
          .toList(growable: false);

      state = state.copyWith(
        allScales: scales,
        filteredScales:
            _filter(scales, state.selectedRoot, state.selectedCategory),
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
      generatedPatterns: [],
    );
  }

  /// Filters scales by [category] ('Scales', 'Modes', 'Exotic').
  void filterByCategory(String cat) {
    state = state.copyWith(
      selectedCategory: cat,
      filteredScales: _filter(state.allScales, state.selectedRoot, cat),
      selectedScale: null,
      generatedPatterns: [],
    );
  }

  /// Sets the currently highlighted scale and generates engine patterns for it.
  void selectScale(Scale scale) {
    state = state.copyWith(selectedScale: scale);
    _generateEnginePatterns(scale);
  }

  /// Clears the selected scale and any generated patterns.
  void clearSelection() {
    state = state.copyWith(
      selectedScale: null,
      generatedPatterns: [],
    );
  }

  /// Updates the active [FingeringStrategy] and regenerates patterns.
  void selectStrategy(String strategyName) {
    state = state.copyWith(selectedStrategyName: strategyName);
    if (state.selectedScale != null) {
      _generateEnginePatterns(state.selectedScale!);
    }
  }

  /// Updates the engine string count and regenerates patterns.
  void selectStringCount(int count) {
    state = state.copyWith(engineStringCount: count);
    if (state.selectedScale != null) {
      _generateEnginePatterns(state.selectedScale!);
    }
  }

  /// Updates the engine starting fret and regenerates patterns.
  void selectStartingFret(int fret) {
    state = state.copyWith(engineStartingFret: fret);
    if (state.selectedScale != null) {
      _generateEnginePatterns(state.selectedScale!);
    }
  }

  /// Generates algorithmic fretboard patterns for [scale] using the active
  /// strategy and engine settings, then stores them in [ScalesState.generatedPatterns].
  void _generateEnginePatterns(Scale scale) {
    try {
      final strategies = ref.read(fingeringStrategiesProvider);
      final calculator = ref.read(fretboardCalculatorProvider);
      final mapper = ref.read(generatedPatternMapperProvider);

      final strategy =
          strategies[state.selectedStrategyName] ?? strategies.values.first;

      final config = _configForStringCount(state.engineStringCount);

      final notes = calculator.calculate(
        root: scale.root,
        intervals: scale.intervals,
        strategy: strategy,
        config: config,
        startingFret: state.engineStartingFret,
        maxFretSpan: state.engineMaxFretSpan,
      );

      final pattern = mapper.map(
        notes: notes,
        scaleName: scale.type,
        root: scale.root,
        strategyName: strategy.name,
        positionName: 'Pos. ${state.engineStartingFret} fr',
      );

      state = state.copyWith(
        generatedPatterns: pattern == null ? [] : [pattern],
      );
    } catch (e, st) {
      debugPrint('ScalesViewModel._generateEnginePatterns error: $e\n$st');
      state = state.copyWith(generatedPatterns: []);
    }
  }

  static StringConfiguration _configForStringCount(int count) {
    switch (count) {
      case 7:
        return StringConfiguration.standard7;
      case 8:
        return StringConfiguration.standard8;
      default:
        return StringConfiguration.standard6;
    }
  }

  List<Scale> _filter(List<Scale> all, String root, String category) => all
      .where(
          (s) => s.root == root && ScaleCategory.fromType(s.type) == category)
      .toList();

  Scale _validatePatterns(Scale scale) {
    final block = _validator.validate(
      scale: scale,
      patterns: scale.blockFingerings,
      system: ScalePatternSystem.block,
    );
    final threeNps = _validator.validate(
      scale: scale,
      patterns: scale.threeNotePerStringFingerings,
      system: ScalePatternSystem.threeNps,
    );
    final caged = _validator.validate(
      scale: scale,
      patterns: scale.cagedFingerings,
      system: ScalePatternSystem.caged,
    );

    final issues = [...block.issues, ...threeNps.issues, ...caged.issues];
    if (issues.isNotEmpty) {
      for (final issue in issues) {
        debugPrint(
          'Scale pattern rejected [${scale.name}] ${issue.patternName}: ${issue.reason}',
        );
      }
    }

    return scale.copyWith(
      blockFingerings: block.validPatterns,
      threeNotePerStringFingerings: threeNps.validPatterns,
      cagedFingerings: caged.validPatterns,
    );
  }
}
