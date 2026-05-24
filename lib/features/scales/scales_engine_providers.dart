import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/mappers/generated_pattern_mapper.dart';
import 'domain/models/string_configuration.dart';
import 'domain/services/fretboard_calculator.dart';
import 'domain/strategies/berklee_strategy.dart';
import 'domain/strategies/caged_strategy.dart';
import 'domain/strategies/fingering_strategy.dart';
import 'domain/strategies/linear_four_notes_strategy.dart';
import 'domain/strategies/pentatonic_two_notes_strategy.dart';
import 'domain/strategies/three_notes_per_string_strategy.dart';

// ── Core engine ───────────────────────────────────────────────────────────────

/// Provides the stateless [FretboardCalculator] singleton.
final fretboardCalculatorProvider = Provider<FretboardCalculator>((ref) {
  return const FretboardCalculator();
});

// ── Strategies ────────────────────────────────────────────────────────────────

/// All available [FingeringStrategy] instances keyed by their [name].
///
/// The insertion order defines the display order in the UI.
final fingeringStrategiesProvider = Provider<Map<String, FingeringStrategy>>((ref) {
  return const {
    ThreeNotesPerStringStrategy.strategyName: ThreeNotesPerStringStrategy(),
    CagedStrategy.strategyName: CagedStrategy(),
    PentatonicTwoNotesStrategy.strategyName: PentatonicTwoNotesStrategy(),
    BerkleeStrategy.strategyName: BerkleeStrategy(),
    LinearFourNotesStrategy.strategyName: LinearFourNotesStrategy(),
  };
});

// ── String presets ────────────────────────────────────────────────────────────

/// All available [StringConfiguration] presets.
final stringConfigPresetsProvider = Provider<List<StringConfiguration>>((ref) {
  return StringConfiguration.presets;
});

// ── Mapper ────────────────────────────────────────────────────────────────────

/// Provides the [GeneratedPatternMapper] singleton.
final generatedPatternMapperProvider = Provider<GeneratedPatternMapper>((ref) {
  return const GeneratedPatternMapper();
});
