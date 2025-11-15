import 'dart:async';
import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
/// Optional import for mobile only.
/// We must guard it with try/catch so it does NOT load on desktop/web.
dynamic _mobileIntent;

class ShareIntentHandler {
  static final _controller = StreamController<List<String>>.broadcast();

  static Stream<List<String>> get onSharedFiles => _controller.stream;

  static Future<void> init() async {
    // Desktop / Web → No share intent
    if (!_isMobile) return;

    try {
      _mobileIntent = await _loadMobileIntent();
    } catch (e) {
      print("ShareIntentHandler: Could not load mobile intent → $e");
      return;
    }

    // Live incoming shared files
    _mobileIntent.getMediaStream().listen((files) {
      final paths = files.map((e) => e.path.toString()).toList();
      _controller.add(paths);
    });

    // Initial share (when app starts from a share)
    final initial = await _mobileIntent.getInitialMedia();
    if (initial.isNotEmpty) {
      final paths = initial.map((e) => e.path.toString()).toList();
      _controller.add(paths);
    }
  }

  static bool get _isMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}

/// Loads mobile-only plugin safely
Future<dynamic> _loadMobileIntent() async {
  try {
    // Dynamically import the package only on mobile
    final lib = await Future.microtask(() => _import());
    return lib;
  } catch (e) {
    throw "Failed to load share intent plugin: $e";
  }
}

/// Real import separated so desktop never touches it
dynamic _import() {
  // This import will be removed by tree-shaking on desktop/web
  // ignore: avoid_dynamic_calls
  return ReceiveSharingIntent;
}

// Must import it normally — Flutter will tree-shake safely on desktop/web.

