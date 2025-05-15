import 'dart:math';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:auto_test/screen/auth_page.dart';
import 'package:auto_test/screen/monitor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_test/screen/FeedTimerPage.dart';
import 'package:auto_test/screen/report.dart';
import 'package:auto_test/screen/profile.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const FeedTimerPage(),
    const Monitor(),
    const ReportScreen(),
    const ProfileScreen(),
  ];
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        fixedColor: Colors.black,
        backgroundColor: Colors.white,
        onTap: _navigateBottomBar,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm_rounded), label: 'Timer'),
          BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt), label: 'Monitor'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded), label: 'Reporting'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String realTimeValue = '0';
  final currentUser = FirebaseAuth.instance.currentUser!;
  String? name;
  bool feedSwitch = false;
  bool powerSwitch = false;
  String? todaySchedule = "Loading today's schedule...";
  String? selectedFishAge;
  String? selectedFishAmount;

  @override
  void initState() {
    super.initState();
    fetchname();
    fetchFeedSwitchState();
    fetchPowerSwitchState();
    fetchTodaySchedule();
    subscribeToTopic(currentUser.uid);
  }

  final Map<String, List<String>> fishAgeAmountOptions = {
    '24 months and above': ['0–5', '6–10', '11–15', '15 and above'],
    '12–24 months': ['0–5', '6–10', '11–15', '15 and above'],
    '6–12 months': ['0–5', '6–10', '11–15', '15 and above'],
  };

  void subscribeToTopic(String userId) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(userId);
      print("✅ Subscribed to topic: $userId");
    } catch (e) {
      print("❌ Error subscribing to topic: $e");
    }
  }

  Future<void> fetchname() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/${currentUser.uid}');
      DataSnapshot snapshot = await userRef.child('name').get();
      if (snapshot.exists && mounted) {
        setState(() {
          name = snapshot.value as String?;
        });
      }
    }
  }

  Future<void> fetchFeedSwitchState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference feedRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/device/status');
      DataSnapshot snapshot = await feedRef.get();
      if (snapshot.exists && mounted) {
        setState(() {
          feedSwitch = snapshot.value as bool;
        });
      }
    }
  }

  Future<void> fetchPowerSwitchState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference powerRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/device/power');
      DataSnapshot snapshot = await powerRef.get();
      if (snapshot.exists && mounted) {
        setState(() {
          powerSwitch = snapshot.value as bool;
        });
      }
    }
  }

  void fetchTodaySchedule() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Adjust for Malaysia timezone (GMT+8)
    final now = DateTime.now().add(const Duration(hours: 8));
    final today = DateFormat('EEEE').format(now); // Get the day of the week
    final todayDate = DateFormat('dd-MM-yyyy').format(now); // Get today's date

    debugPrint("Today: $today"); // Check the current day

    final scheduleRef =
        FirebaseDatabase.instance.ref('users/${currentUser.uid}/schedule');

    final snapshot = await scheduleRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      List<String> todayTimers = [];

      data.forEach((key, value) {
        if (value['day'] != null && value['enabled'] == true) {
          String days = value['day']; // Example: "Monday, Wednesday"
          if (days.contains(today)) {
            todayTimers.add(value['time']); // Collect time if day matches
          }
        }
      });

      // Sort times
      todayTimers.sort((a, b) {
        final timeA =
            DateFormat('hh:mm a').parse(a); // Correct for 12-hour format
        final timeB = DateFormat('hh:mm a').parse(b);
        return timeA.compareTo(timeB);
      });

      setState(() {
        todaySchedule = todayTimers.isNotEmpty
            ? "$today, $todayDate :\n${todayTimers.join("\n")}" // Show day and date
            : "No schedule for today.";
      });
    } else {
      setState(() {
        todaySchedule = "No schedule found.";
      });
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

  void sendFeedData(bool feedStatus) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      //baca userID untuk store and fetch data
      DatabaseReference statusRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/device/status');
      try {
        // Toggle the current status value
        DataSnapshot snapshot = await statusRef.get();
        bool currentStatus = snapshot.value == true;

        // Update the "status" field in Firebase
        await statusRef.set(!currentStatus);

        print("Status updated successfully to ${!currentStatus}");
      } catch (e) {
        print("Error updating status: $e");
      }
    } else {
      print("User is not logged in");
    }
  }

  // Function to send the power status to Firebase
  void sendPowerData(bool powerStatus) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference powerRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/device/power');
      try {
        await powerRef
            .set(powerStatus); // Set the new power status in the database
        print("Power status updated successfully to $powerStatus");
      } catch (e) {
        print("Error updating power status: $e");
      }
    } else {
      print("User is not logged in");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      //baca userID untuk store and fetch data
      DatabaseReference testref =
          FirebaseDatabase.instance.ref('users/${user.uid}/foodLevel');

      //listen databse
      testref.onValue.listen(
        (event) {
          setState(() {
            realTimeValue = event.snapshot.value.toString();
          });
        },
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
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
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              //tajuk
              const Text(
                'AutoFeed',
                style: TextStyle(
                  fontSize: 23.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                name ?? 'Loading...',
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  hint: const Text(
                    'Select Fish Age',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  items: fishAgeAmountOptions.keys.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  value: selectedFishAge,
                  onChanged: (value) {
                    setState(() {
                      selectedFishAge = value;
                      selectedFishAmount =
                          null; // Reset fish amount on age change
                    });
                  },
                  buttonStyleData: ButtonStyleData(
                    height: 50,
                    width: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black26,
                      ),
                      color: Colors.white,
                    ),
                    elevation: 2,
                  ),
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Second Dropdown: Select Fish Amount based on Fish Age
              if (selectedFishAge != null && selectedFishAge != 'Custom')
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    hint: const Text(
                      'Select Fish Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    items: fishAgeAmountOptions[selectedFishAge]!.map((item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    value: selectedFishAmount,
                    onChanged: (value) {
                      setState(() {
                        selectedFishAmount = value;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 50,
                      width: 200,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.black26,
                        ),
                        color: Colors.white,
                      ),
                      elevation: 2,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                      ),
                    ),
                    menuItemStyleData: const MenuItemStyleData(
                      height: 40,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 15),

              Container(
                height: 220, // Adjusted height to fit schedule and toggle only
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Shadow color
                      spreadRadius: 10, // Spread of the shadow
                      blurRadius: 10, // How much the shadow is blurred
                      offset:
                          const Offset(3, 5), // Position of the shadow (x, y)
                    ),
                  ],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0), // Add horizontal padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Schedule",
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            todaySchedule ?? "No feeding schedule today.",
                            style: const TextStyle(
                              fontSize: 18.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 200,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1), // Shadow color
                          spreadRadius: 7, // Spread of the shadow
                          blurRadius: 10, // How much the shadow is blurred
                          offset: const Offset(
                              3, 5), // Position of the shadow (x, y)
                        ),
                      ],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Food Level',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Fetch data from Firebase
                          displayFoodLevelCircular(realTimeValue),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 200,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 7,
                          blurRadius: 10,
                          offset: const Offset(3, 5),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/feeder.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Text(
                          "Device",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DefaultTextStyle.merge(
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                            child: IconTheme.merge(
                              data: const IconThemeData(color: Colors.white),
                              child: AnimatedToggleSwitch.dual(
                                current: powerSwitch,
                                first: false,
                                second: true,
                                spacing: 20,
                                animationDuration:
                                    const Duration(milliseconds: 600),
                                style: const ToggleStyle(
                                  borderColor: Colors.transparent,
                                  indicatorColor: Colors.white,
                                  backgroundColor: Colors.black,
                                ),
                                customStyleBuilder: (context, local, global) {
                                  if (global.position <= 0) {
                                    return ToggleStyle(
                                      backgroundColor: Colors.grey[300],
                                    );
                                  }
                                  return ToggleStyle(
                                      backgroundGradient:
                                          LinearGradient(colors: [
                                    Colors.green,
                                    Colors.grey[300]!
                                  ], stops: [
                                    global.position -
                                        (1 -
                                                2 *
                                                    max(
                                                        0,
                                                        global.position -
                                                            0.5)) *
                                            0.7,
                                    global.position +
                                        max(0, 2 * (global.position - 0.5)) *
                                            0.7,
                                  ]));
                                },
                                borderWidth: 3,
                                height: 40,
                                loadingIconBuilder: (context, global) =>
                                    CupertinoActivityIndicator(
                                  color: Color.lerp(Colors.red[800],
                                      Colors.green, global.position),
                                ),
                                onChanged: (value) {
                                  setState(() => powerSwitch = value);
                                  // Send power status to Firebase
                                  sendPowerData(value);
                                },
                                iconBuilder: (value) => value
                                    ? const Icon(
                                        Icons.power_settings_new_rounded,
                                        color: Colors.black,
                                        size: 22,
                                      )
                                    : const Icon(
                                        Icons.power_settings_new_rounded,
                                        color: Colors.black,
                                        size: 22,
                                      ),
                                textBuilder: (value) => value
                                    ? const Center(
                                        child: Text('Active'),
                                      )
                                    : const Center(
                                        child: Text('Inactive'),
                                      ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

Widget displayFoodLevelCircular(String foodLevelString) {
  double foodLevel = double.tryParse(foodLevelString) ?? 0.0;

  return Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        width: 90,
        height: 90,
        child: CircularProgressIndicator(
          value: foodLevel / 100,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation(Colors.red),
          strokeWidth: 14,
        ),
      ),
      Text(
        '${foodLevel.toStringAsFixed(0)}%',
        style: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ],
  );
}
