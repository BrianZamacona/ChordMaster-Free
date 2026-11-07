import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/selector_pill.dart';
import '../../domain/progressions/progression_data.dart';
import '../../domain/theory/capo.dart';
import '../../domain/theory/notes.dart';
import '../../ui/theme.dart';
import '../chords/chord_viewmodel.dart';

/// "¿Qué capo uso?": eliges la tonalidad que quieres que suene y ves en qué
/// traste poner el capo con cada forma abierta, con su I – IV – V.
class CapoScreen extends StatefulWidget {
  const CapoScreen({super.key});

  @override
  State<CapoScreen> createState() => _CapoScreenState();
}

class _CapoScreenState extends State<CapoScreen> {
  var _key = noteIndex('A');
  var _minor = false;
  var _progression = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final options = capoOptions(_key, minor: _minor);
    final keyName = '${pitchClassName(_key)}${_minor ? 'm' : ''}';
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.capoTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.capoIntro,
            style: text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SelectorPill(
                key: const Key('capo-key'),
                label: AppStrings.capoKey,
                value: pitchClassName(_key),
                onOpen: () => showNotePicker(
                  context,
                  title: AppStrings.capoKey,
                  selected: pitchClassName(_key),
                  onPicked: (note) {
                    if (note != null) setState(() => _key = noteIndex(note));
                  },
                ),
              ),
              SegmentedButton<bool>(
                key: const Key('capo-mode'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(AppStrings.capoMajor)),
                  ButtonSegment(value: true, label: Text(AppStrings.capoMinor)),
                ],
                selected: {_minor},
                onSelectionChanged: (v) => setState(() => _minor = v.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.capoResults(keyName),
            key: const Key('capo-summary'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final o in options) _CapoOptionCard(option: o),
          // Las progresiones son de la tonalidad mayor.
          if (!_minor) ...[
            const SizedBox(height: 16),
            _TurnProgression(
              keyName: keyName,
              keyRoot: _key,
              options: options,
              progression: progressions[_progression],
              onPick: () => _pickProgression(context),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            AppStrings.capoRule,
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }

  void _pickProgression(BuildContext context) => showSelectorSheet(
        context,
        title: AppStrings.capoProgression,
        builder: (sheet) => Column(
          children: [
            for (final (i, p) in progressions.indexed)
              ListTile(
                key: Key('capo-progression-${p.id}'),
                title: Text(p.label, style: musicMono(fontSize: 14)),
                trailing: i == _progression
                    ? Icon(Icons.check, color: sheet.palette.accent)
                    : null,
                onTap: () {
                  setState(() => _progression = i);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      );
}

/// Una progresión de la tonalidad elegida y, por cada capo, qué acordes arma
/// la mano y cómo suenan.
class _TurnProgression extends StatelessWidget {
  const _TurnProgression({
    required this.keyName,
    required this.keyRoot,
    required this.options,
    required this.progression,
    required this.onPick,
  });

  final String keyName;
  final int keyRoot;
  final List<CapoOption> options;
  final Progression progression;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final degrees = [
      for (final d in progression.degrees) (semitones: d.semitones, type: d.type),
    ];
    return Card(
      key: const Key('capo-turn'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.capoTurnTitle, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              AppStrings.capoTurnIntro(keyName),
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 10),
            SelectorPill(
              key: const Key('capo-progression'),
              label: AppStrings.capoProgression,
              value: progression.label,
              onOpen: onPick,
            ),
            const SizedBox(height: 10),
            Text(
              AppStrings.capoTurnInKey(
                keyName,
                chordsInKey(degrees, keyRoot).join(' – '),
              ),
              key: const Key('capo-turn-target'),
              style: musicMono(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            for (final o in options) ...[
              const Divider(height: 20),
              Text(
                o.fret == 0 ? AppStrings.capoNone(o.shape) : AppStrings.capoAt(o.fret, o.shape),
                style: text.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(
                capoTransposition(degrees, o).shapes.join(' – '),
                key: Key('capo-turn-${o.shape}'),
                style: musicMono(fontSize: 14, fontWeight: FontWeight.w600, color: p.accent),
              ),
              Text(
                AppStrings.capoSounds(capoTransposition(degrees, o).sounds.join(' – ')),
                style: musicMono(fontSize: 12, color: p.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapoOptionCard extends ConsumerWidget {
  const _CapoOptionCard({required this.option});

  final CapoOption option;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    // Reconstruye al terminar de cargar la biblioteca.
    ref.watch(chordViewModelProvider.select((s) => s.allChords.length));
    final vm = ref.read(chordViewModelProvider.notifier);
    return Card(
      key: Key('capo-option-${option.shape}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.fret == 0
                  ? AppStrings.capoNone(option.shape)
                  : AppStrings.capoAt(option.fret, option.shape),
              style: text.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in capoProgression(option.shape, option.fret))
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final chord = vm.findByName(c.shape);
                      if (chord != null) {
                        context.push(
                          '/learn/chords/${Uri.encodeComponent(chord.name)}',
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          if (vm.findByName(c.shape) case final chord?)
                            ChordDiagramWidget(
                              chordName: chord.name,
                              fretPositions: chord.fretPositions,
                              fingerPositions: chord.fingerPositions,
                              root: chord.root,
                              baseFret: chord.baseFret,
                              size: 72,
                              showChordName: false,
                            ),
                          Text(c.shape, style: text.titleSmall),
                          Text(
                            AppStrings.capoSounds(c.sounds),
                            style: musicMono(fontSize: 12, color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
