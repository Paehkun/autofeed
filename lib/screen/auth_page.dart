import 'package:auto_test/screen/homepage.dart';
import 'package:auto_test/screen/login.dart';
import 'package:auto_test/screen/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Checking for connection state while waiting for Firebase auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handling error state if any
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // If the user is logged in, navigate to HomePage
          if (snapshot.hasData) {
            return const HomePage();
          }

          // If the user is not logged in, show the Login screen
          return Login(onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Register()),
            );
          });
        },
      ),
    );
  }
}
