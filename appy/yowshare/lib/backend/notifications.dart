import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notify {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    // Desktop & Web → no notifications
    if (!_isMobile) {
      _initialized = false;
      return;
    }

    // ANDROID initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'yowshare_channel',
      'YowShare Transfers',
      description: 'Shows progress of file transfers',
      importance: Importance.high,
    );

    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (_) {}

    _initialized = true;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    bool ongoing = false,
    bool progress = false,
    int maxProgress = 100,
    int currentProgress = 0,
  }) async {
    if (!_initialized || !_isMobile) return;

    final android = AndroidNotificationDetails(
      'yowshare_channel',
      'YowShare Transfers',
      channelDescription: 'File transfer updates',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: ongoing,
      onlyAlertOnce: true,
      showProgress: progress,
      maxProgress: maxProgress,
      progress: currentProgress,
    );

    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
    );

    final details = NotificationDetails(android: android, iOS: ios);

    await _notifications.show(id, title, body, details);
  }

  static Future<void> cancel(int id) async {
    if (!_initialized || !_isMobile) return;
    await _notifications.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (!_initialized || !_isMobile) return;
    await _notifications.cancelAll();
  }

  // ----------------------------------------------------------
  // Platform helper
  // ----------------------------------------------------------
  static bool get _isMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false; // Web also ends here safely
    }
  }
}
