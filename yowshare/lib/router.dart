import 'package:flutter/material.dart';
import 'ui/home/home_screen.dart';
import 'ui/send/file_preview_screen.dart';
import 'ui/send/device_list_screen.dart';
import 'ui/send/sending_progress_screen.dart';
import 'ui/receive/receive_screen.dart';
import 'ui/receive/receiving_progress_screen.dart';
import 'ui/complete/complete_screen.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case '/filePreview':
        return MaterialPageRoute(
          builder: (_) => const FilePreviewScreen(),
          settings: settings,
        );

      case '/devices':
        return MaterialPageRoute(
          builder: (_) => const DeviceListScreen(),
          settings: settings,
        );

      case '/sendProgress':
        return MaterialPageRoute(
          builder: (_) => const SendingProgressScreen(),
          settings: settings,
        );

      case '/receive':
        return MaterialPageRoute(
          builder: (_) => const ReceiveScreen(),
        );

      case '/receivingProgress':
        return MaterialPageRoute(
          builder: (_) => const ReceivingProgressScreen(),
        );

      case '/complete':
        return MaterialPageRoute(
          builder: (_) => const CompleteScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text("Unknown Route"),
            ),
          ),
        );
    }
  }
}
