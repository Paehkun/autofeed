import 'dart:math';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:auto_test/screen/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_test/screen/FeedTimerPage.dart';
import 'package:auto_test/screen/report.dart';
import 'package:auto_test/screen/profile.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';

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
        onTap: _navigateBottomBar,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.access_alarm_rounded), label: 'Timer'),
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

  @override
  void initState() {
    super.initState();
    fetchname();
    fetchFeedSwitchState();
    fetchPowerSwitchState();
    checkFoodLevel();
    fetchTodaySchedule();
  }

  Future<void> fetchname() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/${currentUser.uid}');
      DataSnapshot snapshot = await userRef.child('name').get();
      if (snapshot.exists) {
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
      if (snapshot.exists) {
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
      if (snapshot.exists) {
        setState(() {
          powerSwitch = snapshot.value as bool;
        });
      }
    }
  }

  void fetchTodaySchedule() async {
    final User? _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) return;

    // Adjust for Malaysia timezone (GMT+8)
    final now = DateTime.now().add(Duration(hours: 8));
    final today = DateFormat('EEEE').format(now); // Get the day of the week
    final todayDate = DateFormat('yyyy-MM-dd').format(now); // Get today's date

    debugPrint("Today: $today"); // Check the current day

    final scheduleRef =
        FirebaseDatabase.instance.ref('users/${_currentUser.uid}/schedule');

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

      setState(() {
        todaySchedule = todayTimers.isNotEmpty
            ? "$today, $todayDate: ${todayTimers.join(", ")}" // Show day and date
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

  void checkFoodLevel() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference feedRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/foodLevel');

      feedRef.onValue.listen((event) {
        if (event.snapshot.exists) {
          String foodLevelString = event.snapshot.value.toString();
          double foodLevel = double.tryParse(foodLevelString) ?? 0.0;

          print("🔥 Food Level: $foodLevel"); // Debugging

          if (foodLevel <= 20) {
            print("🚨 Sending Low Food Level Notification...");
            AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: 1,
                channelKey: 'basic_channel',
                title: 'Food Level Is Low ⚠️',
                body:
                    'Your fish food is at ${foodLevel.toInt()}%. Please refill.',
                notificationLayout: NotificationLayout.BigText,
              ),
            );
          }
        } else {
          print("⚠️ No food level data found.");
        }
      });
    } else {
      print("❌ User is not logged in.");
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
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 25),
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
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              signUserOut(
                                  context); // Call the sign out function
                              Navigator.of(context).pop(); // Close the dialog
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
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Container(
            height: 150, // Adjusted height to fit schedule and toggle only
            width: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Shadow color
                  spreadRadius: 10, // Spread of the shadow
                  blurRadius: 10, // How much the shadow is blurred
                  offset: const Offset(3, 5), // Position of the shadow (x, y)
                ),
              ],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0), // Add horizontal padding
                  child: Center(
                    child: Text(
                      todaySchedule ?? "No feeding schedule today.",
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
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
                      offset:
                          const Offset(3, 5), // Position of the shadow (x, y)
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
                      color: Colors.black.withOpacity(0.1), // Shadow color
                      spreadRadius: 7, // Spread of the shadow
                      blurRadius: 10, // How much the shadow is blurred
                      offset:
                          const Offset(3, 5), // Position of the shadow (x, y)
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
                                  backgroundGradient: LinearGradient(colors: [
                                Colors.green,
                                Colors.grey[300]!
                              ], stops: [
                                global.position -
                                    (1 - 2 * max(0, global.position - 0.5)) *
                                        0.7,
                                global.position +
                                    max(0, 2 * (global.position - 0.5)) * 0.7,
                              ]));
                            },
                            borderWidth: 3,
                            height: 40,
                            loadingIconBuilder: (context, global) =>
                                CupertinoActivityIndicator(
                              color: Color.lerp(Colors.red[800], Colors.green,
                                  global.position),
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
        ],
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
