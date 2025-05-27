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
  String selectedFilter = "week"; // Default filter
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

    final snapshot =
        await _database.child('users/${_currentUser.uid}/food_usage').get();

    if (snapshot.exists && mounted) {
      Map<dynamic, dynamic> logs = snapshot.value as Map<dynamic, dynamic>;

      List<double> tempMonthlyUsage = List.filled(12, 0);
      List<double> tempWeeklyUsage = List.filled(7, 0);

      DateTime now = DateTime.now();
      DateTime startOfWeek =
          now.subtract(Duration(days: now.weekday - 1)); // Monday
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

      logs.forEach((key, value) {
        if (value != null &&
            value['food_dispensed'] != null &&
            value['time'] != null) {
          double foodUsed = (value['food_dispensed'] is int)
              ? (value['food_dispensed'] as int).toDouble()
              : value['food_dispensed'];

          if (foodUsed > 0) {
            DateTime feedDate = DateTime.parse(value['time']);
            int month = feedDate.month - 1;
            int weekday = feedDate.weekday - 1;

            // Monthly usage (no change)
            tempMonthlyUsage[month] += foodUsed;

            // Weekly usage (only if within current week)
            if (feedDate.isAfter(
                    startOfWeek.subtract(const Duration(seconds: 1))) &&
                feedDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
              tempWeeklyUsage[weekday] += foodUsed;
            }
          }
        }
      });

      setState(() {
        monthlyUsage = tempMonthlyUsage;
        weeklyUsage = tempWeeklyUsage;
      });

      await updateChartData();
    }
  }

  Future<void> updateChartData() async {
    if (selectedFilter == "week") {
      setState(() {
        chartData = List.generate(
          7,
          (index) => FlSpot(index.toDouble(), weeklyUsage[index]),
        );
      });
    } else if (selectedFilter == "month") {
      DateTime now = DateTime.now();
      int currentMonth = now.month;
      int currentYear = now.year;

      List<double> currentMonthWeeklyUsage = List.filled(5, 0);

      final snapshot =
          await _database.child('users/${_currentUser!.uid}/food_usage').get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> logs = snapshot.value as Map<dynamic, dynamic>;

        logs.forEach((key, value) {
          if (value != null &&
              value['food_dispensed'] != null &&
              value['time'] != null) {
            double foodUsed = (value['food_dispensed'] is int)
                ? (value['food_dispensed'] as int).toDouble()
                : value['food_dispensed'];
            DateTime feedDate = DateTime.parse(value['time']);

            if (feedDate.month == currentMonth &&
                feedDate.year == currentYear) {
              int weekOfMonth = ((feedDate.day - 1) ~/ 7);
              currentMonthWeeklyUsage[weekOfMonth] += foodUsed;
            }
          }
        });

        setState(() {
          chartData = List.generate(
            5,
            (index) => FlSpot(index.toDouble(), currentMonthWeeklyUsage[index]),
          );
        });
      }
    } else if (selectedFilter == "year") {
      setState(() {
        chartData = List.generate(12, (index) {
          return FlSpot(index.toDouble(), monthlyUsage[index] / 1000);
        });
      });
    }
  }

  // Calculate the total usage based on selected filter
  double getTotalFoodUsage() {
    if (selectedFilter == "week") {
      return weeklyUsage.reduce((a, b) => a + b);
    } else if (selectedFilter == "month") {
      // Multiply by 1000 because chartData stores in kg
      return chartData.map((spot) => spot.y).reduce((a, b) => a + b);
    } else if (selectedFilter == "year") {
      return monthlyUsage.reduce((a, b) => a + b);
    }
    return 0;
  }

// Format the total usage as text
  String getFormattedTotalUsage() {
    double total = getTotalFoodUsage();
    if (selectedFilter == "year") {
      return "${(total / 1000).toStringAsFixed(2)} kg";
    } else {
      return "${total.toInt()} grams";
    }
  }

  List<String> _getMonthWeekDateRanges() {
    DateTime now = DateTime.now();
    int year = now.year;
    int month = now.month;

    List<String> ranges = [];
    int daysInMonth = DateTime(year, month + 1, 0).day;

    for (int i = 0; i < 5; i++) {
      int startDay = i * 7 + 1;
      int endDay = ((i + 1) * 7).clamp(1, daysInMonth);
      if (startDay > daysInMonth) break;

      // Format: "1-7", "8-14", etc.
      ranges.add("$startDay-$endDay");
    }
    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          // Wrap the content inside the scroll view
          child: Container(
            color: const Color(0xFFF5F7FA),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Report',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      letterSpacing: 1.2,
                    ),
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
                        items: ["week", "month", "year"]
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
                                if (selectedFilter == "week" ||
                                    selectedFilter == "month") {
                                  return Text(
                                    '${value.toInt()} grams',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                } else {
                                  return Text(
                                    '${value.toStringAsFixed(1)} Kg',
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
                                if (value % 1 != 0) {
                                  return const SizedBox.shrink();
                                }
                                int index = value.toInt();

                                Widget buildLabel(String text) {
                                  if (index == 0) {
                                    // Add extra left padding to the first label
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0), // adjust 8.0 as needed
                                      child: Text(
                                        text,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      text,
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                }

                                if (selectedFilter == "week") {
                                  List<String> weekdays = [
                                    "Mon",
                                    "Tue",
                                    "Wed",
                                    "Thu",
                                    "Fri",
                                    "Sat",
                                    "Sun"
                                  ];
                                  if (index < weekdays.length) {
                                    return buildLabel(weekdays[index]);
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                } else if (selectedFilter == "month") {
                                  List<String> weekDateRanges =
                                      _getMonthWeekDateRanges();
                                  if (index < weekDateRanges.length) {
                                    return buildLabel(weekDateRanges[index]);
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                } else if (selectedFilter == "year") {
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
                                  if (index < months.length) {
                                    return buildLabel(months[index]);
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                } else {
                                  return buildLabel("M$index");
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
                        // Set the Y-axis range dynamically
                        gridData: const FlGridData(show: true),
                        minY: selectedFilter == "week"
                            ? 0
                            : 0, // Keep minY at 0 for both week and month/year
                        maxY: selectedFilter == "week"
                            ? (weeklyUsage.isNotEmpty
                                ? weeklyUsage.reduce((a, b) => a > b ? a : b) +
                                    10
                                : 10)
                            : (chartData.isNotEmpty
                                ? chartData
                                        .map((e) => e.y)
                                        .reduce((a, b) => a > b ? a : b) +
                                    0.2
                                : 1),

                        minX: 0, // Start of X-axis
                        maxX: selectedFilter == "week"
                            ? 6.0
                            : (selectedFilter == "month"
                                ? 4.0
                                : 11.0), // 6 for weeks, 4 for months, 11 for years (12 months - 1)
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 20),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                    color: Colors.white,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            'Total Food Usage ${selectedFilter.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getFormattedTotalUsage(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
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
