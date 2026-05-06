import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/settings/settings_viewmodel.dart';
import 'ui/navigation.dart';
import 'ui/theme.dart';

/// Root widget for ChordMaster Free.
class ChordMasterApp extends ConsumerWidget {
  /// Creates the [ChordMasterApp].
  const ChordMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsViewModelProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'ChordMaster Free',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      // OWASP A05: warn when running in web (unencrypted storage).
      builder: kIsWeb
          ? (context, child) => _WebStorageWarningBanner(child: child!)
          : null,
    );
  }
}

/// Banner shown on web to inform users that storage is not encrypted.
///
/// On native platforms the app uses AES-encrypted Hive boxes backed by
/// [FlutterSecureStorage].  The web platform cannot support this, so data
/// is stored unencrypted in IndexedDB.  This banner makes that limitation
/// visible to users (OWASP A05 — Security Misconfiguration).
class _WebStorageWarningBanner extends StatefulWidget {
  const _WebStorageWarningBanner({required this.child});
  final Widget child;

  @override
  State<_WebStorageWarningBanner> createState() =>
      _WebStorageWarningBannerState();
}

class _WebStorageWarningBannerState extends State<_WebStorageWarningBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return widget.child;
    return Column(
      children: [
        Material(
          color: const Color(0xFFF39C12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.black87),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Running on web: data is stored unencrypted in your browser.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, size: 16, color: Colors.black87),
                    onPressed: () => setState(() => _dismissed = true),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

