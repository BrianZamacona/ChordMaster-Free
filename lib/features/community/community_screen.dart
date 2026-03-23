import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Community feed screen.
class CommunityScreen extends StatelessWidget {
  /// Creates the [CommunityScreen].
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.moduleCommunity)),
      body: Center(
        child: Text(
          AppStrings.moduleCommunity,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
