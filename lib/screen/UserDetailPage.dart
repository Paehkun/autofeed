import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UserDetailPage extends StatefulWidget {
  final String uid;

  const UserDetailPage({super.key, required this.uid});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final ref = FirebaseDatabase.instance.ref('users/${widget.uid}');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      setState(() {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  Future<void> deleteUser() async {
    final ref = FirebaseDatabase.instance.ref('users/${widget.uid}');
    try {
      await ref.remove();
      Navigator.pop(
          context); // Navigate back to the previous screen after deletion
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profileImageBase64 = userData!['profileImageBase64'];
    final imageWidget = profileImageBase64 != null
        ? CircleAvatar(
            radius: 60,
            backgroundImage: MemoryImage(base64Decode(profileImageBase64)),
          )
        : const CircleAvatar(
            radius: 60,
            child: Icon(Icons.person, size: 40),
          );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('User Details'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image Section
            Container(
              padding: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: imageWidget,
            ),
            const SizedBox(height: 20),
            // User Info Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildUserInfoRow('Name', userData!['name'] ?? 'N/A'),
                    _buildUserInfoRow('Email', userData!['email'] ?? 'N/A'),
                    _buildUserInfoRow('Phone', userData!['phone'] ?? 'N/A'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Show a confirmation dialog before deleting the user
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text(
                                  'Are you sure you want to delete this user? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteUser(); // Call delete user function
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 50),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Delete User',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
