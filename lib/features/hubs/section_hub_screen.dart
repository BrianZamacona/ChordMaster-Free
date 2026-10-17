import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/theme.dart';

/// Un destino dentro de una sección (p. ej. Acordes dentro de Aprender).
class HubEntry {
  const HubEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;

  /// Qué se aprende o practica ahí, en una línea.
  final String subtitle;
  final String route;
}

/// Pantalla raíz de una pestaña: una frase de qué hay en la sección y la
/// lista de destinos. [footer] permite añadir contenido propio (ajustes).
class SectionHubScreen extends StatelessWidget {
  const SectionHubScreen({
    super.key,
    required this.title,
    required this.intro,
    required this.entries,
    this.footer = const [],
  });

  final String title;
  final String intro;
  final List<HubEntry> entries;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(intro, style: text.bodyLarge?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 16),
          for (final entry in entries) ...[
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: Key('hub-${entry.route}'),
                onTap: () => context.go(entry.route),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(entry.icon, color: p.accent),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.title, style: text.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              entry.subtitle,
                              style: text.bodyMedium
                                  ?.copyWith(color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: p.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...footer,
        ],
      ),
    );
  }
}
