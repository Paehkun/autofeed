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
      Navigator.pop(context); // Navigate back after deletion
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
            radius: 70,
            backgroundImage: MemoryImage(base64Decode(profileImageBase64)),
          )
        : const CircleAvatar(
            radius: 70,
            child: Icon(Icons.person, size: 60, color: Colors.grey),
            backgroundColor: Colors.black12,
          );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('User Details'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image with border and shadow
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(child: imageWidget),
              ),
              const SizedBox(height: 32),

              // User Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.blueAccent.withOpacity(0.3),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  child: Column(
                    children: [
                      _buildUserInfoRow(
                          Icons.person, 'Name', userData!['name'] ?? 'N/A'),
                      const Divider(height: 20),
                      _buildUserInfoRow(
                          Icons.email, 'Email', userData!['email'] ?? 'N/A'),
                      const Divider(height: 20),
                      _buildUserInfoRow(
                          Icons.phone, 'Phone', userData!['phone'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Delete Button
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  child: Text(
                    'Delete User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 8,
                  shadowColor: Colors.redAccent.withOpacity(0.5),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                          'Are you sure you want to delete this user? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            deleteUser();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 26),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(fontSize: 17, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
