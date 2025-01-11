import 'package:auto_test/screen/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
