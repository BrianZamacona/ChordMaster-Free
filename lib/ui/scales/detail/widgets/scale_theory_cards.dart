import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/chord_metadata.dart';
import '../../../../core/i18n/tr.dart';
import '../../../../domain/theory/double_stops.dart' show noteNames;
import '../../../../domain/theory/intervals.dart';
import '../../../../domain/theory/scale_insights.dart';
import '../../../theme.dart';

/// "¿Por qué suena así?" de una escala: pasos, qué la distingue y sus
/// acordes diatónicos. Todo sale de `domain/theory/scale_insights.dart`.
class ScaleWhyCard extends StatelessWidget {
  const ScaleWhyCard({
    super.key,
    required this.intervals,
    required this.rootSemitone,
  });

  final List<int> intervals;
  final int rootSemitone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final comparison = compareScale(intervals);
    final period = symmetryPeriod(intervals);
    final triads = diatonicTriads(intervals);
    return _TheoryCard(
      key: const Key('scale-why'),
      icon: Icons.lightbulb_outline,
      title: AppStrings.whyTitle,
      children: [
        _Line(
          label: AppStrings.scaleSteps,
          child: Text(
            stepPatternLabel(intervals),
            style: musicMono(fontSize: 14, color: p.textPrimary),
          ),
        ),
        if (comparison != null)
          Text(describeComparison(comparison, intervals), style: text.bodyMedium),
        if (period != null)
          Text(
            tr(
              es: 'Es simétrica: el mismo patrón se repite cada $period trastes, así que una forma sirve en varios sitios.',
              en: 'It is symmetric: the same pattern repeats every $period frets, so one shape works in several places.',
            ),
            style: text.bodyMedium,
          ),
        if (triads.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(AppStrings.scaleDiatonicChords, style: text.titleSmall),
          Text(AppStrings.scaleDiatonicHint, style: text.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in triads)
                _ChordChip(
                  top: c.numeral,
                  bottom: chordDisplayName(
                    root: noteNames[(rootSemitone + c.semitones) % 12],
                    type: c.type,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Frase que explica en qué se diferencia la escala de su referencia.
String describeComparison(ScaleComparison c, List<int> scale) {
  final ref = c.reference.text;
  final added = [for (final i in c.added) spellInterval(i, scale)];
  final removed = [for (final i in c.removed) spellInterval(i, c.referenceIntervals)];
  if (added.isEmpty) {
    return tr(
      es: 'Es $ref sin ${removed.join(' ni ')}: quita las notas que más chocan, por eso es tan fácil de usar.',
      en: 'It is $ref without the ${removed.join(' or ')}: it drops the notes that clash most, which is why it is so easy to use.',
    );
  }
  if (removed.isEmpty) {
    return tr(
      es: 'Es $ref con ${added.join(' y ')} añadida: esa nota de paso le da su color.',
      en: 'It is $ref with an added ${added.join(' and ')}: that passing note gives it its color.',
    );
  }
  if (added.length == removed.length) {
    final swaps = [for (var i = 0; i < added.length; i++) '${added[i]} ${tr(es: 'en vez de', en: 'instead of')} ${removed[i]}'];
    return tr(
      es: 'Es $ref con ${swaps.join(' y ')}. ${added.length == 1 ? 'Esa es su nota característica' : 'Esas son sus notas características'}: apóyate en ${added.length == 1 ? 'ella' : 'ellas'} para que se oiga.',
      en: 'It is $ref with ${swaps.join(' and ')}. ${added.length == 1 ? 'That is its characteristic note' : 'Those are its characteristic notes'}: lean on ${added.length == 1 ? 'it' : 'them'} so it can be heard.',
    );
  }
  return tr(
    es: 'Comparada con $ref: añade ${added.join(', ')} y quita ${removed.join(', ')}.',
    en: 'Compared with $ref: it adds ${added.join(', ')} and drops ${removed.join(', ')}.',
  );
}

/// Cómo improvisar con la escala (antes era un módulo aparte).
class ScaleImproviseCard extends StatelessWidget {
  const ScaleImproviseCard({
    super.key,
    required this.scaleId,
    required this.intervals,
    required this.rootName,
  });

  final String scaleId;
  final List<int> intervals;
  final String rootName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final tip = improvisationTips(scaleId, intervals);
    final types = chordTypesOnTonic(intervals);
    return _TheoryCard(
      key: const Key('scale-improvise'),
      icon: Icons.music_note_outlined,
      title: AppStrings.scaleImproviseTitle,
      children: [
        if (tip != null) ...[
          _Line(label: AppStrings.improvWhere, child: Text(tip.style.text, style: text.bodyMedium)),
          _Line(label: AppStrings.improvIdea, child: Text(tip.idea.text, style: text.bodyMedium)),
        ],
        if (types.isNotEmpty) ...[
          Text(AppStrings.scaleChordsFit, style: text.titleSmall),
          Text(AppStrings.scaleChordsFitHint, style: text.bodySmall?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in types)
                _ChordChip(
                  top: chordDisplayName(root: rootName, type: t),
                  bottom: chordTypeLabel(t),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TheoryCard extends StatelessWidget {
  const _TheoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      leading: Icon(icon, color: context.palette.accent),
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final c in children)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
      ],
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.palette.textSecondary,
        ),
      ),
      const SizedBox(height: 2),
      child,
    ],
  );
}

class _ChordChip extends StatelessWidget {
  const _ChordChip({required this.top, required this.bottom});

  final String top;
  final String bottom;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(top, style: musicMono(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
          Text(bottom, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}
