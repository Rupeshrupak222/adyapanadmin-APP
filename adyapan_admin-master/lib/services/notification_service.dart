import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Handles FCM push notification registration and display for Principals.
///
/// Call [NotificationService.instance.init()] once in main.dart (after
/// Firebase.initializeApp), then call [registerTokenForPrincipal] after a
/// successful Principal login.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// Callback invoked when a notification is tapped (foreground or background).
  /// The host widget (e.g. MainLayout) can set this to open the inbox.
  void Function()? onNotificationTap;

  // Android notification channel for admin messages
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'admin_messages',
    'Admin Messages',
    description: 'Push notifications from the Adyapan admin panel',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    // Request permission (iOS / Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Create Android high-priority channel
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialise local notifications plugin
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // User tapped local notification (foreground)
        onNotificationTap?.call();
      },
    );

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tapped from background (app was in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped (background): ${message.messageId}');
      onNotificationTap?.call();
    });

    // Check if app was launched from a terminated state by tapping a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
      // Delay to allow the UI to fully mount before opening the inbox
      Future.delayed(const Duration(milliseconds: 800), () {
        onNotificationTap?.call();
      });
    }
  }

  /// Register or refresh the FCM token on the backend for the logged-in principal.
  Future<void> registerTokenForPrincipal() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      debugPrint('FCM token: $token');
      await ApiService.instance.saveFcmToken(token);
    } catch (e) {
      debugPrint('NotificationService.registerTokenForPrincipal error: $e');
    }

    // Listen for token refresh and re-register
    _fcm.onTokenRefresh.listen((newToken) async {
      try {
        await ApiService.instance.saveFcmToken(newToken);
      } catch (_) {}
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title ?? '📢 Admin Message',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

/// Top-level background message handler (must NOT be a class method).
/// Register this in main.dart with:
///   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the Flutter engine in background isolate.
  debugPrint('Background FCM message: ${message.messageId}');
}
