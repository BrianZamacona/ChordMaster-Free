/// Explanatory metadata for a fingering system (CAGED, 3NPS, etc.).
///
/// This is the single place where the *theory* behind a fingering system
/// lives — the explanation text and the canonical shape order — so that
/// both `features/chords` and the scale explorer read from the same
/// source instead of each maintaining their own copy (which is what
/// caused CAGED to be implemented twice, out of sync, before this).
class FingeringSystemTheory {
  const FingeringSystemTheory({
    required this.id,
    required this.name,
    required this.shortExplanation,
    required this.shapeOrder,
    required this.howShapesConnect,
  });

  /// Stable id matching `FingeringSystem.id` / `ScalePosition.systemId`
  /// in the data layer (e.g. 'caged', '3nps').
  final String id;

  /// Display name (e.g. 'CAGED').
  final String name;

  /// 2-3 sentence explanation of what the system is, shown once per
  /// system (not repeated per scale/chord).
  final String shortExplanation;

  /// Canonical order of shape labels, e.g. ['C', 'A', 'G', 'E', 'D'].
  /// Empty for systems that don't have named shapes (e.g. 3NPS).
  final List<String> shapeOrder;

  /// Explanation of how consecutive shapes overlap/connect on the neck.
  final String howShapesConnect;
}
