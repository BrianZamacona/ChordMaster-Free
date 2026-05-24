import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/mappers/generated_pattern_mapper.dart';
import 'domain/models/string_configuration.dart';
import 'domain/models/tablature_constraints.dart';
import 'domain/services/arpeggio_generation_engine.dart';
import 'domain/services/chord_voicing_engine.dart';
import 'domain/services/direct_harmonization_service.dart';
import 'domain/services/fretboard_calculator.dart';
import 'domain/services/fretboard_geometry_service.dart';
import 'domain/services/reverse_harmonization_service.dart';
import 'domain/services/roman_progression_service.dart';
import 'domain/services/scale_generation_engine.dart';
import 'domain/strategies/berklee_strategy.dart';
import 'domain/strategies/caged_strategy.dart';
import 'domain/strategies/fingering_strategy.dart';
import 'domain/strategies/linear_four_notes_strategy.dart';
import 'domain/strategies/pentatonic_two_notes_strategy.dart';
import 'domain/strategies/three_notes_per_string_strategy.dart';

// ── Core engine ───────────────────────────────────────────────────────────────

/// Provides the stateless [FretboardGeometryService] singleton.
final fretboardGeometryServiceProvider =
    Provider<FretboardGeometryService>((ref) => const FretboardGeometryService());

/// Provides the stateless [FretboardCalculator] singleton.
final fretboardCalculatorProvider = Provider<FretboardCalculator>(
  (ref) => FretboardCalculator(ref.read(fretboardGeometryServiceProvider)),
);

/// Default tablature constraints for generated output.
final tablatureConstraintsProvider =
    Provider<TablatureConstraints>((ref) => const TablatureConstraints());

/// Formal scales generation engine.
final scaleGenerationEngineProvider = Provider<ScaleGenerationEngine>(
  (ref) => ScaleGenerationEngine(calculator: ref.read(fretboardCalculatorProvider)),
);

/// Formal arpeggio generation engine.
final arpeggioGenerationEngineProvider = Provider<ArpeggioGenerationEngine>(
  (ref) => ArpeggioGenerationEngine(scaleEngine: ref.read(scaleGenerationEngineProvider)),
);

/// Formal chord voicing engine.
final chordVoicingEngineProvider = Provider<ChordVoicingEngine>(
  (ref) => ChordVoicingEngine(scaleEngine: ref.read(scaleGenerationEngineProvider)),
);

/// Direct harmonization service: scale -> chords.
final directHarmonizationServiceProvider =
    Provider<DirectHarmonizationService>((ref) => const DirectHarmonizationService());

/// Reverse harmonization service: chord -> scale candidates.
final reverseHarmonizationServiceProvider =
    Provider<ReverseHarmonizationService>((ref) => const ReverseHarmonizationService());

/// Roman progression transposition service.
final romanProgressionServiceProvider =
    Provider<RomanProgressionService>((ref) => const RomanProgressionService());

// ── Strategies ────────────────────────────────────────────────────────────────

/// All available [FingeringStrategy] instances keyed by their [name].
///
/// The insertion order defines the display order in the UI.
final fingeringStrategiesProvider = Provider<Map<String, FingeringStrategy>>((ref) => const {
    ThreeNotesPerStringStrategy.strategyName: ThreeNotesPerStringStrategy(),
    CagedStrategy.strategyName: CagedStrategy(),
    PentatonicTwoNotesStrategy.strategyName: PentatonicTwoNotesStrategy(),
    BerkleeStrategy.strategyName: BerkleeStrategy(),
    LinearFourNotesStrategy.strategyName: LinearFourNotesStrategy(),
  });

// ── String presets ────────────────────────────────────────────────────────────

/// All available [StringConfiguration] presets.
final stringConfigPresetsProvider = Provider<List<StringConfiguration>>((ref) => StringConfiguration.presets);

/// Presets keyed by stable tuning id.
final stringConfigByIdProvider = Provider<Map<String, StringConfiguration>>(
  (ref) => {for (final preset in ref.watch(stringConfigPresetsProvider)) preset.id: preset},
);

// ── Mapper ────────────────────────────────────────────────────────────────────

/// Provides the [GeneratedPatternMapper] singleton.
final generatedPatternMapperProvider = Provider<GeneratedPatternMapper>((ref) => const GeneratedPatternMapper());
