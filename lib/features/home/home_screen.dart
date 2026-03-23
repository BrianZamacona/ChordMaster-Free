import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/donation_button.dart';

/// Home screen showing the app tagline and a donation button.
///
/// This widget does not include a [Scaffold] — the shell route provides one.
class HomeScreen extends StatelessWidget {
  /// Creates the [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.appTagline,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const DonationButton(),
        ],
      ),
    );
  }
}
