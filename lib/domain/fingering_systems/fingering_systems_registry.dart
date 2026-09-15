import 'berklee/berklee_generator.dart';
import 'berklee/berklee_theory.dart';
import 'caged/caged_shape_generator.dart';
import 'caged/caged_theory.dart';
import 'fingering_generator.dart';
import 'fingering_theory.dart';
import 'linear_four_notes/linear_four_notes_generator.dart';
import 'linear_four_notes/linear_four_notes_theory.dart';
import 'pentatonic_two_notes/pentatonic_two_notes_generator.dart';
import 'pentatonic_two_notes/pentatonic_two_notes_theory.dart';
import 'three_nps/three_nps_generator.dart';
import 'three_nps/three_nps_theory.dart';

/// Single source of truth mapping a fingering-system id to its theory
/// metadata and its shape generator.
///
/// `features/chords` and the scale explorer both read from here instead
/// of each hardcoding their own copy of a system's theory — that
/// duplication is what caused CAGED to drift out of sync between the
/// two features before this module existed.
class FingeringSystemsRegistry {
  const FingeringSystemsRegistry._();

  static const Map<String, FingeringSystemTheory> theories = {
    'caged': cagedTheory,
    'three_nps': threeNpsTheory,
    'linear_four_notes': linearFourNotesTheory,
    'pentatonic_two_notes': pentatonicTwoNotesTheory,
    'berklee': berkleeTheory,
  };

  static const Map<String, FingeringGenerator> generators = {
    'caged': CagedShapeGenerator(),
    'three_nps': ThreeNpsGenerator(),
    'linear_four_notes': LinearFourNotesGenerator(),
    'pentatonic_two_notes': PentatonicTwoNotesGenerator(),
    'berklee': BerkleeGenerator(),
  };

  static FingeringSystemTheory? theoryFor(String systemId) =>
      theories[systemId];

  static FingeringGenerator? generatorFor(String systemId) =>
      generators[systemId];

  /// All registered systems, in a stable display order — use this to
  /// drive the `_SystemFilterRow` chips instead of whatever order a
  /// scale's own JSON `systems` list happens to be in.
  static const List<String> displayOrder = [
    'caged',
    'three_nps',
    'pentatonic_two_notes',
    'linear_four_notes',
    'berklee',
  ];
}
