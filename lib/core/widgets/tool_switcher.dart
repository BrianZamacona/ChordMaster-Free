import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';

enum AppTool { tuner, metronome }

/// Selector Afinador | Metrónomo bajo la `AppBar`. En la pestaña Afinar cambia
/// de ruta ahí; abierto sobre otra pantalla (Inicio, una lección) reemplaza esta
/// por la otra herramienta, así atrás sigue volviendo a donde se abrió.
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
            segments: [
              ButtonSegment(
                value: AppTool.tuner,
                icon: const Icon(Icons.graphic_eq),
                label: Text(AppStrings.toolTuner),
              ),
              ButtonSegment(
                value: AppTool.metronome,
                icon: const Icon(Icons.timer_outlined),
                label: Text(AppStrings.toolMetronome),
              ),
            ],
            selected: {current},
            onSelectionChanged: (s) => _open(context, s.first),
          ),
        ),
      );

  void _open(BuildContext context, AppTool tool) {
    final name = tool == AppTool.tuner ? 'tuner' : 'metronome';
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/tools/')) {
      context.go('/tools/$name');
    } else {
      context.pushReplacement(path.replaceFirst(RegExp(r'(tuner|metronome)$'), name));
    }
  }
}
