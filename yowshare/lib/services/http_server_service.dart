import 'dart:convert';
import 'dart:io';
import '../models/share_file.dart';

class HttpServerService {
  HttpServer? _server;
  final String sessionToken;
  final List<ShareFile> files;

  HttpServerService({
    required this.sessionToken,
    required this.files,
  });

  /// Start HTTP server on any free port
  Future<int> startServer() async {
    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      0, // auto-select free port
    );
    _handleRequests();
    return _server!.port;
  }

  /// Main request handler
  void _handleRequests() {
    _server!.listen((HttpRequest request) async {
      final uri = request.uri.path;

      // --- Validate token ---
      final recvToken = request.uri.queryParameters["token"];
      if (recvToken != sessionToken) {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }

      // ===========================
      // 1) Manifest
      // ===========================
      if (uri == "/manifest.json") {
        final manifest = files.map((f) => {
              "name": f.name,
              "size": f.size,
            }).toList();

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(manifest));
        await request.response.close();
        return;
      }

      // ===========================
      // 2) File streaming
      // ===========================
      if (uri.startsWith("/files/")) {
        final filename = uri.replaceFirst("/files/", "");

        final file = files.firstWhere(
          (f) => f.name == filename,
          orElse: () => ShareFile(name: "", path: "", size: 0),
        );

        if (file.path.isEmpty) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final ioFile = File(file.path);

        if (!await ioFile.exists()) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        // --- Correct Content-Disposition header ---
        request.response.headers.set(
          'Content-Disposition',
          'attachment; filename="${file.name}"',
        );

        request.response.headers.contentType = ContentType.binary;

        // Stream file efficiently
        await ioFile.openRead().pipe(request.response);
        return;
      }

      // ===========================
      // 3) Unknown route
      // ===========================
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    });
  }

  /// Stop the HTTP server (clean shutdown)
  Future<void> stopServer() async {
    await _server?.close(force: true);
  }
}
