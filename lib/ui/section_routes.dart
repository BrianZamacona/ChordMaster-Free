import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Rutas de un módulo dentro de la pestaña en la que se está.
extension SectionRoutes on BuildContext {
  /// [path] (p. ej. `chords/C%20Major`) en la sección actual: `/learn/...`
  /// dentro de Aprender y `/...` dentro de Inicio.
  String sectionPath(String path) {
    final location =
        GoRouter.maybeOf(this)?.routerDelegate.currentConfiguration.uri.path ?? '/learn';
    return location == '/learn' || location.startsWith('/learn/')
        ? '/learn/$path'
        : '/$path';
  }
}
