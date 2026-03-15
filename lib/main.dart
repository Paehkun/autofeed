import 'package:auto_test/screen/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      databaseURL: dotenv.env['FIREBASE_DATABASE_URL'],
    ),
  );

  // AwesomeNotifications().initialize(
  //   'resource://drawable/ic_stat_ic_notification',
  //   [
  //     NotificationChannel(
  //       channelKey: 'basic_channel',
  //       channelName: 'Basic Notifications',
  //       channelDescription: 'Notification channel for Autofeed alerts',
  //       defaultColor: Colors.blue,
  //       importance: NotificationImportance.High,
  //       ledColor: Colors.white,
  //     )
  //   ],
  //   debug: true,
  // );

  // AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
  //   if (!isAllowed) {
  //     AwesomeNotifications().requestPermissionToSendNotifications();
  //   }
  // });

  // FirebaseMessaging messaging = FirebaseMessaging.instance;
  // await messaging.requestPermission();

  // NotificationSettings settings = await messaging.requestPermission();

  // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //   print("✅ User granted notification permission.");
  // } else {
  //   print("❌ User denied notification permission.");
  // }

  // FCM Listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      print('📩 FCM Message received: ${message.notification!.title}');
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'basic_channel',
          title: notification.title,
          body: notification.body,
          notificationLayout: NotificationLayout.Default,
          icon: 'resource://drawable/ic_stat_ic_notification',
        ),
      );
    }
  });

  runApp(const MyApp());
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
