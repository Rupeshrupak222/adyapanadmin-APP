import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Handles FCM push notification registration and display.
///
/// Works for ALL roles: Admin, Principal, Teacher.
///
/// Call [NotificationService.instance.init()] once in main.dart (after
/// Firebase.initializeApp), then call [registerToken] after a successful login.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// Callback invoked when a notification is tapped (foreground or background).
  /// The host widget (e.g. MainLayout) sets this to open the inbox.
  void Function()? onNotificationTap;

  // Android notification channel for admin messages
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'admin_messages',
    'Admin Messages',
    description: 'Push notifications from the Adyapan admin panel',
    importance: Importance.high,
    playSound: true,
  );

  // Secondary channel for admin: incoming replies from principals/teachers
  static const AndroidNotificationChannel _replyChannel = AndroidNotificationChannel(
    'admin_replies',
    'Principal & Teacher Replies',
    description: 'Replies received from principals and teachers',
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

    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Create Android notification channels
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_replyChannel);

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

    // Tapped from background (app was open but not in foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped (background): ${message.messageId}');
      onNotificationTap?.call();
    });

    // App launched from terminated state by tapping a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
      // Delay to allow the UI to fully mount before opening the inbox
      Future.delayed(const Duration(milliseconds: 800), () {
        onNotificationTap?.call();
      });
    }
  }

  /// Register or refresh the FCM token on the backend for any logged-in role.
  /// Call this after login for Admin, Principal, and Teacher.
  Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      debugPrint('FCM token obtained: ${token.substring(0, 20)}...');
      await ApiService.instance.saveFcmToken(token);
    } catch (e) {
      debugPrint('NotificationService.registerToken error: $e');
    }

    // Re-register on token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      try {
        await ApiService.instance.saveFcmToken(newToken);
      } catch (_) {}
    });
  }

  /// Legacy alias — kept so existing call sites still compile.
  Future<void> registerTokenForPrincipal() => registerToken();

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Choose channel based on notification type (reply vs admin message)
    final type = message.data['type'] ?? '';
    final channelId = type == 'reply' ? _replyChannel.id : _channel.id;
    final channelName = type == 'reply' ? _replyChannel.name : _channel.name;

    _local.show(
      notification.hashCode,
      notification.title ?? (type == 'reply' ? '📩 New Reply' : '📢 Admin Message'),
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
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
  debugPrint('Background FCM message: ${message.messageId}');
}
