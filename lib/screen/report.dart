import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String selectedFilter = "Week"; // Default filter
  List<FlSpot> chartData = [];

  List<double> monthlyUsage = List.filled(12, 0); // Array for monthly usage
  List<double> weeklyUsage =
      List.filled(7, 0); // Array for weekly usage (7 days in a week)

  @override
  void initState() {
    super.initState();
    _fetchFoodUsageData(); // Load food usage data from Firebase
  }

  Future<void> _fetchFoodUsageData() async {
    if (_currentUser == null) return;

    // Access the "food_usage" node for the current user
    final snapshot =
        await _database.child('users/${_currentUser.uid}/food_usage').get();

    if (snapshot.exists && mounted) {
      Map<dynamic, dynamic> logs = snapshot.value as Map<dynamic, dynamic>;

      // Reset arrays before calculating
      setState(() {
        monthlyUsage = List.filled(12, 0);
        weeklyUsage = List.filled(7, 0);
      });

      // Iterate over the logs to calculate total food usage
      logs.forEach((key, value) {
        // Check if the required fields ('food_dispensed' and 'time') are available
        if (value != null &&
            value['food_dispensed'] != null &&
            value['time'] != null) {
          double foodUsed = (value['food_dispensed'] is int)
              ? (value['food_dispensed'] as int).toDouble()
              : value['food_dispensed']; // Cast to double if it's an int

          // Only add food usage if food_dispensed is greater than zero
          if (foodUsed > 0) {
            String timeStr = value['time']; // Time of feeding event

            // For now, we'll assume the feeding time can be mapped to today's date
            DateTime feedDate = DateTime
                .now(); // Modify this to use actual feeding date if possible
            int month = feedDate.month -
                1; // Adjust for Firebase 1-based month indexing
            int weekday =
                feedDate.weekday - 1; // Adjust for weekday index (Mon=0, Sun=6)

            setState(() {
              monthlyUsage[month] += foodUsed;
              weeklyUsage[weekday] += foodUsed;
            });
          }
        }
      });

      updateChartData();
    }
  }

  void updateChartData() {
    setState(() {
      if (selectedFilter == "Week") {
        // Weekly usage (displaying days of the week) in grams
        chartData = List.generate(
          7,
          (index) => FlSpot(index.toDouble(), weeklyUsage[index]),
        );
      } else if (selectedFilter == "Month") {
        // Monthly usage, divided into 4 weeks (in kilograms)
        chartData = List.generate(
          4,
          (index) {
            double weeklyAverage = monthlyUsage[index] / 4;
            return FlSpot(
                index.toDouble(), weeklyAverage / 1000); // Convert to kg
          },
        );
      } else if (selectedFilter == "Year") {
        // Yearly cumulative food usage (per month) in kilograms
        double total = 0;
        chartData = List.generate(12, (index) {
          total += monthlyUsage[index];
          return FlSpot(index.toDouble(), total / 1000); // Convert to kg
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // Wrap the content inside the scroll view
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Report",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select View:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: selectedFilter,
                        items: ["Week", "Month", "Year"]
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedFilter = newValue;
                              updateChartData();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // White Container for the Chart with increased size
                Container(
                  height: 400, // Set a fixed height for the chart
                  width: MediaQuery.of(context).size.width * 0.9, // Wider
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (selectedFilter == "Week") {
                                  return Text(
                                    '${value.toInt()} grams',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                } else {
                                  return Text(
                                    '${value.toInt()} kg', // Show in kg for Month/Year
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                              },
                              reservedSize: 30,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (selectedFilter == "Week") {
                                  // Weekdays (Mon, Tue, Wed, ...)
                                  List<String> weekdays = [
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                    "Sun"
                                  ];
                                  return Text(
                                    weekdays[value.toInt()],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                } else if (selectedFilter == "Month") {
                                  // Weeks of the month (Week 1, Week 2, Week 3, Week 4)
                                  return Text(
                                    "Week ${value.toInt() + 1}",
                                    style: const TextStyle(fontSize: 10),
                                  );
                                } else if (selectedFilter == "Year") {
                                  // Month names (Jan, Feb, Mar, ...)
                                  List<String> months = [
                                    "Jan",
                                    "Feb",
                                    "Mar",
                                    "Apr",
                                    "May",
                                    "Jun",
                                    "Jul",
                                    "Aug",
                                    "Sep",
                                    "Oct",
                                    "Nov",
                                    "Dec"
                                  ];
                                  int monthIndex = value.toInt();
                                  return Text(
                                    months[monthIndex],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                } else {
                                  return Text(
                                    "M${value.toInt()}",
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: false,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Total food usage in $selectedFilter view',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Container(
                  height:
                      200, // Adjusted height to fit schedule and toggle only
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.0), // Add horizontal padding
                        child: Center(
                          child: Text(
                            "Feeding Log",
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
