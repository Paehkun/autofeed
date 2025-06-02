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

  final String adminEmail = "admin@autofeed.com";

  void signInUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = FirebaseAuth.instance.currentUser;
      print("Signed in as: ${user?.email}");

      if (user != null) {
        final userEmail = user.email?.toLowerCase();

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (!user.emailVerified) {
          print("Email not verified");
          await user.sendEmailVerification();

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Email Not Verified'),
                content: const Text(
                  'Please verify your email before logging in. A verification link has been sent to your email.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
          await FirebaseAuth.instance.signOut();
          return;
        }

        print("Checking admin database...");
        final adminRef = FirebaseDatabase.instance.ref('admins/${user.uid}');
        final adminSnapshot = await adminRef.get();

        if (adminSnapshot.exists) {
          print("Admin found in admins DB");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminPage()),
          );
          return;
        }

        print("Checking users database...");
        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        final userSnapshot = await userRef.get();

        if (userSnapshot.exists) {
          print("User found in users DB");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
          return;
        }

        print("User not found in either DB");
        showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              title: Text('Error'),
              content: Text('Account not found in system database.'),
            );
          },
        );
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      print("FirebaseAuthException: ${e.code}");

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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      print("Unexpected error: $e");
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
                Image.asset(
                  'assets/images/logo1.png',
                  height: 120,
                ),
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
