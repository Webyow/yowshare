import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class Permissions {
  static Future<bool> requestAll() async {
    bool allGranted = true;

    // -----------------------------
    // WINDOWS / LINUX / MACOS
    // -----------------------------
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop OS does not need runtime permissions
        return true;
      }
    } catch (_) {
      // Web throws UnsupportedError for Platform.*
      return true;
    }

    // -----------------------------
    // ANDROID
    // -----------------------------
    if (Platform.isAndroid) {
      // Notifications (Android 13+)
      await _safeRequest(Permission.notification);

      // Storage (Android 12 and older)
      await _safeRequest(Permission.storage);

      // Android 13+ granular media permissions
      await _safeRequest(Permission.photos);
      await _safeRequest(Permission.videos);
      await _safeRequest(Permission.audio);

      // Optional (location usage in WiFi device discovery)
      await _safeRequest(Permission.location);
    }

    // -----------------------------
    // iOS / iPadOS
    // -----------------------------
    if (Platform.isIOS) {
      await _safeRequest(Permission.photos);
      await _safeRequest(Permission.notification);
    }

    return allGranted;
  }

  // Helper function to safely request
  static Future<void> _safeRequest(Permission perm) async {
    try {
      await perm.request();
    } catch (_) {
      // Ignore unsupported permissions — prevents crashes
    }
  }
}
