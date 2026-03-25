import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_strings.dart';

/// A button that opens the ChordMaster Free Ko-fi donation page.
///
/// Renders as an [OutlinedButton] with an amber heart icon so it is visually
/// distinct from primary-action buttons.
///
/// Example:
/// ```dart
/// const DonationButton()
/// ```
class DonationButton extends StatelessWidget {
  /// Creates a [DonationButton].
  const DonationButton({super.key});

  static final Uri _kofiUri = Uri.parse('https://ko-fi.com/chordmasterfree');

  Future<void> _launch() async {
    try {
      final launched = await launchUrl(
        _kofiUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('DonationButton: launchUrl returned false for $_kofiUri');
      }
    } catch (e, st) {
      debugPrint('DonationButton: failed to launch url – $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
      onPressed: _launch,
      icon: const Icon(Icons.favorite, color: Colors.amber),
      label: const Text(AppStrings.supportApp),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amber,
        side: const BorderSide(color: Colors.amber),
      ),
    );
}
