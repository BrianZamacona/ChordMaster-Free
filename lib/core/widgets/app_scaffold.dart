import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      appBar: AppBar(
        title: Text(widget.title ?? AppStrings.appName),
        actions: widget.actions,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      endDrawer: _AppEndDrawer(scaffoldKey: _scaffoldKey),
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
class _AppEndDrawer extends StatelessWidget {
  const _AppEndDrawer({required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  static const List<_DrawerItem> _items = [
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
    _DrawerItem(
      label: AppStrings.moduleScales,
      icon: Icons.music_video,
      route: '/scales',
    ),
  ];

  @override
  Widget build(BuildContext context) => Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.appTagline,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ..._items.map(
              (item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(context);
                  context.go(item.route);
                },
              ),
            ),
          ],
        ),
      ),
    );
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
