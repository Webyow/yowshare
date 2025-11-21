import 'dart:io';

class PlatformHelper {
  static bool supportsMdns() {
    // mDNS works on: Android, iOS, macOS, Linux
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux;
  }
}
