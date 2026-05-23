import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scaffold.dart';

/// Shared scaffold for feature modules outside the shell branches.
///
/// Provides a consistent app bar (with back button), end drawer, and global
/// bottom navigation so modules keep one navigation source of truth.
class FeatureModuleScaffold extends StatefulWidget {
  const FeatureModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.appBarBottom,
    this.backgroundColor,
    this.floatingActionButton,
    this.showBackButton = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final Color? appBarBackgroundColor;
  final Color? appBarForegroundColor;
  final PreferredSizeWidget? appBarBottom;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final bool showBackButton;

  @override
  State<FeatureModuleScaffold> createState() => _FeatureModuleScaffoldState();
}

class _FeatureModuleScaffoldState extends State<FeatureModuleScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndexFor(String location) {
    if (location == '/' || location.startsWith('/home')) return 0;
    if (location.startsWith('/chords')) return 1;
    if (location.startsWith('/tuner')) return 2;
    if (location.startsWith('/metronome')) return 3;
    return 4;
  }

  void _navigate(int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/chords');
      case 2:
        context.go('/tuner');
      case 3:
        context.go('/metronome');
      case 4:
        _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndexFor(location);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.appBarBackgroundColor,
        foregroundColor: widget.appBarForegroundColor,
        actions: widget.appBarActions,
        bottom: widget.appBarBottom,
        leading: widget.showBackButton
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      endDrawer: const AppEndDrawer(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _navigate,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Chords',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_outlined),
            selectedIcon: Icon(Icons.graphic_eq),
            label: 'Tuner',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Metronome',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
