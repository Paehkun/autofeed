import 'package:auto_test/screen/UserDetailPage.dart';
import 'package:auto_test/screen/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');
  List<Map<String, dynamic>> userList = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final snapshot = await usersRef.get();

    if (snapshot.exists && mounted) {
      List<Map<String, dynamic>> tempList = [];
      Map usersMap = snapshot.value as Map;

      for (final key in usersMap.keys) {
        final value = usersMap[key];
        if (value['role'] != 'admin') {
          // Fetch device power
          final deviceSnapshot =
              await usersRef.child('$key/device/power').get();
          final bool isDeviceOn = deviceSnapshot.value == true;

          tempList.add({
            'uid': key,
            'name': value['name'] ?? 'No Name',
            'email': value['email'] ?? 'No Email',
            'profileImageBase64': value['profileImageBase64'],
            'devicePower': isDeviceOn,
          });
        }
      }

      if (mounted) {
        setState(() {
          userList = tempList;
        });
      }
    }
  }

  void signUserOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen after sign-out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const AuthPage()), // Replace with your login screen
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Show confirmation dialog before logging out
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Logout'),
                            content:
                                const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  signUserOut(
                                      context); // Call the sign out function
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              const Text(
                'Manage Users',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: userList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: userList.length,
                        itemBuilder: (context, index) {
                          final user = userList[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ListTile(
                              leading: user['profileImageBase64'] != null
                                  ? Container(
                                      width: 100, // Set the desired width
                                      height: 100, // Set the desired height
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: MemoryImage(base64Decode(
                                              user['profileImageBase64'])),
                                          fit: BoxFit
                                              .cover, // Ensures the image is cropped or scaled to fit the container
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 100, // Set the desired width
                                      height: 100, // Set the desired height
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors
                                            .grey, // Default background color
                                      ),
                                      child: const Icon(Icons.person),
                                    ),
                              title: Text(user['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email']),
                                  Text(
                                    'Device: ${user['devicePower'] == true ? "Online" : "Offline"}',
                                    style: TextStyle(
                                      color: user['devicePower'] == true
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UserDetailPage(uid: user['uid']),
                                  ),
                                );
                              },
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    deleteUser(user['uid']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteUser(String uid) async {
    await usersRef.child(uid).remove();
    fetchUsers(); // Refresh the list
  }
}
