import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class FileSender {
  static bool _stopFlag = false;

  static void stopAll() {
    _stopFlag = true;
  }

  // --------------------------------------------------------------------------
  // MAIN SEND FUNCTION
  // --------------------------------------------------------------------------
  static Future<void> sendFiles({
    required List<PlatformFile> files,
    required String ip,
    required int port,
    required Function(double) onProgress,
    required Function(String) onSpeed,
    required Function(String) onETA,
    required Function() onComplete,
  }) async {
    _stopFlag = false;

    // ------------------------------------------
    // 1. Handshake
    // ------------------------------------------
    final handshake = await _handshake(ip, port, files.length);

    if (!handshake["accepted"]) {
      print("Receiver rejected request.");
      return;
    }

    final requestId = handshake["requestId"];
    print("Handshake OK. Request ID = $requestId");

    // ------------------------------------------
    // 2. Calculate total bytes
    // ------------------------------------------
    final totalBytes = files.fold<int>(0, (sum, f) => sum + f.size);
    int globalSent = 0;

    final globalStopwatch = Stopwatch()..start();

    // ------------------------------------------
    // 3. Send each file
    // ------------------------------------------
    for (final file in files) {
      if (_stopFlag) return;

      final filePath = file.path!;
      final fileSize = file.size;

      final url = Uri.parse("http://$ip:$port/upload");
      final httpClient = HttpClient();
      final request = await httpClient.postUrl(url);

      // Headers
      request.headers.set("x-file-name", p.basename(file.name));
      request.headers.set("x-request-id", requestId);
      request.headers.set("Content-Length", fileSize.toString());

      final fileStream = File(filePath).openRead();

      await for (final chunk in fileStream) {
        if (_stopFlag) {
          httpClient.close(force: true);
          return;
        }

        request.add(chunk);

        globalSent += chunk.length;

        // ---- PROGRESS % ----
        double percent = (globalSent / totalBytes) * 100;
        onProgress(percent);

        // ---- SPEED ----
        final seconds = globalStopwatch.elapsedMilliseconds / 1000;
        double speedMB = (globalSent / (1024 * 1024)) / seconds;
        if (speedMB.isNaN || speedMB.isInfinite) speedMB = 0;
        onSpeed("${speedMB.toStringAsFixed(2)} MB/s");

        // ---- ETA ----
        final remaining = totalBytes - globalSent;
        final secondsLeft =
            speedMB > 0 ? (remaining / (1024 * 1024)) / speedMB : 0;
        onETA("${secondsLeft.toStringAsFixed(0)}s remaining");
      }

      // Close request
      final response = await request.close();
      final respText = await response.transform(utf8.decoder).join();
      print("UPLOAD RESP: $respText");

      httpClient.close();
    }

    // ------------------------------
    // COMPLETE
    // ------------------------------
    onProgress(100);
    onSpeed("0 MB/s");
    onETA("Completed");
    onComplete();
  }

  // --------------------------------------------------------------------------
  // HANDSHAKE
  // --------------------------------------------------------------------------
  static Future<Map<String, dynamic>> _handshake(
      String ip, int port, int fileCount) async {
    try {
      final url = Uri.parse("http://$ip:$port/handshake");
      final client = HttpClient();
      final request = await client.postUrl(url);

      request.headers.contentType = ContentType.json;

      request.write(jsonEncode({
        "deviceName": Platform.localHostname,
        "fileCount": fileCount,
      }));

      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();

      client.close();

      final json = jsonDecode(text);
      return {
        "accepted": json["accepted"] == true,
        "requestId": json["requestId"] ?? "",
      };
    } catch (e) {
      print("HANDSHAKE ERROR: $e");
      return {"accepted": false, "requestId": ""};
    }
  }
}
