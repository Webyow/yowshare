import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const YowshareApp());

class YowshareApp extends StatelessWidget {
  const YowshareApp({super.key});

  @override
  Widget build(BuildContext context) {
    const matteBlack = Color(0xFF0E0E10);
    const matteWhite = Color(0xFFF6F7F8);

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: matteWhite,
        brightness: Brightness.dark,
        surface: matteBlack,
        background: matteBlack,
      ),
      scaffoldBackgroundColor: matteBlack,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(fontSize: 14),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: matteBlack,
        foregroundColor: matteWhite,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MatteScaffold(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/send', builder: (_, __) => const SendScreen()),
            GoRoute(path: '/receive', builder: (_, __) => const ReceiveScreen()),
            GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Yowshare',
      theme: theme,
      routerConfig: router,
    );
  }
}

/* ===============================
   MatteScaffold (shared shell)
   =============================== */

class MatteScaffold extends StatefulWidget {
  final Widget child;
  const MatteScaffold({super.key, required this.child});

  @override
  State<MatteScaffold> createState() => _MatteScaffoldState();
}

class _MatteScaffoldState extends State<MatteScaffold> {
  static const _tabs = ['/', '/send', '/receive', '/history'];

  int indexFromLocation(String loc) {
    final path = Uri.parse(loc).path;
    final idx = _tabs.indexOf(path);
    return idx < 0 ? 0 : idx;
  }

  void _onTap(int newIndex) {
    final target = _tabs[newIndex];
    final currentUri = GoRouterState.of(context).uri.toString();
    if (currentUri != target) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUri = GoRouterState.of(context).uri.toString();
    final currentIndex = indexFromLocation(currentUri);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yowshare'),
        centerTitle: true,
      ),
      body: SafeArea(child: widget.child),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: Colors.white12,
        selectedIndex: currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.upload_outlined),
              selectedIcon: Icon(Icons.upload),
              label: 'Send'),
          NavigationDestination(
              icon: Icon(Icons.download_outlined),
              selectedIcon: Icon(Icons.download),
              label: 'Receive'),
          NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history_toggle_off),
              label: 'History'),
        ],
      ),
    );
  }
}

/* ===============================
   Placeholder Pages
   =============================== */

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _MatteCardPage(title: 'Home', icon: Icons.home);
}

class SendScreen extends StatelessWidget {
  const SendScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _MatteCardPage(title: 'Send', icon: Icons.upload);
}

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _MatteCardPage(title: 'Receive', icon: Icons.download);
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _MatteCardPage(title: 'History', icon: Icons.history);
}

/* ===============================
   Reusable Matte Card Page
   =============================== */

class _MatteCardPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const _MatteCardPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Card(
        color: cs.surface.withOpacity(0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: cs.onSurface),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
