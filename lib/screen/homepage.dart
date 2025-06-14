import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:auto_test/screen/auth_page.dart';
import 'package:auto_test/screen/monitor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    fetchname();
    fetchFeedSwitchState();
    fetchPowerSwitchState();
    fetchTodaySchedule();
    subscribeToTopic(currentUser.uid);
    _loadUserSelection();
  }

  Future<void> _loadUserSelection() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _database.child("users/$userId/selection").get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      setState(() {
        if (data['fish_age'] != null &&
            fishAgeAmountOptions.containsKey(data['fish_age'])) {
          selectedFishAge = data['fish_age'];
        }
        if (selectedFishAge != null &&
            data['fish_amount'] != null &&
            fishAgeAmountOptions[selectedFishAge]!
                .contains(data['fish_amount'])) {
          selectedFishAmount = data['fish_amount'];
        }
      });
    }
  }

  Future<void> sendScheduleBasedOnSelection() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null ||
        selectedFishAge == null ||
        selectedFishAmount == null) {
      return;
    }

    final database = FirebaseDatabase.instance.ref();

    int feedTimesPerDay = 0;

    // Determine feeding frequency
    if (selectedFishAmount == '0–5') {
      feedTimesPerDay = 3;
    } else if (selectedFishAmount == '6–10') {
      feedTimesPerDay = 4;
    } else if (selectedFishAmount == '11–15') {
      feedTimesPerDay = 5;
    } else if (selectedFishAmount == '15 and above') {
      feedTimesPerDay = 5;
    } else {
      return; // Invalid
    }

    // Define feeding times
    List<String> feedTimes;
    if (feedTimesPerDay == 3) {
      feedTimes = ['08:00 AM', '01:00 PM', '06:00 PM'];
    } else if (feedTimesPerDay == 4) {
      feedTimes = ['08:00 AM', '10:00 AM', '01:00 PM', '04:00 PM'];
    } else {
      feedTimes = ['08:00 AM', '10:00 AM', '12:00 PM', '03:00 PM', '05:00 PM'];
    }

    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    // Save selection
    await database.child("users/$userId/selection").set({
      'fish_age': selectedFishAge,
      'fish_amount': selectedFishAmount,
    });

    // Save schedule
    for (int i = 0; i < feedTimes.length; i++) {
      String timerId = 'timer${i + 1}';

      await database.child("schedule/$userId/$timerId").set({
        'day': days.join(", "),
        'time': feedTimes[i],
        'enabled': true,
      });
    }

    // Delete unused timers (optional cleanup)
    for (int i = feedTimes.length + 1; i <= 5; i++) {
      String timerId = 'timer$i';
      await database.child("schedule/$userId/$timerId").remove();
    }
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
          FirebaseDatabase.instance.ref('device/${user.uid}/status');
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
          FirebaseDatabase.instance.ref('device/${user.uid}/power');
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
        FirebaseDatabase.instance.ref('schedule/${currentUser.uid}');

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
            ? "$today, $todayDate :\n${todayTimers.asMap().entries.map((entry) => "Slot ${entry.key + 1}: ${entry.value}").join("\n")}"
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
          FirebaseDatabase.instance.ref('device/${user.uid}/status');
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
          FirebaseDatabase.instance.ref('device/${user.uid}/power');
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
          FirebaseDatabase.instance.ref('device/${user.uid}/foodLevel');

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
      backgroundColor: const Color(0xFFF5F7FA), // Soft light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top bar with logout
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Logout icon on the left
                  Tooltip(
                    message: 'Logout',
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.black),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                  'Are you sure you want to log out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
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
                    ),
                  ),

                  const Spacer(), // Push logo to the far right

                  // Logo on the right
                  Image.asset(
                    'assets/images/logo1.png', // Update with your logo path
                    height: 50, // Adjust as needed
                  ),
                ],
              ),
              Text(
                'AutoFeed',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name ?? 'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 30),

              // Dropdown Card Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Fish Age',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Fish Age Dropdown
                    DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Text(
                          'Add Fish Age',
                          style:
                              TextStyle(fontSize: 16, color: Colors.blueGrey),
                        ),
                        items: fishAgeAmountOptions.keys.map((item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item,
                                style: const TextStyle(fontSize: 16)),
                          );
                        }).toList(),
                        value: selectedFishAge,
                        onChanged: (value) {
                          setState(() {
                            selectedFishAge = value;
                            selectedFishAmount = null;
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 55,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.blue.shade200),
                            color: Colors.blue.shade50,
                          ),
                          elevation: 0,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 45,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Select Fish Amount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Fish Amount Dropdown
                    if (selectedFishAge != null && selectedFishAge != 'Custom')
                      DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          hint: const Text(
                            'Add Fish Amount',
                            style:
                                TextStyle(fontSize: 16, color: Colors.blueGrey),
                          ),
                          items: fishAgeAmountOptions[selectedFishAge]!
                              .map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item,
                                  style: const TextStyle(fontSize: 16)),
                            );
                          }).toList(),
                          value: selectedFishAmount,
                          onChanged: (value) {
                            setState(() {
                              selectedFishAmount = value;
                            });
                          },
                          buttonStyleData: ButtonStyleData(
                            height: 55,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.blue.shade200),
                              color: Colors.blue.shade50,
                            ),
                            elevation: 0,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                          menuItemStyleData: const MenuItemStyleData(
                            height: 45,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          if (selectedFishAge != null &&
                              selectedFishAmount != null) {
                            sendScheduleBasedOnSelection();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please select both fish age and amount')),
                            );
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Schedule display card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Feeding Schedule",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (todaySchedule != null &&
                        todaySchedule!.contains("Slot")) ...[
                      Text(
                        todaySchedule!.split(":")[0], // Show date line only
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...todaySchedule!
                          .split("\n")
                          .skip(1)
                          .map((line) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  line,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              )),
                    ] else
                      Text(
                        todaySchedule ?? "No feeding schedule today.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, color: Colors.black87),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Food Level and Device Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Food Level Card
                  Expanded(
                    child: Container(
                      height: 240,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Food Level",
                            style: TextStyle(
                              fontSize: 18, // smaller font
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 25),
                          displayFoodLevelCircular(realTimeValue),
                        ],
                      ),
                    ),
                  ),

                  // Device Control Card
                  Expanded(
                    child: Container(
                      height: 240,
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Device Status",
                            style: TextStyle(
                              fontSize: 18, // smaller font
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Image.asset(
                            'assets/images/feeder.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          AnimatedToggleSwitch.dual(
                            current: powerSwitch,
                            first: false,
                            second: true,
                            height: 42,
                            borderWidth: 3,
                            spacing: 22,
                            animationDuration:
                                const Duration(milliseconds: 600),
                            style: ToggleStyle(
                              borderColor: powerSwitch
                                  ? Colors.blue.shade700
                                  : Colors.red.shade700,
                              indicatorColor: powerSwitch
                                  ? Colors.blueAccent
                                  : Colors.redAccent,
                              backgroundColor: powerSwitch
                                  ? Colors.blue.shade100
                                  : Colors.red.shade100,
                            ),
                            onChanged: (value) {
                              setState(() => powerSwitch = value);
                              sendPowerData(value);
                            },
                            iconBuilder: (value) => Icon(
                              Icons.power_settings_new_rounded,
                              color: powerSwitch
                                  ? Colors.blue.shade700
                                  : Colors.red.shade700,
                              size: 20, // smaller icon
                            ),
                            textBuilder: (value) => Center(
                              child: Text(
                                value ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: powerSwitch
                                      ? Colors.blue.shade900
                                      : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // smaller text
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
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
        width: 120,
        height: 120,
        child: CircularProgressIndicator(
          value: foodLevel / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            foodLevel >= 60
                ? Colors.green
                : (foodLevel >= 21 ? Colors.orange : Colors.red),
          ),
          strokeWidth: 20,
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
