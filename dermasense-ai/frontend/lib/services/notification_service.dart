import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // 3. Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
        _addNotificationToProvider(message);
      }
    });

    // 5. Handle app opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessageAction(message);
      }
    });

    // 6. Handle app opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageAction(message);
    });

    // Get FCM token for testing
    String? token = await _fcm.getToken();
    print('FCM Token: $token');
  }

  void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dermasense_channel_id',
      'DermaSense Notifications',
      channelDescription: 'Important updates and reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      print('notification payload: ${response.payload}');
      // Handle navigation or actions based on payload
      // For now, we can just navigate to the Notifications screen
      if (navigatorKey != null && navigatorKey!.currentContext != null) {
        // We will implement navigation logic here, e.g. pushing a route
        Navigator.pushNamed(navigatorKey!.currentContext!, '/notifications');
      }
    }
  }

  void _handleMessageAction(RemoteMessage message) {
    if (navigatorKey != null && navigatorKey!.currentContext != null) {
      Navigator.pushNamed(navigatorKey!.currentContext!, '/notifications');
    }
  }

  void _addNotificationToProvider(RemoteMessage message) {
    if (navigatorKey != null && navigatorKey!.currentContext != null) {
      final context = navigatorKey!.currentContext!;
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.addNotification(
        AppNotification(
          id: message.messageId ?? DateTime.now().toString(),
          title: message.notification?.title ?? 'Alert',
          body: message.notification?.body ?? '',
          timestamp: message.sentTime ?? DateTime.now(),
        ),
      );
    }
  }
}
