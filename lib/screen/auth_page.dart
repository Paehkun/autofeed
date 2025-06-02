import 'package:auto_test/screen/admin.dart';
import 'package:auto_test/screen/homepage.dart';
import 'package:auto_test/screen/login.dart';
import 'package:auto_test/screen/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<Widget> checkUserRole(User user) async {
    // Hardcoded admin email check
    if (user.email == "admin@autofeed.com") {
      return const AdminPage();
    }

    // Fetch role from Realtime Database
    final ref = FirebaseDatabase.instance.ref('admin/${user.uid}');
    final snapshot = await ref.child('role').get();

    final role = snapshot.value.toString();
    if (role == 'admin') {
      return const AdminPage();
    } else {
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.hasData) {
            return FutureBuilder<Widget>(
              future: checkUserRole(snapshot.data!),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (roleSnapshot.hasError) {
                  return Center(child: Text("Error: ${roleSnapshot.error}"));
                }

                return roleSnapshot.data!;
              },
            );
          }

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
