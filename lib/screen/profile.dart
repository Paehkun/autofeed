import 'dart:convert';
import 'dart:io'; // For using File class
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? phone;
  String? profileImageBase64;
  bool isEditing = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

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
      if (nameSnapshot.exists && mounted) {
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

      DataSnapshot phoneSnapshot = await userRef.child('phone').get();
      if (phoneSnapshot.exists) {
        setState(() {
          phone = phoneSnapshot.value as String?;
          phoneController.text = phone ?? '';
        });
      }

      // Fetch profile image
      DataSnapshot profileImageSnapshot =
          await userRef.child('profileImageBase64').get();
      if (profileImageSnapshot.exists && mounted) {
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

    // Update name if it has changed
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

    if (phoneController.text.trim() != phone) {
      await userRef.update({'phone': phoneController.text.trim()});
      setState(() {
        phone = phoneController.text.trim();
        isEditing = false;
      });
    } else {
      setState(() {
        isEditing = false;
      });
    }

    if (newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty) {
      if (newPasswordController.text == confirmPasswordController.text) {
        try {
          await currentUser.updatePassword(newPasswordController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
          setState(() {
            isEditing = false; // Exit editing mode after a successful update
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating password: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        setState(() {
          isEditing = true;
        });
      }
    }
  }

  Future<void> cancelChanges() async {
    setState(() {
      nameController.text = name ?? '';
      phoneController.text = phone ?? '';
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

  Future<void> _deleteProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final dbRef = FirebaseDatabase.instance.ref().child('users/$uid');

    try {
      await dbRef.update({
        'profileImageBase64': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture deleted.")),
      );

      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting image: ${e.toString()}")),
      );
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting account: $e')),
      );
    }
  }

  void signUserOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to the login screen after sign-out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23.0,
            fontWeight: FontWeight.normal,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () {
                        signUserOut(context);
                        Navigator.of(context).pop();
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
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60.0,
                backgroundColor: Colors.grey[400],
                backgroundImage: (profileImageBase64 != null &&
                        profileImageBase64!.isNotEmpty)
                    ? MemoryImage(base64Decode(profileImageBase64!))
                    : null,
                child:
                    (profileImageBase64 == null || profileImageBase64!.isEmpty)
                        ? const Icon(
                            Icons.person,
                            size: 50.0,
                            color: Colors.white,
                          )
                        : null,
              ),
            ),
          ),
          const SizedBox(height: 40.0),
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
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
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
                        backgroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: SizedBox(
                        width: 100,
                        height: 50,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 140.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
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
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await deleteAccount();
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: SizedBox(
                        width: 160,
                        height: 50,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Center(
                            child: Text(
                              'Delete Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else if (!isEditing)
            const SizedBox(height: 5.0),
          if (!isEditing)
            Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 20,
            ),
          const SizedBox(height: 5.0),
          Column(
            children: [
              if (!isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.account_box_rounded,
                      color: Colors.black,
                      size: 35.0,
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
              const SizedBox(height: 5.0),
              if (!isEditing)
                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  height: 20,
                ),
              const SizedBox(height: 5.0),
              if (!isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.local_phone_rounded,
                      color: Colors.black,
                      size: 35.0,
                    ),
                    Text(
                      phone ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 5.0),
              if (!isEditing)
                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  height: 20,
                ),
              const SizedBox(height: 5.0),
              if (!isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.mail_rounded,
                      color: Colors.black,
                      size: 35.0,
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
              const SizedBox(height: 5.0),
              if (!isEditing)
                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                  height: 20,
                ),
              const SizedBox(height: 5.0),
              const SizedBox(height: 40.0),
              if (!isEditing)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: SizedBox(
                    width: 160,
                    height: 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(9), //
                      ),
                      child: const Center(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20.0),
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _deleteProfilePicture,
                  child: Container(
                    width: 160,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Center(
                      child: Text(
                        'Remove Profile Picture',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
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
