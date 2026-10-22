import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_viewmodel.dart';
import '../../ui/theme.dart';
import '../constants/app_strings.dart';
import '../i18n/app_i18n.dart';

/// Shell de toda la app: la barra inferior está en todas las pantallas.
///
/// Cada pantalla pone su propio `Scaffold` con `AppBar`; el botón de atrás
/// es el automático de Flutter, que vuelve a la pantalla anterior real.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onIndexChange,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onIndexChange;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onIndexChange,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: AppStrings.tabHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: AppStrings.tabLearn,
            ),
            NavigationDestination(
              icon: const Icon(Icons.hearing_outlined),
              selectedIcon: const Icon(Icons.hearing),
              label: AppStrings.tabPractice,
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune),
              label: AppStrings.tabTools,
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: AppStrings.tabProgress,
            ),
          ],
        ),
      );
}

/// Ajustes de tema e idioma (antes en el menú lateral "Más").
class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final themeMode =
        ref.watch(settingsViewModelProvider.select((s) => s.themeMode));
    final localeCode =
        ref.watch(settingsViewModelProvider.select((s) => s.localeCode));
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: p.textSecondary),
            title: Text(AppStrings.darkMode),
            subtitle: Text(
              AppStrings.darkModeSubtitle,
              style: text.labelSmall?.copyWith(color: p.textSecondary),
            ),
            value: isDark,
            onChanged: (value) =>
                ref.read(settingsViewModelProvider.notifier).setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.system,
                    ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.language, color: p.textSecondary),
                const SizedBox(width: 16),
                Expanded(child: Text(AppStrings.language)),
                DropdownButton<String>(
                  value: localeCode,
                  underline: const SizedBox.shrink(),
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(settingsViewModelProvider.notifier)
                        .setLocaleCode(value);
                  },
                  items: [
                    for (final language in AppI18n.supportedLanguages)
                      DropdownMenuItem(
                        value: language.locale.languageCode,
                        child: Text(language.displayName),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
