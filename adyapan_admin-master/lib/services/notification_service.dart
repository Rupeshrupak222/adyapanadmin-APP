import 'package:flutter/foundation.dart';

/// Notification Service — stubbed out (Firebase not configured).
/// Once Firebase is added to the project, replace this with the real implementation.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  /// Callback invoked when a notification is tapped.
  VoidCallback? onNotificationTap;

  /// Initialize — no-op until Firebase is configured.
  Future<void> init() async {
    debugPrint('NotificationService: Firebase not configured, skipping init');
  }

  /// Register token — no-op until Firebase is configured.
  Future<void> registerToken() async {
    debugPrint('NotificationService: Firebase not configured, skipping token registration');
  }

  /// Register for principal — no-op
  Future<void> registerTokenForPrincipal() async {}
}

/// Background handler stub
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(dynamic message) async {}
