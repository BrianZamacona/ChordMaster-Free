import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Utility helpers for requesting and checking runtime permissions.
class PermissionUtils {
  PermissionUtils._();

  /// Requests microphone permission from the OS.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await ph.Permission.microphone.request();
      return status.isGranted;
    } catch (e, st) {
      debugPrint('PermissionUtils.requestMicrophonePermission error: $e\n$st');
      return false;
    }
  }

  /// Checks the current microphone permission status without prompting.
  ///
  /// Returns `true` if permission is already granted, `false` otherwise.
  static Future<bool> checkMicrophonePermission() async {
    try {
      final status = await ph.Permission.microphone.status;
      return status.isGranted;
    } catch (e, st) {
      debugPrint('PermissionUtils.checkMicrophonePermission error: $e\n$st');
      return false;
    }
  }

  /// Opens the operating-system app settings page for ChordMaster Free.
  ///
  /// Useful when a permission has been permanently denied and the user must
  /// manually enable it in the OS settings.
  static Future<void> openAppSettings() async {
    try {
      await ph.openAppSettings();
    } catch (e, st) {
      debugPrint('PermissionUtils.openAppSettings error: $e\n$st');
    }
  }
}
