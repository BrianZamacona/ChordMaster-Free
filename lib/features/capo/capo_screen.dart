import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/chord_diagram.dart';
import '../../core/widgets/selector_pill.dart';
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
          const SizedBox(height: 8),
          Text(
            AppStrings.capoRule,
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
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
