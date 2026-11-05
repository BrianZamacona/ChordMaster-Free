import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/scale_names.dart';
import '../../../domain/theory/neck_notes.dart';
import '../../widgets/fretboard_diagram.dart';
import 'scale_detail_notifier.dart';
import 'widgets/pattern_selector.dart';

/// Solo el teléfono o la tableta giran a horizontal; web y escritorio no tienen
/// orientación que pedir.
@visibleForTesting
bool forcesLandscape({required TargetPlatform platform, required bool isWeb}) =>
    !isWeb &&
    (platform == TargetPlatform.android || platform == TargetPlatform.iOS);

/// Abre el mástil completo sobre toda la app, sin la barra de pestañas.
void openScaleFretboardFullscreen(BuildContext context, ScaleDetailArgs args) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ScaleFretboardFullscreen(args: args),
      ),
    );

/// Mástil completo de la escala. Comparte [scaleDetailProvider] con el detalle:
/// al cerrar, la digitación elegida sigue siendo la misma.
class ScaleFretboardFullscreen extends ConsumerStatefulWidget {
  const ScaleFretboardFullscreen({super.key, required this.args});

  final ScaleDetailArgs args;

  @override
  ConsumerState<ScaleFretboardFullscreen> createState() =>
      _ScaleFretboardFullscreenState();
}

class _ScaleFretboardFullscreenState
    extends ConsumerState<ScaleFretboardFullscreen> {
  /// Ancho desde el que los controles caben en la barra superior.
  static const _toolbarInlineWidth = 600.0;

  /// Parte de la barra superior que pueden ocupar los controles.
  static const _toolbarWidthShare = 0.72;

  var _label = FretboardLabel.interval;
  var _landscapeRequested = false;

  @override
  void initState() {
    super.initState();
    if (forcesLandscape(platform: defaultTargetPlatform, isWeb: kIsWeb)) {
      _landscapeRequested = true;
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// La app no fija ninguna orientación: la lista vacía devuelve la decisión al
  /// sistema, y respeta si la persona bloqueó la rotación.
  void _restoreOrientation() {
    if (!_landscapeRequested) return;
    _landscapeRequested = false;
    SystemChrome.setPreferredOrientations(const []);
  }

  @override
  void dispose() {
    _restoreOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = scaleDetailProvider(widget.args);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final selected = state.hasSelectedPattern ? state.currentPattern : null;
    final scale = widget.args.scale;
    final title =
        '${state.rootName} ${scaleDisplayName(scale.id, scale.intervals, fallback: scale.name)}';

    final systemPill = SystemSelectorPill(
      key: const Key('neck-system'),
      systems: scale.systems,
      selectedId: state.selectedSystemId,
      onChanged: notifier.changeSystem,
      maxLines: 1,
    );
    final patternPill = PatternSelectorPill(
      key: const Key('neck-pattern'),
      patterns: state.visiblePatterns,
      selectedIndex: state.hasSelectedPattern
          ? state.selectedPatternIndex
          : null,
      onSelected: notifier.selectPattern,
      maxLines: 1,
    );
    final labelToggle = SegmentedButton<FretboardLabel>(
      key: const Key('neck-label'),
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: FretboardLabel.interval,
          label: Text(AppStrings.neckIntervals),
        ),
        ButtonSegment(
          value: FretboardLabel.note,
          label: Text(AppStrings.neckNotes),
        ),
      ],
      selected: {_label},
      onSelectionChanged: (v) => setState(() => _label = v.first),
    );
    final screenWidth = MediaQuery.sizeOf(context).width;
    final inline = screenWidth >= _toolbarInlineWidth;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _restoreOrientation();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: inline
                  ? [
                      // Deja sitio al título: los botones se cortan con "…".
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * _toolbarWidthShare,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: systemPill),
                            const SizedBox(width: 8),
                            Flexible(child: patternPill),
                            const SizedBox(width: 8),
                            labelToggle,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ]
                  : null,
              bottom: inline
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(104),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: systemPill),
                                const SizedBox(width: 8),
                                Flexible(child: patternPill),
                              ],
                            ),
                            const SizedBox(height: 8),
                            labelToggle,
                          ],
                        ),
                      ),
                    ),
            ),
            body: SafeArea(
              top: false,
              child: FretboardNeck(
                key: const Key('scale-neck'),
                coordinates: scaleNotesOnNeck(
                  rootSemitone: state.rootSemitone,
                  intervals: scale.intervals,
                ),
                highlighted: selected == null
                    ? null
                    : patternAcrossNeck(selected.coordinates).toSet(),
                focus: selected == null
                    ? null
                    : (start: selected.startingFret, end: selected.endFret),
                label: _label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
