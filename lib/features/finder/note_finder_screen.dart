import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/chord_metadata.dart';
import '../../core/constants/scale_names.dart';
import '../../core/i18n/tr.dart';
import '../../data/models/note_coordinate.dart';
import '../../data/models/scale_definition.dart';
import '../../data/repository/scale_repository.dart';
import '../../domain/theory/intervals.dart';
import '../../domain/theory/note_finder.dart';
import '../../domain/theory/notes.dart';
import '../../models/chord.dart';
import '../../ui/palette.dart';
import '../../ui/widgets/fretboard_diagram.dart';
import '../chords/chord_viewmodel.dart';
import 'note_finder_viewmodel.dart';

/// Buscador de Inicio: se marcan notas en un mástil vacío y salen los acordes
/// (una nota por cuerda) o las escalas (notas sueltas) que pueden ser. Cada
/// resultado abre su ficha.
class NoteFinderScreen extends ConsumerWidget {
  const NoteFinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteFinderProvider);
    final vm = ref.read(noteFinderProvider.notifier);
    final notes = state.notes;
    final pitchClasses = pitchClassesOf(notes);
    final names = [
      for (final pc in pitchClasses.toList()..sort()) pitchClassName(pc),
    ];
    final isChords = state.mode == FinderMode.chords;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.moduleFinder)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<FinderMode>(
            key: const Key('finder-mode'),
            segments: [
              ButtonSegment(
                value: FinderMode.chords,
                label: Text(AppStrings.moduleChords),
                icon: const Icon(Icons.piano),
              ),
              ButtonSegment(
                value: FinderMode.scales,
                label: Text(AppStrings.moduleScales),
                icon: const Icon(Icons.music_note),
              ),
            ],
            selected: {state.mode},
            onSelectionChanged: (s) => vm.setMode(s.first),
          ),
          const SizedBox(height: 12),
          Text(
            isChords ? AppStrings.finderChordHint : AppStrings.finderScaleHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.palette.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 230,
            child: FretboardNeck(
              key: ValueKey('finder-neck-${state.mode.name}'),
              coordinates: [
                for (final n in notes)
                  NoteCoordinate(
                    string: n.string,
                    fret: n.fret,
                    isRoot: false,
                    note: pitchClassName(fretNotePitchClass(n)),
                  ),
              ],
              label: FretboardLabel.note,
              onTapCell: vm.tap,
              semanticLabel: tr(
                es: 'Mástil para marcar notas. Marcadas: ${names.join(', ')}',
                en: 'Neck to mark notes. Marked: ${names.join(', ')}',
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.finderNotes(names.isEmpty ? '—' : names.join(' ')),
                  key: const Key('finder-notes'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton.icon(
                key: const Key('finder-clear'),
                onPressed: notes.isEmpty ? null : vm.clear,
                icon: const Icon(Icons.clear),
                label: Text(AppStrings.finderClear),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isChords)
            _ChordResults(pitchClasses: pitchClasses, bass: bassOf(notes))
          else
            _ScaleResults(pitchClasses: pitchClasses, tonic: bassOf(notes)),
        ],
      ),
    );
  }
}

/// "5ª" / "5th": nombre de una nota omitida del acorde.
String _degreeName(int semitones) {
  final label = chordToneLabel(semitones);
  return tr(es: '$labelª', en: '${label}th');
}

class _ChordResults extends ConsumerWidget {
  const _ChordResults({required this.pitchClasses, required this.bass});

  final Set<int> pitchClasses;
  final int? bass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chords = ref.watch(chordViewModelProvider.select((s) => s.allChords));
    if (chords.isEmpty) return const Center(child: CircularProgressIndicator());
    final byRootAndType = <(int, String), Chord>{};
    final types = <PitchFormula>[];
    for (final c in chords) {
      byRootAndType[(noteIndex(c.root), c.type)] = c;
      if (!types.any((t) => t.id == c.type)) {
        types.add((id: c.type, intervals: c.intervals));
      }
    }
    if (pitchClasses.length < 2) return _Message(AppStrings.finderPickTwo);
    final matches = [
      for (final m in chordsFor(pitchClasses, types: types, bass: bass))
        if (byRootAndType[(m.root, m.type)] case final chord?) (m, chord),
    ];
    if (matches.isEmpty) return _Message(AppStrings.finderNoChord);
    return _ResultList(
      count: matches.length,
      builder: (i) {
        final (match, chord) = matches[i];
        final name = chordDisplayName(
          root: chord.root,
          type: chord.type,
          explicitDisplayName: chord.displayName,
        );
        return _ResultTile(
          title: match.isSlash ? '$name/${pitchClassName(match.bass!)}' : name,
          subtitle: [
            chordTypeLabel(chord.type),
            if (match.omitted.isNotEmpty)
              AppStrings.finderOmitted([for (final i in match.omitted) _degreeName(i)]),
          ].join(' · '),
          onTap: () => context.push('/chords/${Uri.encodeComponent(chord.name)}'),
        );
      },
    );
  }
}

class _ScaleResults extends ConsumerWidget {
  const _ScaleResults({required this.pitchClasses, required this.tonic});

  final Set<int> pitchClasses;
  final int? tonic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scales = ref.watch(allScalesProvider).value;
    final modes = ref.watch(allModesProvider).value;
    if (scales == null || modes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final defs = <String, ScaleDefinition>{
      for (final s in [...scales, ...modes]) s.id: s,
    };
    if (pitchClasses.length < 2) return _Message(AppStrings.finderPickTwo);
    final matches = scalesFor(
      pitchClasses,
      scales: [for (final d in defs.values) (id: d.id, intervals: d.intervals)],
      tonic: tonic,
    );
    if (matches.isEmpty) return _Message(AppStrings.finderNoScale);
    return _ResultList(
      count: matches.length,
      builder: (i) {
        final match = matches[i];
        final def = defs[match.id]!;
        final extra = [
          for (final interval in def.intervals)
            if (!pitchClasses.contains((match.root + interval) % 12))
              pitchClassName(match.root + interval),
        ];
        return _ResultTile(
          title: '${pitchClassName(match.root)} '
              '${scaleDisplayName(def.id, def.intervals, fallback: def.name)}',
          subtitle: extra.isEmpty
              ? AppStrings.finderExact
              : AppStrings.finderAdds(extra.join(', ')),
          onTap: () => context.push(
            '/scales/${def.id}?root=${match.root}',
            extra: def,
          ),
        );
      },
    );
  }
}

/// Los resultados: los primeros [preview] y, si hay más, "Ver todas".
class _ResultList extends StatefulWidget {
  const _ResultList({required this.count, required this.builder});

  static const preview = 12;

  final int count;
  final Widget Function(int index) builder;

  @override
  State<_ResultList> createState() => _ResultListState();
}

class _ResultListState extends State<_ResultList> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final shown = _all ? widget.count : widget.count.clamp(0, _ResultList.preview);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.finderResults(widget.count),
          key: const Key('finder-count'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.palette.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < shown; i++)
          KeyedSubtree(key: Key('finder-result-$i'), child: widget.builder(i)),
        if (shown < widget.count)
          TextButton(
            key: const Key('finder-show-all'),
            onPressed: () => setState(() => _all = true),
            child: Text(AppStrings.finderShowAll(widget.count)),
          ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        key: const Key('finder-message'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
        ),
      );
}
