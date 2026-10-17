import 'package:flutter/material.dart';

/// Scaffold de las pantallas de módulo dentro del shell.
///
/// La barra inferior la pone el shell (`AppScaffold`); aquí solo va la
/// `AppBar`, cuyo botón de atrás es el automático (vuelve a la pantalla
/// anterior de la pestaña).
class FeatureModuleScaffold extends StatelessWidget {
  const FeatureModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
    this.appBarBottom,
    this.backgroundColor,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final PreferredSizeWidget? appBarBottom;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(title),
          actions: appBarActions,
          bottom: appBarBottom,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
      );
}
