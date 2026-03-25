import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/navigation.dart';
import 'ui/theme.dart';

/// Root widget for ChordMaster Free.
class ChordMasterApp extends ConsumerWidget {
  /// Creates the [ChordMasterApp].
  const ChordMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
      title: 'ChordMaster Free',
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
}
