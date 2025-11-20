import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: YowShareApp()));
}

class YowShareApp extends StatelessWidget {
  const YowShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "YOWShare",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: AppRouter.generate,
    );
  }
}
