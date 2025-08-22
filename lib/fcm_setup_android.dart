import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// MUST be a top-level function (background handler)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 BG message: ${message.messageId}');
}

/// Local notifications plugin
final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

/// Android notification channel
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important alerts.',
  importance: Importance.max,
);

/// Initialize local notifications
Future<void> initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await _fln.initialize(initSettings);

  // Create channel for Android notifications
  await _fln
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

/// Request runtime notification permission on Android 13+
Future<void> requestAndroidNotificationPermissionIfNeeded() async {
  if (Platform.isAndroid && await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

/// Initialize Firebase + FCM
Future<void> initFirebaseAndFCM() async {
  await Firebase.initializeApp();

  // Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request permission (iOS + Android 13+)
  await FirebaseMessaging.instance.requestPermission();
  await requestAndroidNotificationPermissionIfNeeded();

  // Subscribe all users to topic
  await FirebaseMessaging.instance.subscribeToTopic('all_users');

  // Log token
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('✅ FCM token: $token');

  // Foreground messages → show local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      _fln.show(
        notification.hashCode,
        notification.title ?? 'Notification',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  // Background tapped
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('🔔 Notification tapped (background): ${message.data}');
  });

  // Launched from terminated state
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('🚀 Notification launched app: ${initialMessage.data}');
  }
}
