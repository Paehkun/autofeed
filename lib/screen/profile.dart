import 'dart:convert';
import 'dart:io'; // For using File class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart'; // For image picking

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? profileImageBase64;
  bool isEditing = false;

  final TextEditingController nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/${currentUser.uid}');

      // Fetch username
      DataSnapshot nameSnapshot = await userRef.child('name').get();
      if (nameSnapshot.exists) {
        setState(() {
          name = nameSnapshot.value as String?;
          nameController.text = name ?? '';
        });
      }

      // Fetch email
      DataSnapshot emailSnapshot = await userRef.child('email').get();
      if (emailSnapshot.exists) {
        setState(() {
          email = emailSnapshot.value as String?;
        });
      }

      // Fetch profile image
      DataSnapshot profileImageSnapshot =
          await userRef.child('profileImageBase64').get();
      if (profileImageSnapshot.exists) {
        setState(() {
          profileImageBase64 = profileImageSnapshot.value as String?;
        });
      }
    }
  }

  Future<void> saveChanges() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DatabaseReference userRef =
        FirebaseDatabase.instance.ref('users/${currentUser.uid}');

    if (nameController.text.trim() != name) {
      await userRef.update({'name': nameController.text.trim()});
      setState(() {
        name = nameController.text.trim();
        isEditing = false;
      });
    } else {
      setState(() {
        isEditing = false;
      });
    }
  }

  Future<void> cancelChanges() async {
    setState(() {
      nameController.text = name ?? '';
      isEditing = false;
    });
  }

  // Function to pick image from gallery
  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File imageFile = File(image.path);
      String base64Image = base64Encode(imageFile.readAsBytesSync());
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('users/${currentUser.uid}');
        await userRef.update({'profileImageBase64': base64Image});
        setState(() {
          profileImageBase64 = base64Image;
        });
      }
    }
  }

  // Function to delete user account
  Future<void> deleteAccount() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Delete user data from Firebase Realtime Database
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/${currentUser.uid}');
      await userRef.remove();

      // Delete user account from Firebase Authentication
      await currentUser.delete();

      // Navigate to login screen or show confirmation dialog
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23.0,
            fontWeight: FontWeight.normal,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20.0),
          Center(
            child: GestureDetector(
              onTap: pickImage, // Call pickImage on tap
              child: CircleAvatar(
                radius: 60.0,
                backgroundColor: Colors.grey[400],
                backgroundImage: profileImageBase64 != null
                    ? MemoryImage(base64Decode(profileImageBase64!))
                    : null,
                child: profileImageBase64 == null
                    ? const Icon(
                        Icons.person,
                        size: 50.0,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          if (isEditing)
            Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: cancelChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      name ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      email ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Edit Name',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: const Text(
                            'Are you sure you want to delete your account? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop(); // Close the dialog
                              await deleteAccount(); // Call the delete account function
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
