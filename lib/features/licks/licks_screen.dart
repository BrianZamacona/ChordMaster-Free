import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/guides/guides.dart';
import '../../domain/licks/lick.dart';
import '../../domain/licks/licks.dart';
import '../../ui/section_routes.dart';
import '../../ui/theme.dart';
import 'lick_texts.dart';
import 'licks_viewmodel.dart';

/// La biblioteca de licks y riffs: una sección por estilo (nombre y cómo
/// suena) con sus frases en lista, a todo lo ancho. Se filtra por nivel y
/// por tipo; los estilos que quedan vacíos se ocultan.
class LicksScreen extends ConsumerStatefulWidget {
  const LicksScreen({super.key});

  @override
  ConsumerState<LicksScreen> createState() => _LicksScreenState();
}

class _LicksScreenState extends ConsumerState<LicksScreen> {
  GuideLevel? _level;
  LickKind? _kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final records = ref.watch(licksViewModelProvider.select((s) => s.records));
    final sections = [
      for (final style in LickStyle.values)
        (
          style,
          [
            for (final l in licks)
              if (l.style == style &&
                  (_level == null || l.level == _level) &&
                  (_kind == null || l.kind == _kind))
                l,
          ],
        ),
    ].where((s) => s.$2.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.moduleLicks)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(AppStrings.licksIntro, style: text.bodyMedium?.copyWith(color: p.textSecondary)),
          const SizedBox(height: 12),
          _Filters<GuideLevel>(
            key: const Key('licks-levels'),
            label: AppStrings.guidesLevel,
            values: GuideLevel.values,
            nameOf: (l) => guideLevelTitle(l).text,
            selected: _level,
            keyOf: (l) => 'licks-level-${l?.name ?? 'all'}',
            onChanged: (l) => setState(() => _level = l),
          ),
          const SizedBox(height: 4),
          _Filters<LickKind>(
            key: const Key('licks-kinds'),
            label: AppStrings.licksKind,
            values: LickKind.values,
            nameOf: lickKindLabel,
            selected: _kind,
            keyOf: (k) => 'licks-kind-${k?.name ?? 'all'}',
            onChanged: (k) => setState(() => _kind = k),
          ),
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(AppStrings.licksNoResults, key: const Key('licks-empty')),
            ),
          for (final (style, items) in sections) ...[
            const SizedBox(height: 20),
            Text(
              lickStyleInfo(style).title.text,
              key: Key('licks-style-${style.name}'),
              style: text.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              lickStyleInfo(style).summary.text,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: 8),
            for (final l in items) _LickCard(lick: l, record: records[l.id]),
          ],
        ],
      ),
    );
  }
}

/// "Nivel: Todos · Principiante …" como chips; `null` = todos.
class _Filters<T> extends StatelessWidget {
  const _Filters({
    super.key,
    required this.label,
    required this.values,
    required this.nameOf,
    required this.selected,
    required this.keyOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final String Function(T) nameOf;
  final T? selected;
  final String Function(T?) keyOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      ChoiceChip(
        key: Key(keyOf(null)),
        label: Text(AppStrings.guidesAllLevels),
        selected: selected == null,
        onSelected: (_) => onChanged(null),
      ),
      for (final v in values)
        ChoiceChip(
          key: Key(keyOf(v)),
          label: Text(nameOf(v)),
          selected: selected == v,
          onSelected: (_) => onChanged(v),
        ),
    ],
  );
}

class _LickCard extends StatelessWidget {
  const _LickCard({required this.lick, required this.record});

  final Lick lick;
  final int? record;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final record = this.record;
    return Card(
      key: Key('lick-${lick.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(context.sectionPath('licks/${lick.id}')),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lick.title.text, style: text.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${lickKindLabel(lick.kind)} · ${guideLevelTitle(lick.level).text} · '
                      '${lickScaleLabel(lick.scale)}',
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                    if (lick.techniques.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lick.techniques.map(techniqueLabel).join(' · '),
                        style: musicMono(fontSize: 12, color: p.accent),
                      ),
                    ],
                    if (record != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.techniqueRecord(record),
                        style: musicMono(fontSize: 12, color: p.success),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
