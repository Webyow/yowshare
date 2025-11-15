import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class SenderInfo {
  final String ip;
  final String deviceName;
  final int fileCount;
  final String requestId;

  SenderInfo(this.ip, this.deviceName, this.fileCount, this.requestId);
}

class LocalServer {
  static HttpServer? _server;

  static final StreamController<SenderInfo> _incomingRequestController =
      StreamController.broadcast();
  static Stream<SenderInfo> get onIncomingRequest =>
      _incomingRequestController.stream;

  static final Map<String, Completer<bool>> _pendingRequests = {};

  static final StreamController<double> _progressController =
      StreamController.broadcast();
  static Stream<double> get onProgress => _progressController.stream;

  // --------------------------------------------------------------------------
  // START SERVER
  // --------------------------------------------------------------------------
  static Future<void> start({int port = 8888}) async {
    if (_server != null) return;

    // Web cannot run HttpServer
    if (!_isServerSupported) {
      print("LocalServer disabled on this platform");
      return;
    }

    try {
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );

      print("Local server running on port $port");

      _server!.listen(
        (HttpRequest req) {
          if (req.uri.path == "/handshake") {
            _handleHandshake(req);
          } else if (req.uri.path == "/upload") {
            _handleUpload(req);
          } else {
            req.response.statusCode = 404;
            req.response.close();
          }
        },
        onError: (e) => print("SERVER ERROR: $e"),
      );
    } catch (e) {
      print("LocalServer failed to start: $e");
    }
  }

  static Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
  }

  // --------------------------------------------------------------------------
  // HANDSHAKE
  // --------------------------------------------------------------------------
  static void _handleHandshake(HttpRequest req) async {
    try {
      final senderIp = req.connectionInfo?.remoteAddress.address ?? "unknown";

      final bodyData = await utf8.decoder.bind(req).join();
      final body = jsonDecode(bodyData);

      final senderName = body["deviceName"] ?? "Unknown Device";
      final fileCount = body["fileCount"] ?? 0;

      final requestId = DateTime.now().microsecondsSinceEpoch.toString();

      final info = SenderInfo(senderIp, senderName, fileCount, requestId);

      final completer = Completer<bool>();
      _pendingRequests[requestId] = completer;

      // Notify UI
      _incomingRequestController.add(info);

      final allowed = await completer.future;

      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({"accepted": allowed, "requestId": requestId}));
      await req.response.close();
    } catch (e) {
      print("HANDSHAKE ERROR: $e");
      _safeClose(req);
    }
  }

  // UI triggers
  static void acceptRequest(SenderInfo info) {
    final completer = _pendingRequests[info.requestId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(true);
    }
  }

  static void rejectRequest(SenderInfo info) {
    final completer = _pendingRequests[info.requestId];
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  // --------------------------------------------------------------------------
  // FILE UPLOAD
  // --------------------------------------------------------------------------
  static void _handleUpload(HttpRequest req) async {
    try {
      final contentLength = req.headers.contentLength;
      final fileName = req.headers.value("x-file-name") ?? "file.bin";

      final savePath = await _getSavePath(fileName);
      final file = File(savePath);
      final sink = file.openWrite();

      int bytesReceived = 0;

      await for (var data in req) {
        bytesReceived += data.length;
        sink.add(data);

        if (contentLength > 0) {
          final progress = (bytesReceived / contentLength) * 100;
          _progressController.add(progress);
        }
      }

      await sink.close();

      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({"status": "success", "path": savePath}));
      await req.response.close();
    } catch (e) {
      print("UPLOAD ERROR: $e");
      _safeClose(req);
    }
  }

  // --------------------------------------------------------------------------
  // SAFE SAVE PATH
  // --------------------------------------------------------------------------
  static Future<String> _getSavePath(String fileName) async {
    Directory dir;

    if (_isWindows) {
      dir = Directory("${Platform.environment['USERPROFILE']}\\Downloads");
    } else if (_isMacOS) {
      dir = Directory("${Platform.environment['HOME']}/Downloads");
    } else if (_isLinux) {
      dir = Directory("${Platform.environment['HOME']}/Downloads");
    } else if (_isAndroid) {
      dir = Directory("/storage/emulated/0/Download");
    } else if (_isIOS) {
      dir = Directory.systemTemp;
    } else {
      dir = Directory.systemTemp;
    }

    if (!dir.existsSync()) dir.createSync(recursive: true);

    return p.join(dir.path, "YowShare_$fileName");
  }

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------
  static bool get _isServerSupported {
    try {
      return !Platform.isFuchsia && !Platform.isIOS && !Platform.isAndroid
          ? true
          : true;
    } catch (_) {
      return false; // Web
    }
  }

  static bool get _isWindows => _safePlatformCheck(() => Platform.isWindows);
  static bool get _isLinux => _safePlatformCheck(() => Platform.isLinux);
  static bool get _isMacOS => _safePlatformCheck(() => Platform.isMacOS);
  static bool get _isAndroid => _safePlatformCheck(() => Platform.isAndroid);
  static bool get _isIOS => _safePlatformCheck(() => Platform.isIOS);

  static bool _safePlatformCheck(bool Function() fn) {
    try {
      return fn();
    } catch (_) {
      return false;
    }
  }

  static void _safeClose(HttpRequest req) {
    try {
      req.response.close();
    } catch (_) {}
  }
}
