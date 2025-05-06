import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FeedTimerPage extends StatefulWidget {
  const FeedTimerPage({super.key});

  @override
  _FeedTimerPageState createState() => _FeedTimerPageState();
}

class _FeedTimerPageState extends State<FeedTimerPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final List<Map<String, dynamic>> _feedTimes = [];
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadFeedTimesFromFirebase();
  }

  Future<void> _loadFeedTimesFromFirebase() async {
    if (_currentUser == null) return;

    final snapshot =
        await _database.child("users/${_currentUser.uid}/schedule").once();
    final data = snapshot.snapshot.value as Map?;

    _feedTimes.clear();

    if (data != null) {
      data.forEach((key, value) {
        _feedTimes.add({
          'id': key, // Store the scheduleId (like 'timer1', 'timer2', etc.)
          'days': (value['day'] as String)
              .split(", ")
              .where((d) => d.isNotEmpty)
              .toList(),
          'time': value['time'] ?? '',
          'enabled': value['enabled'] ?? false,
        });
      });
      _feedTimes.sort((a, b) {
        final timeA = DateFormat('hh:mm a').parse(a['time']);
        final timeB = DateFormat('hh:mm a').parse(b['time']);
        return timeA.compareTo(timeB);
      });
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickTime(BuildContext context, [int? index]) async {
    DateTime selectedTime = DateTime.now();

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selectedTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    selectedTime = newTime;
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String formattedTime =
                      DateFormat('hh:mm a').format(selectedTime);
                  if (index != null) {
                    setState(() {
                      _feedTimes[index]['time'] = formattedTime;
                    });
                    await _updateScheduleToFirebase(index);
                  } else {
                    setState(() {
                      _feedTimes.add({
                        'time': formattedTime,
                        'enabled': true,
                        'days': <String>[]
                      });
                    });
                    await _saveScheduleToFirebase(_feedTimes.length - 1);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9))),
                child: const Text("Set Time",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveScheduleToFirebase(int index) async {
    if (_currentUser == null || _feedTimes.isEmpty) return;

    // SAFELY find existing IDs
    Set<String> existingIds = _feedTimes
        .where((e) => e['id'] != null && (e['id'] as String).isNotEmpty)
        .map<String>((e) => e['id'].toString())
        .toSet();

    // Find next available timer number
    int timerNumber = 1;
    while (existingIds.contains('timer$timerNumber')) {
      timerNumber++;
    }

    String scheduleId = 'timer$timerNumber';

    // Save to Firebase
    await _database
        .child("users/${_currentUser.uid}/schedule/$scheduleId")
        .set({
      'day': _feedTimes[index]['days'].join(", "),
      'time': _feedTimes[index]['time'],
      'enabled': _feedTimes[index]['enabled'],
    });

    // Save the id locally
    _feedTimes[index]['id'] = scheduleId;
  }

  Future<void> _updateScheduleToFirebase(int index) async {
    if (_currentUser == null || _feedTimes.isEmpty) return;

    String? scheduleId = _feedTimes[index]['id'];

    if (scheduleId == null || scheduleId.isEmpty) return; // Extra safety

    await _database
        .child("users/${_currentUser.uid}/schedule/$scheduleId")
        .update({
      'day': _feedTimes[index]['days'].join(", "),
      'time': _feedTimes[index]['time'],
      'enabled': _feedTimes[index]['enabled'],
    });
  }

  Future<void> _deleteSchedule(int index) async {
    if (_currentUser == null || _feedTimes.isEmpty) return;

    String? scheduleId = _feedTimes[index]['id'];

    if (scheduleId == null || scheduleId.isEmpty) return; // Prevent null crash

    // Remove the schedule data from Firebase
    await _database
        .child("users/${_currentUser.uid}/schedule/$scheduleId")
        .remove();

    if (!mounted) return;

    // Remove the item from the list
    setState(() {
      _feedTimes.removeAt(index);
    });
  }

  void _toggleFeedTime(int index) {
    setState(() {
      _feedTimes[index]['enabled'] = !_feedTimes[index]['enabled'];
    });
    _updateScheduleToFirebase(index);
  }

  Future<void> _selectDays(BuildContext context, int index) async {
    List<String> selectedDays = List.from(_feedTimes[index]['days']);
    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
            daysOfWeek: _daysOfWeek, selectedDays: selectedDays);
      },
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _feedTimes[index]['days'] = result;
      });
      _updateScheduleToFirebase(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),
            const Text("Set Timer", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 25),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: _feedTimes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _feedTimes.length) {
                      return GestureDetector(
                        onTap: () => _pickTime(context),
                        child: Container(
                          height: 60,
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.1), // Shadow color
                                spreadRadius: 10, // Spread of the shadow
                                blurRadius:
                                    10, // How much the shadow is blurred
                                offset: const Offset(
                                    3, 5), // Position of the shadow (x, y)
                              ),
                            ],
                            borderRadius:
                                BorderRadius.circular(25), // Rounded corners
                          ),
                          child: const Center(
                            child:
                                Icon(Icons.add, color: Colors.black, size: 30),
                          ),
                        ),
                      );
                    }
                    return Dismissible(
                        key: Key(_feedTimes[index]['id'] ??
                            'defaultKey'), // Use a fallback value if 'id' is null
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete,
                              color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) => _deleteSchedule(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.1), // Shadow color
                                spreadRadius: 10, // Spread of the shadow
                                blurRadius:
                                    10, // How much the shadow is blurred
                                offset: const Offset(
                                    3, 5), // Position of the shadow (x, y)
                              ),
                            ],
                            borderRadius:
                                BorderRadius.circular(25), // Rounded corners
                          ),
                          child: ListTile(
                            title: GestureDetector(
                              onTap: () => _pickTime(context, index),
                              child: Text(
                                _feedTimes[index]['time'] ??
                                    'No Time Set', // Fallback for time
                                style: TextStyle(
                                  fontSize: 24,
                                  color: _feedTimes[index]['enabled']
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            subtitle: GestureDetector(
                              onTap: () => _selectDays(context, index),
                              child: Text(
                                _feedTimes[index]['days'].isEmpty
                                    ? "Select Days"
                                    : _feedTimes[index]['days'].join(", "),
                                style: TextStyle(
                                  color: _feedTimes[index]['enabled']
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            trailing: Switch(
                              value: _feedTimes[index]['enabled'],
                              onChanged: (value) => _toggleFeedTime(index),
                              activeColor: Colors.blue,
                            ),
                          ),
                        ));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MultiSelectDialog for selecting days
class MultiSelectDialog extends StatefulWidget {
  final List<String> daysOfWeek;
  final List<String> selectedDays;

  const MultiSelectDialog(
      {super.key, required this.daysOfWeek, required this.selectedDays});

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _tempSelectedDays;

  @override
  void initState() {
    super.initState();
    _tempSelectedDays = List.from(widget.selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Select Days"),
      content: Column(
          children: widget.daysOfWeek.map((day) {
        return CheckboxListTile(
          title: Text(day),
          value: _tempSelectedDays.contains(day),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _tempSelectedDays.add(day);
              } else {
                _tempSelectedDays.remove(day);
              }
            });
          },
        );
      }).toList()),
      actions: [
        TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop()),
        TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(_tempSelectedDays)),
      ],
    );
  }
}
