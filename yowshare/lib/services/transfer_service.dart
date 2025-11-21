import 'dart:convert';
import 'dart:io';
import '../models/device.dart';
import '../models/share_file.dart';
import 'http_server_service.dart';

class TransferService {
  final List<ShareFile> files;
  final List<Device> receivers;

  TransferService({required this.files, required this.receivers});

  late String sessionToken;
  HttpServerService? httpServer;

  Future<int> startServer() async {
    sessionToken = DateTime.now().millisecondsSinceEpoch.toString();
    httpServer = HttpServerService(
      sessionToken: sessionToken,
      files: files,
    );

    return await httpServer!.startServer();
  }

  // SEND HANDSHAKE REQUEST
  Future<bool> sendHandshake(Device d, int senderPort) async {
    final url = Uri.parse("http://${d.ip}:${d.port}/handshake");

    try {
      final httpClient = HttpClient();
      final req = await httpClient.postUrl(url);

      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        "sessionToken": sessionToken,
        "senderPort": senderPort,
        "deviceName": "YowShareDevice",
        "fileCount": files.length,
      }));

      final response = await req.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
