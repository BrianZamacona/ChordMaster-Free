import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/chord_metadata.dart';
import '../../../../core/i18n/tr.dart';
import '../../../../data/models/note_coordinate.dart';
import '../../../../data/repository/scale_repository.dart';
import '../../../../domain/theory/double_stops.dart' show noteNames;
import '../../../../domain/theory/intervals.dart';
import '../../../../domain/theory/octaves.dart';
import '../../../../domain/theory/scale_insights.dart';
import '../../../../features/chords/chord_viewmodel.dart';
import '../../../theme.dart';
import '../../../widgets/fretboard_diagram.dart';

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

/// La tónica en todo el diapasón (trastes 0–12) y las formas para saltar a
/// su octava; la forma elegida se marca con líneas. Reglas en
/// `domain/theory/octaves.dart`.
class ScaleOctavesCard extends StatefulWidget {
  const ScaleOctavesCard({super.key, required this.rootSemitone});

  final int rootSemitone;

  @override
  State<ScaleOctavesCard> createState() => _ScaleOctavesCardState();
}

class _ScaleOctavesCardState extends State<ScaleOctavesCard> {
  final _shapes = octaveShapes();
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final root = widget.rootSemitone % 12;
    final name = noteNames[root];
    final shape = _shapes[_selected];
    final pattern = ResolvedPattern(
      scaleId: 'octaves',
      scaleName: name,
      systemId: 'octaves',
      systemName: '',
      positionId: 'octaves',
      positionName: '',
      startingFret: 0,
      endFret: 12,
      coordinates: [
        for (final n in notePositions(root))
          NoteCoordinate(string: n.string, fret: n.fret, isRoot: true, note: name, interval: '1'),
      ],
    );
    return _TheoryCard(
      key: const Key('scale-octaves'),
      icon: Icons.swap_vert,
      title: AppStrings.octavesTitle,
      children: [
        Text(AppStrings.octavesHint, style: text.bodySmall?.copyWith(color: p.textSecondary)),
        FretboardDiagram(
          key: const Key('octaves-board'),
          pattern: pattern,
          height: 150,
          label: FretboardLabel.note,
          links: octavePairs(root, shape),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (i, s) in _shapes.indexed)
              ChoiceChip(
                key: Key('octave-shape-$i'),
                label: Text(
                  AppStrings.octaveShapeLabel(s.lowString, s.highString, s.fretShift),
                  style: musicMono(fontSize: 13, color: p.textPrimary),
                ),
                selected: i == _selected,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ],
        ),
        Text(
          AppStrings.octaveShapeText(
            shape.lowString,
            shape.highString,
            shape.fretShift,
            shape.octaves,
          ),
          key: const Key('octave-shape-text'),
          style: text.bodyMedium,
        ),
      ],
    );
  }
}

/// Acordes que armonizan la escala: por grado, su tríada y su cuatríada
/// (escalas de 7 notas), los de la escala de la que sale (pentatónicas y
/// blues) o los propios de las simétricas. Cada acorde abre su detalle.
class ScaleHarmonyCard extends ConsumerWidget {
  const ScaleHarmonyCard({
    super.key,
    required this.intervals,
    required this.rootSemitone,
  });

  final List<int> intervals;
  final int rootSemitone;

  String _note(int semitones) => noteNames[(rootSemitone + semitones) % 12];

  /// Nombre del acorde; los tipos que no están en chords.json se escriben
  /// con su cifrado habitual.
  String _symbol(int semitones, String type) => switch (type) {
    'minorMajor7' => '${_note(semitones)}m(maj7)',
    'augmentedMajor7' => '${_note(semitones)}maj7#5',
    _ => chordDisplayName(root: _note(semitones), type: type),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final vm = ref.read(chordViewModelProvider.notifier);
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));

    Widget chip(int semitones, String type) {
      final symbol = _symbol(semitones, type);
      final chord = vm.findByName(symbol);
      return _ChordChip(
        key: Key('harmony-$symbol'),
        top: symbol,
        bottom: switch (type) {
          'minorMajor7' => tr(es: 'Menor con 7ª mayor', en: 'Minor-major 7th'),
          'augmentedMajor7' => tr(es: 'Maj7 aumentado', en: 'Augmented major 7th'),
          _ => chordTypeLabel(type),
        },
        onTap: chord == null
            ? null
            : () => context.push('/learn/chords/${Uri.encodeComponent(chord.name)}'),
      );
    }

    final source = harmonizationSource(intervals);
    final List<Widget> body;
    if (source != null) {
      final chords = diatonicTriads(source);
      final fromParent = source.length != intervals.toSet().length;
      body = [
        Text(
          fromParent
              ? tr(
                  es: 'Esta escala sale de ${_note(0)} ${source.contains(3) ? 'menor natural' : 'mayor'}: '
                      'se acompaña con sus acordes. Cada grado forma un acorde apilando terceras '
                      'con las notas de la escala: 1-3-5 (tríada) y 1-3-5-7 (cuatríada).',
                  en: 'This scale comes from ${_note(0)} ${source.contains(3) ? 'natural minor' : 'major'}: '
                      'it is accompanied by its chords. Each degree builds a chord by stacking '
                      'thirds with the notes of the scale: 1-3-5 (triad) and 1-3-5-7 (seventh chord).',
                )
              : AppStrings.harmonyHint,
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        for (final c in chords)
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  c.numeral,
                  style: musicMono(fontSize: 15, fontWeight: FontWeight.w600, color: p.accent),
                ),
              ),
              Expanded(child: chip(c.semitones, c.type)),
              const SizedBox(width: 8),
              Expanded(child: chip(c.semitones, c.seventhType)),
            ],
          ),
      ];
    } else {
      final chords = symmetricChords(intervals);
      if (chords.isEmpty) return const SizedBox.shrink();
      body = [
        Text(
          switch (chords.first.type) {
            'augmented' => tr(
              es: 'Todas sus tríadas son aumentadas: cada una está a 2 trastes de la siguiente.',
              en: 'All of its triads are augmented: each one sits 2 frets from the next.',
            ),
            'dominant7' => tr(
              es: 'Funciona sobre acordes 7 separados 3 trastes: los cuatro comparten la escala.',
              en: 'It works over 7 chords 3 frets apart: all four share the scale.',
            ),
            _ => tr(
              es: 'Contiene dos acordes dim7; cada uno se repite cada 3 trastes.',
              en: 'It holds two dim7 chords; each repeats every 3 frets.',
            ),
          },
          style: text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final c in chords) chip(c.semitones, c.type)],
        ),
      ];
    }

    return _TheoryCard(
      key: const Key('scale-harmony'),
      icon: Icons.piano_outlined,
      title: AppStrings.harmonyTitle,
      children: body,
    );
  }
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
  const _ChordChip({super.key, required this.top, required this.bottom, this.onTap});

  final String top;
  final String bottom;

  /// Si no es null, el chip abre el acorde (borde de acento).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: onTap == null ? p.outline : p.accent.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(top, style: musicMono(fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary)),
              Text(
                bottom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
