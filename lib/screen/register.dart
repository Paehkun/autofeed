import 'package:auto_test/component/register_button.dart';
import 'package:auto_test/screen/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void registerUser() async {
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
      if (passwordController.text == confirmPasswordController.text) {
        // Create user with email and password
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Send email verification
        await userCredential.user?.sendEmailVerification();

        // Save user data to Firebase Realtime Database
        await saveUserData(userCredential.user!, nameController.text);

        // Sign out the user to force them back to the login screen
        await FirebaseAuth.instance.signOut();

        // Pop loading indicator
        Navigator.pop(context);

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Registration Successful'),
              content: const Text(
                'A verification link has been sent to your email. Please verify your email to complete the registration.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to login screen
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Pop loading indicator
        Navigator.pop(context);

        // Show passwords do not match message
        passwordsDoNotMatchMessage();
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      // Handle specific Firebase errors
      if (e.code == 'email-already-in-use') {
        emailAlreadyInUseMessage();
      } else if (e.code == 'weak-password') {
        weakPasswordMessage();
      } else {
        genericErrorMessage(e.message);
      }
    }
  }

  Future<void> saveUserData(User user, String name) async {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref('users/${user.uid}');
    await userRef.set({
      'foodLevel': 100, // Set initial food level
      'name': name, // Save the username
      'email': user.email,
    });
  }

  void emailAlreadyInUseMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Email Already In Use'),
        );
      },
    );
  }

  void weakPasswordMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Weak Password'),
          content: Text('Password must be at least 6 characters long.'),
        );
      },
    );
  }

  void passwordsDoNotMatchMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Passwords Do Not Match'),
        );
      },
    );
  }

  void genericErrorMessage(String? message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message ?? 'An error occurred. Please try again.'),
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

                // Welcome text
                Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 50),

                // Username field
                Textfield(
                  controller: nameController,
                  hintText: 'Name',
                  obsecureText: false,
                ),
                const SizedBox(height: 20),

                // Email field
                Textfield(
                  controller: emailController,
                  hintText: 'Email',
                  obsecureText: false,
                ),
                const SizedBox(height: 20),

                // Password field
                Textfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obsecureText: true,
                ),
                const SizedBox(height: 20),

                // Confirm password field
                Textfield(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obsecureText: true,
                ),

                const SizedBox(height: 20),

                // Sign up button
                RegisterButton(
                  onTap: registerUser,
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
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      )
                    ],
                  ),
                ),

                // Already have an account section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back to Login screen
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
