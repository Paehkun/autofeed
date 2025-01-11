import 'package:auto_test/component/login_button.dart';
import 'package:auto_test/screen/homepage.dart';
import 'package:auto_test/screen/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void signInUser() async {
    // Show loading indicator
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Sign in the user with email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      // Check if the user's email is verified
      if (user != null && !user.emailVerified) {
        // Close the loading dialog
        Navigator.pop(context);

        // Show the email verification dialog
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
        // Optionally sign out the user as they cannot proceed without verified email
        await FirebaseAuth.instance.signOut();
      } else {
        // Close the loading dialog
        Navigator.pop(context);

        // Proceed to the home screen if email is verified
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const HomePage(), // Replace with your home screen
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase error code: ${e.code}");
      Navigator.pop(context); // Pop loading dialog

      // Show error messages
      if (e.code == 'invalid-email') {
        wrongEmailMessage();
      } else if (e.code == 'invalid-credential') {
        wrongPasswordMessage();
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
                // Logo
                const Icon(
                  Icons.lock,
                  size: 80,
                ),
                const SizedBox(height: 40),
                // Welcome
                Text(
                  'Welcome to AutoFeed',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 120),
                // Email field
                Textfield(
                  controller: emailController,
                  hintText: 'Email',
                  obsecureText: false,
                ),
                const SizedBox(height: 30),
                // Password field
                Textfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obsecureText: true,
                ),
                // Forgot password link
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
                              builder: (context) => const Forgotpass(),
                            ),
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
                // Sign in button
                Button(
                  onTap: signInUser,
                ),
                const SizedBox(height: 20),
                // Divider
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
                // Register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t Have Account Yet? ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(
                      height: 40.0,
                    ),
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
