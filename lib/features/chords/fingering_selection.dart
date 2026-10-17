import '../../core/constants/app_strings.dart';
import '../../models/chord.dart';

/// Máximo de digitaciones en el comparador.
const maxCompareSelection = 3;

/// Secciones seleccionables; son las claves estables de `sel=` (`sección:índice`).
const compareSections = [
  'main',
  'caged',
  'voicings',
  'triadInversions',
  'advancedInversions',
];

/// Digitaciones de [section]; vacío si la sección no existe.
List<ChordExplorerItem> sectionItems(Chord chord, String section) =>
    switch (section) {
      'main' => [
          ChordExplorerItem(
            title: chord.displayName ?? chord.name,
            fretPositions: chord.fretPositions,
            fingerPositions: chord.fingerPositions,
            baseFret: chord.baseFret,
          ),
        ],
      'caged' => chord.cagedPositions,
      'voicings' => chord.voicings,
      'triadInversions' => chord.triadInversions,
      'advancedInversions' => chord.advancedInversions,
      _ => const [],
    };

String sectionTitle(String section) => switch (section) {
      'main' => AppStrings.compareMainSection,
      'caged' => 'CAGED',
      'voicings' => AppStrings.curatedVoicings,
      'triadInversions' => AppStrings.triadInversions,
      'advancedInversions' => AppStrings.advancedInversions,
      _ => section,
    };

/// Referencia estable a una digitación: por índice, nunca por título.
class FingeringRef {
  const FingeringRef(this.section, this.index);

  final String section;
  final int index;

  String get key => '$section:$index';

  @override
  bool operator ==(Object other) =>
      other is FingeringRef && other.section == section && other.index == index;

  @override
  int get hashCode => Object.hash(section, index);
}

/// Interpreta `sel=` contra [chord]. Ignora claves mal formadas, fuera de
/// rango o repetidas, y corta en [maxCompareSelection]. Nunca lanza.
List<FingeringRef> parseFingeringSelection(String? raw, Chord chord) {
  if (raw == null) return const [];
  final result = <FingeringRef>[];
  for (final part in raw.split(',')) {
    final pieces = part.trim().split(':');
    if (pieces.length != 2) continue;
    final index = int.tryParse(pieces[1]);
    if (index == null ||
        index < 0 ||
        index >= sectionItems(chord, pieces[0]).length) {
      continue;
    }
    final ref = FingeringRef(pieces[0], index);
    if (result.contains(ref)) continue;
    result.add(ref);
    if (result.length == maxCompareSelection) break;
  }
  return result;
}

/// Título visible de [ref]; en CAGED aplica [sharedShapeLabels].
String fingeringTitle(Chord chord, FingeringRef ref) {
  final item = sectionItems(chord, ref.section)[ref.index];
  if (ref.section == 'caged') {
    return sharedShapeLabels(chord.cagedPositions)[ref.index] ?? item.title;
  }
  return item.title;
}

/// Etiquetas "G (usa la digitación E)" por índice, para formas con
/// `fretPositions` idénticos; la última forma del grupo es la de referencia.
Map<int, String> sharedShapeLabels(List<ChordExplorerItem> items) {
  final groups = <String, List<int>>{};
  for (var i = 0; i < items.length; i++) {
    groups.putIfAbsent(items[i].fretPositions.join(','), () => []).add(i);
  }
  String name(ChordExplorerItem item) => item.shape ?? item.title;
  return {
    for (final group in groups.values)
      if (group.length > 1)
        for (final i in group.take(group.length - 1))
          i: '${name(items[i])} (usa la digitación ${name(items[group.last])})',
  };
}
