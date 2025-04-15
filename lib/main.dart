import 'package:auto_test/screen/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDVYlD2YitXeh5DuB5GwAet2-q-_zpDEHA",
      appId: "1:82288421129:android:afd9d2d0dfd11ad77d0bd8",
      messagingSenderId: "82288421129",
      projectId: "auth-autofeed",
      databaseURL:
          "https://auth-autofeed-default-rtdb.asia-southeast1.firebasedatabase.app",
    ),
  );

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    null, // Let Android handle the default notification icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for Autofeed alerts',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        ledColor: Colors.white,
      )
    ],
    debug: true,
  );

  // Request notification permission
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  NotificationSettings settings = await messaging.requestPermission();

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ User granted notification permission.");
  } else {
    print("❌ User denied notification permission.");
  }

  runApp(const MyApp()); // No need to call checkFoodLevel() here
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}
