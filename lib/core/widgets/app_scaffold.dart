import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/settings_viewmodel.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// The root scaffold for all shell-route screens.
///
/// Provides a consistent [AppBar], a [NavigationBar] with five destinations
/// (Home, Chords, Tuner, Metronome, More), and an [endDrawer] that exposes
/// the remaining feature modules.
///
/// For the four primary tabs the scaffold delegates navigation to
/// [onIndexChange] (typically [StatefulNavigationShell.goBranch]); when
/// [onIndexChange] is `null` it falls back to [GoRouter.go].
///
/// The "More" tab (index 4) opens the end drawer via the internal
/// [GlobalKey<ScaffoldState>] — it does not correspond to a shell branch.
class AppScaffold extends StatefulWidget {
  /// Creates an [AppScaffold].
  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.onIndexChange,
  });

  /// The main content area.
  final Widget body;

  /// The currently selected navigation index (0–3 for shell tabs, 4 for More).
  final int currentIndex;

  /// AppBar title. Defaults to [AppStrings.appName] when `null`.
  final String? title;

  /// Optional AppBar action widgets.
  final List<Widget>? actions;

  /// Optional [FloatingActionButton].
  final Widget? floatingActionButton;

  /// Called when a navigation destination is tapped.
  ///
  /// When `null`, tapping a destination calls [GoRouter.go] with the
  /// associated route.  Index 4 always opens the end drawer regardless.
  final void Function(int)? onIndexChange;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<String> _tabRoutes = [
    '/',
    '/chords',
    '/tuner',
    '/metronome',
  ];

  void _onDestinationTapped(int index) {
    if (index == 4) {
      _scaffoldKey.currentState?.openEndDrawer();
      return;
    }
    if (widget.onIndexChange != null) {
      widget.onIndexChange!(index);
    } else {
      context.go(_tabRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: _scaffoldKey,
        body: widget.body,
        floatingActionButton: widget.floatingActionButton,
        endDrawer: const AppEndDrawer(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.currentIndex.clamp(0, 3),
          onDestinationSelected: _onDestinationTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music),
              label: AppStrings.moduleChords,
            ),
            NavigationDestination(
              icon: Icon(Icons.graphic_eq_outlined),
              selectedIcon: Icon(Icons.graphic_eq),
              label: AppStrings.moduleTuner,
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: AppStrings.moduleMetronome,
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      );
}

/// The end drawer that exposes the remaining feature modules.
class AppEndDrawer extends ConsumerWidget {
  const AppEndDrawer({super.key});

  static const List<_DrawerSection> _sections = [
    _DrawerSection(
      title: 'Practice',
      items: [
        _DrawerItem(
          label: AppStrings.moduleScales,
          icon: Icons.music_video,
          route: '/scales',
        ),
        _DrawerItem(
          label: AppStrings.moduleProgressions,
          icon: Icons.queue_music,
          route: '/progressions',
        ),
        _DrawerItem(
          label: AppStrings.moduleEarTraining,
          icon: Icons.hearing,
          route: '/ear-training',
        ),
        _DrawerItem(
          label: AppStrings.moduleRhythmGame,
          icon: Icons.sports_esports,
          route: '/rhythm-game',
        ),
        _DrawerItem(
          label: AppStrings.moduleImprovisation,
          icon: Icons.piano,
          route: '/improvisation',
        ),
      ],
    ),
    _DrawerSection(
      title: 'Create & Track',
      items: [
        _DrawerItem(
          label: AppStrings.moduleSongs,
          icon: Icons.music_note,
          route: '/songs',
        ),
        _DrawerItem(
          label: AppStrings.moduleComposition,
          icon: Icons.edit_note,
          route: '/composition',
        ),
        _DrawerItem(
          label: AppStrings.moduleHealth,
          icon: Icons.health_and_safety,
          route: '/health',
        ),
        _DrawerItem(
          label: AppStrings.moduleCommunity,
          icon: Icons.people,
          route: '/community',
        ),
        _DrawerItem(
          label: AppStrings.moduleAchievements,
          icon: Icons.emoji_events,
          route: '/achievements',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final location = GoRouterState.of(context).matchedLocation;
    final themeMode =
        ref.watch(settingsViewModelProvider.select((s) => s.themeMode));
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Drawer(
      backgroundColor: scheme.surfaceContainerLow,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            DrawerHeader(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, scheme.surfaceContainerHigh],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: textTheme.titleLarge?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.appTagline,
                      style: textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimary.withAlpha(220),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            ..._sections.expand(
              (section) => [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                  child: Text(
                    section.title,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: section.items
                        .map((item) => _DrawerItemTile(
                              item: item,
                              isSelected: location == item.route ||
                                  location.startsWith('${item.route}/'),
                            ))
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: SwitchListTile(
                secondary: Icon(Icons.dark_mode_outlined,
                    color: scheme.onSurfaceVariant),
                title: Text(
                  AppStrings.darkMode,
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
                subtitle: Text(
                  'Auto/Manual',
                  style: textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                value: isDark,
                activeThumbColor: scheme.primary,
                onChanged: (value) {
                  ref.read(settingsViewModelProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.system,
                      );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data holder for a single end-drawer list tile.
class _DrawerItem {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class _DrawerSection {
  const _DrawerSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_DrawerItem> items;
}

class _DrawerItemTile extends StatelessWidget {
  const _DrawerItemTile({
    required this.item,
    required this.isSelected,
  });

  final _DrawerItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: Icon(
        item.icon,
        color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        item.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? scheme.primary : scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
      onTap: () {
        Navigator.pop(context);
        context.go(item.route);
      },
    );
  }
}
