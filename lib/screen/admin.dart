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
  List<Map<String, dynamic>> filteredList = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    final snapshot = await usersRef.get();

    if (snapshot.exists && mounted) {
      List<Map<String, dynamic>> tempList = [];
      Map usersMap = snapshot.value as Map;

      for (final key in usersMap.keys) {
        final value = usersMap[key];
        if (value['role'] != 'admin') {
          final deviceSnapshot =
              await usersRef.child('$key/device/power').get();
          final bool isDeviceOn = deviceSnapshot.value == true;

          tempList.add({
            'uid': key,
            'name': value['name'] ?? 'No Name',
            'email': value['email'] ?? 'No Email',
            'profileImageBase64': value['profileImageBase64'],
            'devicePower': isDeviceOn,
            'role': value['role'] ?? 'user',
            'active': value['active'] ?? true,
          });
        }
      }

      // Sort online users on top
      tempList.sort((a, b) {
        if (a['devicePower'] && !b['devicePower']) return -1;
        if (!a['devicePower'] && b['devicePower']) return 1;
        return 0;
      });

      setState(() {
        userList = tempList;
        filteredList = tempList;
        isLoading = false;
      });
    } else {
      setState(() {
        userList = [];
        filteredList = [];
        isLoading = false;
      });
    }
  }

  void filterUsers(String query) {
    List<Map<String, dynamic>> filtered = userList.where((user) {
      final nameLower = user['name'].toLowerCase();
      final emailLower = user['email'].toLowerCase();
      final searchLower = query.toLowerCase();

      return nameLower.contains(searchLower) ||
          emailLower.contains(searchLower);
    }).toList();

    setState(() {
      searchQuery = query;
      filteredList = filtered;
    });
  }

  void signUserOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
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
    final totalUsers = userList.length;
    final onlineUsers = userList.where((user) => user['devicePower']).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row with Logout Button + Refresh
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: const Text('Logout'),
                              onPressed: () {
                                Navigator.pop(context);
                                signUserOut(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Users',
                    onPressed: fetchUsers,
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'User Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // User count summary
              Text(
                'Total users: $totalUsers | Online: $onlineUsers',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 12),

              // Search bar
              TextField(
                onChanged: filterUsers,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by name or email...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? Center(
                            child: Text(
                              searchQuery.isEmpty
                                  ? 'No users found.'
                                  : 'No users matching "$searchQuery".',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final user = filteredList[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: user['profileImageBase64'] != null
                                      ? CircleAvatar(
                                          radius: 30,
                                          backgroundImage: MemoryImage(
                                            base64Decode(
                                                user['profileImageBase64']),
                                          ),
                                        )
                                      : const CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Colors.grey,
                                          child: Icon(Icons.person,
                                              color: Colors.white),
                                        ),
                                  title: Text(
                                    user['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user['email']),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Role: ${user['role']}',
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Device: ${user['devicePower'] ? "Online" : "Offline"}',
                                          style: TextStyle(
                                            color: user['devicePower']
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        tooltip: 'Delete User',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Delete User'),
                                              content: Text(
                                                  'Are you sure you want to delete user "${user['name']}"? This action cannot be undone.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(context);
                                                    try {
                                                      await usersRef
                                                          .child(user['uid'])
                                                          .remove();
                                                      setState(() {
                                                        userList.removeWhere(
                                                            (u) =>
                                                                u['uid'] ==
                                                                user['uid']);
                                                        filteredList
                                                            .removeWhere((u) =>
                                                                u['uid'] ==
                                                                user['uid']);
                                                      });
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Failed to delete user: $e')),
                                                      );
                                                    }
                                                  },
                                                  child: const Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            UserDetailPage(uid: user['uid']),
                                      ),
                                    );
                                  },
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
}
