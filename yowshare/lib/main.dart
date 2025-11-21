import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  runApp(const YowShareApp());
}

class YowShareApp extends StatelessWidget {
  const YowShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "YowShare",
      debugShowCheckedModeBanner: false,
      theme: yowTheme,
      home: const HomeScreen(),
    );
  }
}
