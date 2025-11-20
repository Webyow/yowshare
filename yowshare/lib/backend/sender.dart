import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class Sender {
  static const int port = 9753;

  static final StreamController<double> progressStream =
      StreamController.broadcast();
  static final StreamController<String> speedStream =
      StreamController.broadcast();
  static final StreamController<String> etaStream =
      StreamController.broadcast();

  static bool stopFlag = false;

  // ----------------------------------------------------------
  // MAIN SEND FUNCTION
  // ----------------------------------------------------------
  static Future<bool> sendFiles({
    required String receiverIP,
    required List<PlatformFile> files,
  }) async {
    stopFlag = false;

    // Step 1: Handshake
    final handshake = await _handshake(receiverIP, files.length);

    if (!handshake["accepted"]) {
      print("Receiver rejected.");
      return false;
    }

    final String requestId = handshake["requestId"];
    print("Handshake OK → requestId: $requestId");

    // Step 2: Calculate total size
    final int totalBytes =
        files.fold(0, (sum, file) => sum + file.size);

    int sentBytes = 0;
    final Stopwatch stopwatch = Stopwatch()..start();

    // Step 3: Upload each file
    for (final file in files) {
      if (stopFlag) return false;

      final String filePath = file.path!;
      final int fileSize = file.size;

      final int result = await _uploadFile(
        receiverIP: receiverIP,
        filePath: filePath,
        fileName: file.name,
        fileSize: fileSize,
        requestId: requestId,
        onChunk: (chunkSize) {
          sentBytes += chunkSize;

          // Progress %
          double progress = (sentBytes / totalBytes) * 100;
          progressStream.add(progress);

          // Speed
          double seconds = stopwatch.elapsedMilliseconds / 1000;
          double speedMB = (sentBytes / (1024 * 1024)) / seconds;
          speedStream.add("${speedMB.toStringAsFixed(2)} MB/s");

          // ETA
          final int remaining = totalBytes - sentBytes;
          double remainingSec =
              speedMB > 0 ? (remaining / (1024 * 1024)) / speedMB : 0;
          etaStream.add("${remainingSec.toStringAsFixed(0)}s remaining");
        },
      );

      if (result != 200) return false;
    }

    // Completed
    progressStream.add(100);
    speedStream.add("0 MB/s");
    etaStream.add("Completed");

    return true;
  }

  // ----------------------------------------------------------
  // HANDSHAKE
  // ----------------------------------------------------------
  static Future<Map<String, dynamic>> _handshake(
      String receiverIP, int fileCount) async {
    try {
      final url = Uri.parse("http://$receiverIP:$port/handshake");
      final client = HttpClient();

      final req = await client.postUrl(url);

      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        "deviceName": Platform.localHostname,
        "fileCount": fileCount,
      }));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      client.close();

      final json = jsonDecode(body);
      return {
        "accepted": json["accepted"] ?? false,
        "requestId": json["requestId"] ?? "",
      };
    } catch (e) {
      print("Handshake Error → $e");
      return {"accepted": false, "requestId": ""};
    }
  }

  // ----------------------------------------------------------
  // UPLOAD SINGLE FILE
  // ----------------------------------------------------------
  static Future<int> _uploadFile({
    required String receiverIP,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String requestId,
    required Function(int) onChunk,
  }) async {
    try {
      final url = Uri.parse("http://$receiverIP:$port/upload");
      final client = HttpClient();
      final req = await client.postUrl(url);

      req.headers.set("x-file-name", p.basename(fileName));
      req.headers.set("x-request-id", requestId);
      req.headers.set("Content-Length", fileSize.toString());

      final file = File(filePath).openRead();

      await for (final chunk in file) {
        if (stopFlag) {
          client.close(force: true);
          return 499; // Aborted
        }

        req.add(chunk);
        onChunk(chunk.length);
      }

      final res = await req.close();
      final status = res.statusCode;

      client.close();
      return status;
    } catch (e) {
      print("Upload Error → $e");
      return 500;
    }
  }

  static void stop() {
    stopFlag = true;
  }
}
