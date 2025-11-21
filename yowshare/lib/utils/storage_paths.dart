import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StoragePaths {
  static Future<Directory> getDownloadFolder() async {
    Directory? dir;

    if (Platform.isAndroid || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dir = Directory("/storage/emulated/0/Download/YowShare");

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return dir;
    }

    // iOS fallback
    final appDir = await getApplicationDocumentsDirectory();
    final iosDir = Directory("${appDir.path}/Downloads");
    if (!iosDir.existsSync()) iosDir.createSync();
    return iosDir;
  }
}
