import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';

enum AppTool { tuner, metronome }

/// Selector Afinador | Metrónomo bajo la `AppBar` de la pestaña Herramientas.
class ToolSwitcher extends StatelessWidget implements PreferredSizeWidget {
  const ToolSwitcher({super.key, required this.current});

  final AppTool current;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppTool>(
            key: const Key('tool-switcher'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: AppTool.tuner,
                icon: Icon(Icons.graphic_eq),
                label: Text(AppStrings.toolTuner),
              ),
              ButtonSegment(
                value: AppTool.metronome,
                icon: Icon(Icons.timer_outlined),
                label: Text(AppStrings.toolMetronome),
              ),
            ],
            selected: {current},
            onSelectionChanged: (s) => context.go(
              s.first == AppTool.tuner ? '/tools/tuner' : '/tools/metronome',
            ),
          ),
        ),
      );
}
