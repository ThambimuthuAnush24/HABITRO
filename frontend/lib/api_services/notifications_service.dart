import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/reward_screen/achievements_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationsService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final _storage = FlutterSecureStorage();

  static Future<void> initialize() async {
    // Request permission
    // ignore: unused_local_variable
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    String? fcmToken = await _firebaseMessaging.getToken();
    debugPrint("FCM Token: $fcmToken");

    // Save token to Django backend if available
    await saveTokenToBackend(fcmToken!);
  
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(json.decode(response.payload ?? '{}'));
      },
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Background messages tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });
  }

  static Future<void> saveTokenToBackend(String fcmToken) async {
    final baseUrl = dotenv.env['BASE_URL'];
    final token = await _storage.read(key: 'authToken');

    if (token == null) {
      debugPrint("No DRF token found in secure storage");
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/notifications/save-token/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'token': fcmToken}),
    );

    if (response.statusCode == 201) {
      debugPrint('Token saved successfully');
    } else {
      debugPrint('Failed to save token: ${response.body}');
    }
  }

  static void _showNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'achievement_channel',
            'Achievement Notifications',
            channelDescription: 'Notifications for unlocked achievements',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    if (data['type'] == 'achievement') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AchievementsPage(),
        ),
      );
    }
    // Add more types if needed
  }
}
