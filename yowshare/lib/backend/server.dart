import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class IncomingRequest {
  final String deviceName;
  final int fileCount;
  final String requestId;
  final String senderIP;

  IncomingRequest(this.deviceName, this.fileCount, this.requestId, this.senderIP);
}

class LocalServer {
  static const int port = 9753;

  static HttpServer? _httpServer;
  static ServerSocket? _helloSocket;

  static final StreamController<IncomingRequest> incomingRequests =
      StreamController.broadcast();
  static final StreamController<double> progressStream =
      StreamController.broadcast();

  static final Map<String, Completer<bool>> requestApprovals = {};

  // ---------------------------------------------------
  // START BOTH SERVERS
  // ---------------------------------------------------
  static Future<void> start() async {
    await _startHelloServer();
    await _startHttpServer();
  }

  // ---------------------------------------------------
  // HELLO SERVER (For discovery ping)
  // ---------------------------------------------------
  static Future<void> _startHelloServer() async {
    try {
      _helloSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

      _helloSocket!.listen((client) async {
        try {
          final data = await client.first;
          final msg = utf8.decode(data).trim();

          if (msg == "HELLO") {
            final name = Platform.localHostname;
            client.write("YOWSHARE:$name\n");
            await client.flush();
          }
        } catch (_) {}
        client.destroy();
      });
    } catch (e) {
      print("HELLO SERVER ERROR: $e");
    }
  }

  // ---------------------------------------------------
  // HTTP SERVER (Handshake + Upload)
  // ---------------------------------------------------
  static Future<void> _startHttpServer() async {
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);

      _httpServer!.listen((HttpRequest req) async {
        final path = req.uri.path;

        if (path == "/handshake") {
          return _handleHandshake(req);
        }

        if (path == "/upload") {
          return _handleUpload(req);
        }

        req.response.statusCode = 404;
        await req.response.close();
      });
    } catch (e) {
      print("HTTP SERVER ERROR: $e");
    }
  }

  // ---------------------------------------------------
  // HANDSHAKE
  // ---------------------------------------------------
  static Future<void> _handleHandshake(HttpRequest req) async {
    try {
      final body = await utf8.decoder.bind(req).join();
      final json = jsonDecode(body);

      final deviceName = json["deviceName"];
      final fileCount = json["fileCount"];
      final senderIP = req.connectionInfo?.remoteAddress.address ?? "unknown";

      final requestId = DateTime.now().microsecondsSinceEpoch.toString();

      final request = IncomingRequest(
        deviceName,
        fileCount,
        requestId,
        senderIP,
      );

      final completer = Completer<bool>();
      requestApprovals[requestId] = completer;

      // Notify the UI
      incomingRequests.add(request);

      // Wait until UI accepts/rejects
      final approved = await completer.future;

      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({
        "accepted": approved,
        "requestId": requestId,
      }));

      await req.response.close();
    } catch (e) {
      print("HANDSHAKE ERROR: $e");
    }
  }

  // Called by UI
  static void accept(IncomingRequest req) {
    requestApprovals[req.requestId]?.complete(true);
  }

  static void reject(IncomingRequest req) {
    requestApprovals[req.requestId]?.complete(false);
  }

  // ---------------------------------------------------
  // FILE UPLOAD
  // ---------------------------------------------------
  static Future<void> _handleUpload(HttpRequest req) async {
    try {
      final fileName = req.headers.value("x-file-name") ?? "file.bin";
      final contentLength = req.headers.contentLength;

      final savePath = await _getSavePath(fileName);
      final file = File(savePath).openWrite();

      int received = 0;

      await for (var chunk in req) {
        received += chunk.length;
        file.add(chunk);

        if (contentLength > 0) {
          double progress = (received / contentLength) * 100;
          progressStream.add(progress);
        }
      }

      await file.close();

      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({"status": "ok", "path": savePath}));
      await req.response.close();
    } catch (e) {
      print("UPLOAD ERROR: $e");
    }
  }

  // ---------------------------------------------------
  // SAVE PATH (Downloads folder)
  // ---------------------------------------------------
  static Future<String> _getSavePath(String name) async {
    Directory dir;

    if (Platform.isWindows) {
      dir = Directory("${Platform.environment['USERPROFILE']}\\Downloads");
    } else {
      dir = Directory("${Platform.environment['HOME']}/Downloads");
    }

    if (!dir.existsSync()) dir.createSync(recursive: true);

    return p.join(dir.path, "YOWShare_$name");
  }
}
