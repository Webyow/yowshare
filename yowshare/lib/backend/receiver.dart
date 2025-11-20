import 'dart:async';
import 'server.dart';
import '../ui/receive/incoming_request_popup.dart';
import 'package:flutter/material.dart';

class Receiver {
  static bool serverStarted = false;

  /// Starts the local receiving server (only once)
  static Future<void> startServer() async {
    if (serverStarted) return;
    serverStarted = true;

    await LocalServer.start();
  }

  /// Listen for incoming handshake requests
  static Stream<IncomingRequest> get onIncomingRequest =>
      LocalServer.incomingRequests.stream;

  /// Listen for receiving progress stream
  static Stream<double> get onProgress =>
      LocalServer.progressStream.stream;

  /// Handle incoming request with UI popup
  static Future<void> handleIncomingRequest(
      BuildContext context, IncomingRequest req) async {
    
    // Show popup
    bool? accepted = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) {
          return IncomingRequestPopup();
        },
        settings: RouteSettings(
          arguments: {
            "deviceName": req.deviceName,
            "fileCount": req.fileCount,
          },
        ),
      ),
    );

    // User accepted?
    if (accepted == true) {
      LocalServer.accept(req);
    } else {
      LocalServer.reject(req);
    }
  }

  /// Called when file transfer completes
  static void notifyCompletion(BuildContext context, int fileCount) {
    Navigator.pushNamed(
      context,
      '/complete',
      arguments: {
        "message": "Received Successfully",
        "fileCount": fileCount,
      },
    );
  }
}
