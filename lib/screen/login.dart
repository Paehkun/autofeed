import 'package:auto_test/component/login_button.dart';
import 'package:auto_test/screen/admin.dart';
import 'package:auto_test/screen/homepage.dart';
import 'package:auto_test/screen/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:auto_test/screen/forgotpass.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  final Function()? onTap;
  const Login({super.key, required this.onTap});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Define the fake admin email
  final String adminEmail = "admin@autofeed.com";

  void signInUser() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check if the email is the fake admin email
        if (user.email == adminEmail) {
          // Skip email verification and go directly to admin page
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPage(),
            ),
          );
        } else if (!user.emailVerified) {
          // If not the admin, and the email is not verified, show alert
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Email Not Verified'),
                content: const Text(
                    'Please verify your email before logging in. A verification link has been sent to your email.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          await FirebaseAuth.instance.signOut();
        } else {
          // If email is verified, check role in Realtime Database
          DatabaseReference userRef =
              FirebaseDatabase.instance.ref('users/${user.uid}');
          DataSnapshot snapshot = await userRef.get();

          Navigator.pop(context);

          if (snapshot.exists) {
            String role = snapshot.child('role').value.toString();

            if (role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPage(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            }
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text('Error'),
                  content: Text('User role not found.'),
                );
              },
            );
            await FirebaseAuth.instance.signOut();
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase error code: ${e.code}");
      Navigator.pop(context); // Pop loading dialog

      if (e.code == 'invalid-email') {
        wrongEmailMessage();
      } else if (e.code == 'invalid-credential') {
        wrongPasswordMessage();
      } else if (e.code == 'user-not-found') {
        showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              title: Text('Email Not Found'),
            );
          },
        );
      }
    }
  }

  void wrongEmailMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Incorrect Email'),
        );
      },
    );
  }

  void wrongPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Incorrect Password'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.lock, size: 80),
                const SizedBox(height: 40),
                Text(
                  'Welcome to AutoFeed',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 120),
                Textfield(
                  controller: emailController,
                  hintText: 'Email',
                  obsecureText: false,
                ),
                const SizedBox(height: 30),
                Textfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obsecureText: true,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Forgotpass()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Button(onTap: signInUser),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      )),
                      Expanded(
                          child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ))
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t Have Account Yet? ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 40.0),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Sign Up Now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
