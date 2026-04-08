import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/notifications/data/notification_repository.dart';

part 'fcm_service.g.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages (app terminated/background)
}

@riverpod
FcmService fcmService(FcmServiceRef ref) {
  return FcmService(ref.read(notificationRepositoryProvider));
}

class FcmService {
  FcmService(this._repository);

  final NotificationRepository _repository;

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Background handler must be registered at the top level
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Request permissions
    final settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus !=
            AuthorizationStatus.provisional) {
      return; // User denied
    }

    // Local notifications for foreground messages
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Register FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _repository.upsertToken(token);
    }

    // Refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen(_repository.upsertToken);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'snappcar_channel',
          'SnappCar',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
