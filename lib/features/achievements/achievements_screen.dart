import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

/// Provider that loads all achievement unlock timestamps.
final _achievementsDataProvider =
    FutureProvider<Map<String, String?>>((ref) async {
  final storage = ref.read(storageServiceProvider);
  final result = <String, String?>{};
  for (final def in AchievementService.allAchievements) {
    final ts =
        await storage.get<String>(StorageService.achievementsBox, def.id);
    result[def.id] = ts;
  }
  return result;
});

/// Achievements screen showing all 10 achievements with lock/unlock status.
class AchievementsScreen extends ConsumerWidget {
  /// Creates the [AchievementsScreen].
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_achievementsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleAchievements)),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text(AppStrings.errorStorage)),
        data: (statuses) {
          final unlocked = statuses.values.where((v) => v != null).length;
          return Column(
            children: [
              _ProgressHeader(
                unlocked: unlocked,
                total: AchievementService.allAchievements.length,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: AchievementService.allAchievements.length,
                  itemBuilder: (context, i) {
                    final def = AchievementService.allAchievements[i];
                    final ts = statuses[def.id];
                    return _AchievementCard(definition: def, unlockedAt: ts);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.unlocked, required this.total});
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / $total Unlocked',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? unlocked / total : 0,
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard(
      {required this.definition, required this.unlockedAt});
  final AchievementDefinition definition;
  final String? unlockedAt;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = unlockedAt != null;
    final theme = Theme.of(context);
    String? dateLabel;
    if (isUnlocked) {
      try {
        final dt = DateTime.parse(unlockedAt!).toLocal();
        dateLabel =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        dateLabel = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  isUnlocked ? definition.emoji : '🔒',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    if (isUnlocked && dateLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '✅ Unlocked $dateLabel',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
